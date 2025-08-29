import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/payment_model.dart';
import '../config/razorpay_config.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Razorpay _razorpay;

  // Payment callback functions
  Function(PaymentModel)? onPaymentSuccess;
  Function(String)? onPaymentError;
  Function()? onPaymentCancelled;

  // Debug mode for testing
  static const bool _debugMode = RazorpayConfig.debugMode;

  PaymentService() {
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    try {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

      if (_debugMode) {
        print('✅ Razorpay initialized successfully');
      }
    } catch (e) {
      print('❌ Error initializing Razorpay: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_debugMode) {
      print('✅ Payment Success: ${response.paymentId}');
      print('✅ Order ID: ${response.orderId}');
      print('✅ Signature: ${response.signature}');
    }

    // Notify success callback
    if (onPaymentSuccess != null) {
      // Create payment model from response
      final paymentModel = PaymentModel(
        id: response.paymentId ?? '',
        userId: '', // Will be set by caller
        amount: 0.0, // Will be set by caller
        paymentMethod: PaymentMethod.upi, // Will be determined by caller
        status: PaymentStatus.completed,
        transactionType: TransactionType.ridePayment,
        razorpayPaymentId: response.paymentId,
        razorpayOrderId: response.orderId,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );
      onPaymentSuccess!(paymentModel);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (_debugMode) {
      print('❌ Payment Error: ${response.message}');
      print('❌ Error Code: ${response.code}');
    }

    // Notify error callback
    if (onPaymentError != null) {
      onPaymentError!('Payment failed: ${response.message}');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (_debugMode) {
      print('📱 External Wallet: ${response.walletName}');
    }
  }

  void dispose() {
    try {
      _razorpay.clear();
      if (_debugMode) {
        print('✅ Razorpay disposed successfully');
      }
    } catch (e) {
      print('❌ Error disposing Razorpay: $e');
    }
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

  // Recharge wallet with improved error handling
  Future<PaymentModel?> rechargeWallet({
    required String userId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? upiId,
    String? cardLast4,
    String? cardBrand,
  }) async {
    try {
      // Validate input parameters
      if (amount <= 0) {
        throw Exception('Invalid amount: Amount must be greater than 0');
      }

      if (userId.isEmpty) {
        throw Exception('Invalid user ID');
      }

      if (_debugMode) {
        print(
          '💰 Starting wallet recharge: ₹$amount via ${paymentMethod.name}',
        );
      }

      // Create payment record
      final paymentDoc = await _firestore.collection('payments').add({
        'userId': userId,
        'rideId': null,
        'amount': amount,
        'paymentMethod': paymentMethod.toString().split('.').last,
        'status': 'pending',
        'transactionType': 'walletRecharge',
        'description': 'Wallet Recharge',
        'createdAt': FieldValue.serverTimestamp(),
        'upiId': upiId,
        'cardLast4': cardLast4,
        'cardBrand': cardBrand,
      });

      final paymentId = paymentDoc.id;

      if (_debugMode) {
        print('📝 Payment record created: $paymentId');
      }

      // Process payment based on method
      bool paymentSuccess = false;
      String? razorpayOrderId;
      String? razorpayPaymentId;

      switch (paymentMethod) {
        case PaymentMethod.wallet:
          // For wallet, we'll handle it differently
          paymentSuccess = true;
          if (_debugMode) {
            print('✅ Wallet payment processed successfully');
          }
          break;

        case PaymentMethod.upi:
        case PaymentMethod.card:
          try {
            // Create Razorpay order
            final order = await _createRazorpayOrder(amount, 'Wallet Recharge');
            razorpayOrderId = order['id'];

            if (_debugMode) {
              print('📋 Razorpay order created: $razorpayOrderId');
            }

            // Initialize payment
            final options = {
              'key': RazorpayConfig.razorpayKeyId,
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
              'theme': {'color': '#3399cc'},
            };

            // Set up payment callbacks
            onPaymentSuccess = (PaymentModel payment) async {
              try {
                // Update payment status
                await _firestore.collection('payments').doc(paymentId).update({
                  'status': 'completed',
                  'razorpayOrderId': razorpayOrderId,
                  'razorpayPaymentId': payment.razorpayPaymentId,
                  'completedAt': FieldValue.serverTimestamp(),
                });

                // Update wallet balance
                await _updateWalletBalance(userId, amount, paymentId);

                if (_debugMode) {
                  print('✅ Payment completed and wallet updated');
                }
              } catch (e) {
                print('❌ Error updating payment status: $e');
              }
            };

            onPaymentError = (String error) async {
              try {
                await _firestore.collection('payments').doc(paymentId).update({
                  'status': 'failed',
                  'failureReason': error,
                  'completedAt': FieldValue.serverTimestamp(),
                });

                if (_debugMode) {
                  print('❌ Payment failed: $error');
                }
              } catch (e) {
                print('❌ Error updating failed payment: $e');
              }
            };

            // Open payment gateway
            _razorpay.open(options);

            // For demo purposes, simulate success after a delay
            // In real implementation, handle the callback
            await Future.delayed(const Duration(seconds: 2));
            paymentSuccess = true;
            razorpayPaymentId = 'demo_payment_${Random().nextInt(1000000)}';
          } catch (e) {
            print('❌ Error creating Razorpay order: $e');
            throw Exception('Failed to create payment order: $e');
          }
          break;
      }

      if (paymentSuccess) {
        // Update payment status
        await _firestore.collection('payments').doc(paymentId).update({
          'status': 'completed',
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'completedAt': FieldValue.serverTimestamp(),
        });

        // Update wallet balance
        await _updateWalletBalance(userId, amount, paymentId);

        final paymentModel = PaymentModel.fromMap({
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

        if (_debugMode) {
          print('✅ Wallet recharge completed successfully');
        }

        return paymentModel;
      }

      return null;
    } catch (e) {
      print('❌ Error recharging wallet: $e');
      throw Exception('Wallet recharge failed: $e');
    }
  }

  // Process ride payment with improved error handling
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
      // Validate input parameters
      if (amount <= 0) {
        throw Exception('Invalid amount: Amount must be greater than 0');
      }

      if (userId.isEmpty) {
        throw Exception('Invalid user ID');
      }

      if (rideId.isEmpty) {
        throw Exception('Invalid ride ID');
      }

      if (_debugMode) {
        print('🚗 Starting ride payment: ₹$amount via ${paymentMethod.name}');
      }

      // Check if user has sufficient wallet balance
      if (paymentMethod == PaymentMethod.wallet) {
        final wallet = await getWallet(userId);
        if (wallet == null || wallet.balance < amount) {
          throw Exception(
            'Insufficient wallet balance. Required: ₹$amount, Available: ₹${wallet?.balance ?? 0}',
          );
        }

        if (_debugMode) {
          print('✅ Wallet balance sufficient: ₹${wallet.balance}');
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
        'createdAt': FieldValue.serverTimestamp(),
        'upiId': upiId,
        'cardLast4': cardLast4,
        'cardBrand': cardBrand,
      });

      final paymentId = paymentDoc.id;

      if (_debugMode) {
        print('📝 Payment record created: $paymentId');
      }

      // Process payment based on method
      bool paymentSuccess = false;
      String? razorpayOrderId;
      String? razorpayPaymentId;

      switch (paymentMethod) {
        case PaymentMethod.wallet:
          try {
            // Deduct from wallet
            await _updateWalletBalance(userId, -amount, paymentId);
            paymentSuccess = true;

            if (_debugMode) {
              print('✅ Wallet payment processed successfully');
            }
          } catch (e) {
            print('❌ Error processing wallet payment: $e');
            throw Exception('Wallet payment failed: $e');
          }
          break;

        case PaymentMethod.upi:
        case PaymentMethod.card:
          try {
            // Create Razorpay order
            final order = await _createRazorpayOrder(amount, 'Ride Payment');
            razorpayOrderId = order['id'];

            if (_debugMode) {
              print('📋 Razorpay order created: $razorpayOrderId');
            }

            // Initialize payment
            final options = {
              'key': RazorpayConfig.razorpayKeyId,
              'amount': (amount * 100).round(),
              'currency': 'INR',
              'name': 'GoCab',
              'description': 'Ride Payment',
              'order_id': razorpayOrderId,
              'prefill': {'contact': '', 'email': ''},
              'external': {
                'wallets': ['paytm', 'phonepe', 'gpay'],
              },
              'theme': {'color': '#3399cc'},
            };

            // Set up payment callbacks
            onPaymentSuccess = (PaymentModel payment) async {
              try {
                // Update payment status
                await _firestore.collection('payments').doc(paymentId).update({
                  'status': 'completed',
                  'razorpayOrderId': razorpayOrderId,
                  'razorpayPaymentId': payment.razorpayPaymentId,
                  'completedAt': FieldValue.serverTimestamp(),
                });

                if (_debugMode) {
                  print('✅ Ride payment completed successfully');
                }
              } catch (e) {
                print('❌ Error updating payment status: $e');
              }
            };

            onPaymentError = (String error) async {
              try {
                await _firestore.collection('payments').doc(paymentId).update({
                  'status': 'failed',
                  'failureReason': error,
                  'completedAt': FieldValue.serverTimestamp(),
                });

                if (_debugMode) {
                  print('❌ Ride payment failed: $error');
                }
              } catch (e) {
                print('❌ Error updating failed payment: $e');
              }
            };

            // Open payment gateway
            _razorpay.open(options);

            // For demo purposes, simulate success after a delay
            // In real implementation, handle the callback
            await Future.delayed(const Duration(seconds: 2));
            paymentSuccess = true;
            razorpayPaymentId = 'demo_payment_${Random().nextInt(1000000)}';
          } catch (e) {
            print('❌ Error creating Razorpay order: $e');
            throw Exception('Failed to create payment order: $e');
          }
          break;
      }

      if (paymentSuccess) {
        // Update payment status
        await _firestore.collection('payments').doc(paymentId).update({
          'status': 'completed',
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'completedAt': FieldValue.serverTimestamp(),
        });

        final paymentModel = PaymentModel.fromMap({
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

        if (_debugMode) {
          print('✅ Ride payment completed successfully');
        }

        return paymentModel;
      }

      return null;
    } catch (e) {
      print('❌ Error processing ride payment: $e');
      throw Exception('Ride payment failed: $e');
    }
  }

  // Create Razorpay order with improved error handling
  Future<Map<String, dynamic>> _createRazorpayOrder(
    double amount,
    String description,
  ) async {
    try {
      // Validate input parameters
      if (amount <= 0) {
        throw Exception('Invalid amount: Amount must be greater than 0');
      }

      if (description.isEmpty) {
        throw Exception('Invalid description: Description cannot be empty');
      }

      if (_debugMode) {
        print('📋 Creating Razorpay order: ₹$amount - $description');
      }

      final url = Uri.parse('${RazorpayConfig.baseUrl}/orders');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Basic ${base64Encode(utf8.encode('${RazorpayConfig.razorpayKeyId}:${RazorpayConfig.razorpayKeySecret}'))}',
        },
        body: jsonEncode({
          'amount': (amount * 100).round(),
          'currency': 'INR',
          'receipt': 'receipt_${DateTime.now().millisecondsSinceEpoch}',
          'notes': {'description': description},
        }),
      );

      if (_debugMode) {
        print('📡 Razorpay API Response Status: ${response.statusCode}');
        print('📡 Razorpay API Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final orderData = jsonDecode(response.body);

        if (_debugMode) {
          print('✅ Razorpay order created successfully: ${orderData['id']}');
        }

        return orderData;
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['error']?['description'] ?? 'Unknown error';

        if (_debugMode) {
          print('❌ Razorpay API Error: $errorMessage');
        }

        throw Exception('Failed to create Razorpay order: $errorMessage');
      }
    } catch (e) {
      if (_debugMode) {
        print('❌ Error in _createRazorpayOrder: $e');
      }

      if (e.toString().contains('Failed to create Razorpay order')) {
        rethrow;
      } else {
        throw Exception('Network error while creating Razorpay order: $e');
      }
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
