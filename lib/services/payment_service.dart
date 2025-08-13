import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/payment_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Razorpay _razorpay;

  // Replace with your actual Razorpay keys
  static const String _razorpayKeyId = 'rzp_test_YOUR_KEY_ID';
  static const String _razorpayKeySecret = 'YOUR_KEY_SECRET';
  static const String _baseUrl = 'https://api.razorpay.com/v1';

  PaymentService() {
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Handle successful payment
    print('Payment Success: ${response.paymentId}');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Handle payment failure
    print('Payment Error: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet
    print('External Wallet: ${response.walletName}');
  }

  void dispose() {
    _razorpay.clear();
  }

  // Create a new wallet for user
  Future<WalletModel?> createWallet(String userId) async {
    try {
      final walletData = {
        'userId': userId,
        'balance': 0.0,
        'transactionIds': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('wallets').add(walletData);
      return WalletModel.fromMap(walletData, docRef.id);
    } catch (e) {
      print('Error creating wallet: $e');
      return null;
    }
  }

  // Get user's wallet
  Future<WalletModel?> getWallet(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('wallets')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        return WalletModel.fromMap(data, querySnapshot.docs.first.id);
      }

      // If wallet doesn't exist, create one
      return await createWallet(userId);
    } catch (e) {
      print('Error getting wallet: $e');
      // Try to create wallet if permission denied
      try {
        return await createWallet(userId);
      } catch (e2) {
        print('Error creating wallet: $e2');
        return null;
      }
    }
  }

  // Stream wallet updates
  Stream<WalletModel?> getWalletStream(String userId) {
    return _firestore
        .collection('wallets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final doc = snapshot.docs.first;
          return WalletModel.fromMap(doc.data(), doc.id);
        });
  }

  // Recharge wallet
  Future<PaymentModel?> rechargeWallet({
    required String userId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? upiId,
    String? cardLast4,
    String? cardBrand,
  }) async {
    try {
      // Create payment record
      final paymentDoc = await _firestore.collection('payments').add({
        'userId': userId,
        'rideId': null,
        'amount': amount,
        'paymentMethod': paymentMethod.toString().split('.').last,
        'status': 'pending',
        'transactionType': 'walletRecharge',
        'description': 'Wallet Recharge',
        'createdAt': Timestamp.now(),
        'upiId': upiId,
        'cardLast4': cardLast4,
        'cardBrand': cardBrand,
      });

      final paymentId = paymentDoc.id;

      // Process payment based on method
      bool paymentSuccess = false;
      String? razorpayOrderId;
      String? razorpayPaymentId;

      switch (paymentMethod) {
        case PaymentMethod.wallet:
          // For wallet, we'll handle it differently
          paymentSuccess = true;
          break;
        case PaymentMethod.upi:
        case PaymentMethod.card:
          // Create Razorpay order
          final order = await _createRazorpayOrder(amount, 'Wallet Recharge');
          razorpayOrderId = order['id'];

          // Initialize payment
          final options = {
            'key': _razorpayKeyId,
            'amount': (amount * 100).round(), // Convert to paise
            'currency': 'INR',
            'name': 'GoCab',
            'description': 'Wallet Recharge',
            'order_id': razorpayOrderId,
            'prefill': {
              'contact': '', // Add user phone if available
              'email': '', // Add user email if available
            },
            'external': {
              'wallets': ['paytm', 'phonepe', 'gpay'],
            },
          };

          _razorpay.open(options);

          // For demo purposes, we'll simulate success
          // In real implementation, handle the callback
          paymentSuccess = true;
          razorpayPaymentId = 'demo_payment_${Random().nextInt(1000000)}';
          break;
      }

      if (paymentSuccess) {
        // Update payment status
        await _firestore.collection('payments').doc(paymentId).update({
          'status': 'completed',
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'completedAt': Timestamp.now(),
        });

        // Update wallet balance
        await _updateWalletBalance(userId, amount, paymentId);

        return PaymentModel.fromMap({
          'userId': userId,
          'rideId': null,
          'amount': amount,
          'paymentMethod': paymentMethod.toString().split('.').last,
          'status': 'completed',
          'transactionType': 'walletRecharge',
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'upiId': upiId,
          'cardLast4': cardLast4,
          'cardBrand': cardBrand,
          'description': 'Wallet Recharge',
          'createdAt': Timestamp.now(),
          'completedAt': Timestamp.now(),
        }, paymentId);
      }

      return null;
    } catch (e) {
      print('Error recharging wallet: $e');
      return null;
    }
  }

  // Process ride payment
  Future<PaymentModel?> processRidePayment({
    required String userId,
    required String rideId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? upiId,
    String? cardLast4,
    String? cardBrand,
  }) async {
    try {
      // Check if user has sufficient wallet balance
      if (paymentMethod == PaymentMethod.wallet) {
        final wallet = await getWallet(userId);
        if (wallet == null || wallet.balance < amount) {
          throw Exception('Insufficient wallet balance');
        }
      }

      // Create payment record
      final paymentDoc = await _firestore.collection('payments').add({
        'userId': userId,
        'rideId': rideId,
        'amount': amount,
        'paymentMethod': paymentMethod.toString().split('.').last,
        'status': 'pending',
        'transactionType': 'ridePayment',
        'description': 'Ride Payment',
        'createdAt': Timestamp.now(),
        'upiId': upiId,
        'cardLast4': cardLast4,
        'cardBrand': cardBrand,
      });

      final paymentId = paymentDoc.id;

      // Process payment based on method
      bool paymentSuccess = false;
      String? razorpayOrderId;
      String? razorpayPaymentId;

      switch (paymentMethod) {
        case PaymentMethod.wallet:
          // Deduct from wallet
          await _updateWalletBalance(userId, -amount, paymentId);
          paymentSuccess = true;
          break;
        case PaymentMethod.upi:
        case PaymentMethod.card:
          // Create Razorpay order
          final order = await _createRazorpayOrder(amount, 'Ride Payment');
          razorpayOrderId = order['id'];

          // Initialize payment
          final options = {
            'key': _razorpayKeyId,
            'amount': (amount * 100).round(),
            'currency': 'INR',
            'name': 'GoCab',
            'description': 'Ride Payment',
            'order_id': razorpayOrderId,
            'prefill': {'contact': '', 'email': ''},
            'external': {
              'wallets': ['paytm', 'phonepe', 'gpay'],
            },
          };

          _razorpay.open(options);

          // For demo purposes, simulate success
          paymentSuccess = true;
          razorpayPaymentId = 'demo_payment_${Random().nextInt(1000000)}';
          break;
      }

      if (paymentSuccess) {
        // Update payment status
        await _firestore.collection('payments').doc(paymentId).update({
          'status': 'completed',
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'completedAt': Timestamp.now(),
        });

        return PaymentModel.fromMap({
          'userId': userId,
          'rideId': rideId,
          'amount': amount,
          'paymentMethod': paymentMethod.toString().split('.').last,
          'status': 'completed',
          'transactionType': 'ridePayment',
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'upiId': upiId,
          'cardLast4': cardLast4,
          'cardBrand': cardBrand,
          'description': 'Ride Payment',
          'createdAt': Timestamp.now(),
          'completedAt': Timestamp.now(),
        }, paymentId);
      }

      return null;
    } catch (e) {
      print('Error processing ride payment: $e');
      return null;
    }
  }

  // Create Razorpay order
  Future<Map<String, dynamic>> _createRazorpayOrder(
    double amount,
    String description,
  ) async {
    final url = Uri.parse('$_baseUrl/orders');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$_razorpayKeyId:$_razorpayKeySecret'))}',
      },
      body: jsonEncode({
        'amount': (amount * 100).round(),
        'currency': 'INR',
        'receipt': 'receipt_${DateTime.now().millisecondsSinceEpoch}',
        'notes': {'description': description},
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create Razorpay order: ${response.body}');
    }
  }

  // Update wallet balance
  Future<void> _updateWalletBalance(
    String userId,
    double amount,
    String transactionId,
  ) async {
    // First, try to find existing wallet
    final existingWallets = await _firestore
        .collection('wallets')
        .where('userId', isEqualTo: userId)
        .get();

    if (existingWallets.docs.isEmpty) {
      // Create new wallet
      await _firestore.collection('wallets').add({
        'userId': userId,
        'balance': amount,
        'transactionIds': [transactionId],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } else {
      // Update existing wallet
      final walletDoc = existingWallets.docs.first;
      final currentBalance = walletDoc.data()['balance'] ?? 0.0;
      final transactionIds = List<String>.from(
        walletDoc.data()['transactionIds'] ?? [],
      );

      transactionIds.add(transactionId);

      await walletDoc.reference.update({
        'balance': currentBalance + amount,
        'transactionIds': transactionIds,
        'updatedAt': Timestamp.now(),
      });
    }
  }

  // Get payment history
  Stream<List<PaymentModel>> getPaymentHistory(String userId) {
    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Save payment method
  Future<void> savePaymentMethod({
    required String userId,
    required PaymentMethod paymentMethod,
    String? upiId,
    String? cardLast4,
    String? cardBrand,
    String? cardExpiry,
    String? cardHolderName,
    bool isDefault = false,
  }) async {
    if (isDefault) {
      // Remove default from other payment methods
      await _firestore
          .collection('saved_payment_methods')
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .get()
          .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.update({'isDefault': false});
            }
          });
    }

    await _firestore.collection('saved_payment_methods').add({
      'userId': userId,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'upiId': upiId,
      'cardLast4': cardLast4,
      'cardBrand': cardBrand,
      'cardExpiry': cardExpiry,
      'cardHolderName': cardHolderName,
      'isDefault': isDefault,
      'createdAt': Timestamp.now(),
    });
  }

  // Get saved payment methods
  Stream<List<SavedPaymentMethod>> getSavedPaymentMethods(String userId) {
    return _firestore
        .collection('saved_payment_methods')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SavedPaymentMethod.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Delete saved payment method
  Future<void> deleteSavedPaymentMethod(String paymentMethodId) async {
    await _firestore
        .collection('saved_payment_methods')
        .doc(paymentMethodId)
        .delete();
  }

  // Get default payment method
  Future<SavedPaymentMethod?> getDefaultPaymentMethod(String userId) async {
    final doc = await _firestore
        .collection('saved_payment_methods')
        .where('userId', isEqualTo: userId)
        .where('isDefault', isEqualTo: true)
        .get();

    if (doc.docs.isNotEmpty) {
      return SavedPaymentMethod.fromMap(
        doc.docs.first.data(),
        doc.docs.first.id,
      );
    }
    return null;
  }

  // Process refund
  Future<PaymentModel?> processRefund({
    required String originalPaymentId,
    required double amount,
    String reason = 'Refund',
  }) async {
    try {
      // Get original payment
      final originalPaymentDoc = await _firestore
          .collection('payments')
          .doc(originalPaymentId)
          .get();

      if (!originalPaymentDoc.exists) {
        throw Exception('Original payment not found');
      }

      final originalPayment = PaymentModel.fromMap(
        originalPaymentDoc.data()!,
        originalPaymentDoc.id,
      );

      // Create refund payment record
      final refundDoc = await _firestore.collection('payments').add({
        'userId': originalPayment.userId,
        'rideId': originalPayment.rideId,
        'amount': -amount, // Negative amount for refund
        'paymentMethod': originalPayment.paymentMethod
            .toString()
            .split('.')
            .last,
        'status': 'completed',
        'transactionType': 'refund',
        'description': reason,
        'createdAt': Timestamp.now(),
        'completedAt': Timestamp.now(),
      });

      // Update wallet if original payment was from wallet
      if (originalPayment.paymentMethod == PaymentMethod.wallet) {
        await _updateWalletBalance(
          originalPayment.userId,
          amount,
          refundDoc.id,
        );
      }

      return PaymentModel.fromMap({
        'userId': originalPayment.userId,
        'rideId': originalPayment.rideId,
        'amount': -amount,
        'paymentMethod': originalPayment.paymentMethod
            .toString()
            .split('.')
            .last,
        'status': 'completed',
        'transactionType': 'refund',
        'description': reason,
        'createdAt': Timestamp.now(),
        'completedAt': Timestamp.now(),
      }, refundDoc.id);
    } catch (e) {
      print('Error processing refund: $e');
      return null;
    }
  }
}
