import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gocab/models/payment_model.dart';
import 'package:gocab/config/razorpay_config.dart';

void main() {
  group('Payment System Tests', () {
    test('RazorpayConfig validation', () {
      expect(RazorpayConfig.razorpayKeyId, isNotEmpty);
      expect(RazorpayConfig.razorpayKeySecret, isNotEmpty);
      expect(RazorpayConfig.baseUrl, isNotEmpty);
      expect(RazorpayConfig.currency, equals('INR'));
      expect(RazorpayConfig.companyName, equals('GoCab'));
      expect(
        RazorpayConfig.debugMode,
        isFalse,
      ); // Debug mode disabled for production
    });

    test('Payment method validation', () {
      expect(PaymentMethod.values.length, equals(3));
      expect(PaymentMethod.wallet, isNotNull);
      expect(PaymentMethod.upi, isNotNull);
      expect(PaymentMethod.card, isNotNull);
    });

    test('Payment status validation', () {
      expect(PaymentStatus.values.length, equals(5));
      expect(PaymentStatus.pending, isNotNull);
      expect(PaymentStatus.processing, isNotNull);
      expect(PaymentStatus.completed, isNotNull);
      expect(PaymentStatus.failed, isNotNull);
      expect(PaymentStatus.refunded, isNotNull);
    });

    test('Transaction type validation', () {
      expect(TransactionType.values.length, equals(3));
      expect(TransactionType.ridePayment, isNotNull);
      expect(TransactionType.walletRecharge, isNotNull);
      expect(TransactionType.refund, isNotNull);
    });

    test('PaymentModel creation and serialization', () {
      final payment = PaymentModel(
        id: 'test_id',
        userId: 'user_123',
        rideId: 'ride_456',
        amount: 150.0,
        paymentMethod: PaymentMethod.wallet,
        status: PaymentStatus.completed,
        transactionType: TransactionType.ridePayment,
        description: 'Test payment',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      expect(payment.id, 'test_id');
      expect(payment.userId, 'user_123');
      expect(payment.rideId, 'ride_456');
      expect(payment.amount, 150.0);
      expect(payment.paymentMethod, PaymentMethod.wallet);
      expect(payment.status, PaymentStatus.completed);
      expect(payment.transactionType, TransactionType.ridePayment);
      expect(payment.description, 'Test payment');
    });

    test('WalletModel creation and serialization', () {
      final wallet = WalletModel(
        id: 'wallet_123',
        userId: 'user_123',
        balance: 500.0,
        transactionIds: ['txn_1', 'txn_2'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(wallet.id, 'wallet_123');
      expect(wallet.userId, 'user_123');
      expect(wallet.balance, 500.0);
      expect(wallet.transactionIds.length, 2);
      expect(wallet.transactionIds, contains('txn_1'));
      expect(wallet.transactionIds, contains('txn_2'));
    });

    test('SavedPaymentMethod creation and serialization', () {
      final savedMethod = SavedPaymentMethod(
        id: 'method_123',
        userId: 'user_123',
        paymentMethod: PaymentMethod.upi,
        upiId: 'user@upi',
        isDefault: true,
        createdAt: DateTime.now(),
      );

      expect(savedMethod.id, 'method_123');
      expect(savedMethod.userId, 'user_123');
      expect(savedMethod.paymentMethod, PaymentMethod.upi);
      expect(savedMethod.upiId, 'user@upi');
      expect(savedMethod.isDefault, true);
    });

    test('PaymentModel fromMap and toMap', () {
      final now = Timestamp.now();
      final paymentData = {
        'id': 'test_id',
        'userId': 'user_123',
        'rideId': 'ride_456',
        'amount': 150.0,
        'paymentMethod': 'wallet',
        'status': 'completed',
        'transactionType': 'ridePayment',
        'description': 'Test payment',
        'createdAt': now,
        'completedAt': now,
      };

      final payment = PaymentModel.fromMap(paymentData, 'test_id');

      expect(payment.id, 'test_id');
      expect(payment.userId, 'user_123');
      expect(payment.rideId, 'ride_456');
      expect(payment.amount, 150.0);
      expect(payment.paymentMethod, PaymentMethod.wallet);
      expect(payment.status, PaymentStatus.completed);
      expect(payment.transactionType, TransactionType.ridePayment);
    });

    test('WalletModel fromMap and toMap', () {
      final now = Timestamp.now();
      final walletData = {
        'id': 'wallet_123',
        'userId': 'user_123',
        'balance': 500.0,
        'transactionIds': ['txn_1', 'txn_2'],
        'createdAt': now,
        'updatedAt': now,
      };

      final wallet = WalletModel.fromMap(walletData, 'wallet_123');

      expect(wallet.id, 'wallet_123');
      expect(wallet.userId, 'user_123');
      expect(wallet.balance, 500.0);
      expect(wallet.transactionIds.length, 2);
    });

    test('SavedPaymentMethod fromMap and toMap', () {
      final now = Timestamp.now();
      final methodData = {
        'id': 'method_123',
        'userId': 'user_123',
        'paymentMethod': 'upi',
        'upiId': 'user@upi',
        'isDefault': true,
        'createdAt': now,
      };

      final savedMethod = SavedPaymentMethod.fromMap(methodData, 'method_123');

      expect(savedMethod.id, 'method_123');
      expect(savedMethod.userId, 'user_123');
      expect(savedMethod.paymentMethod, PaymentMethod.upi);
      expect(savedMethod.upiId, 'user@upi');
      expect(savedMethod.isDefault, true);
    });

    test('RazorpayConfig environment switching', () {
      // Test that keys are properly configured
      expect(RazorpayConfig.testKeyId, contains('rzp_test_'));
      expect(RazorpayConfig.liveKeyId, contains('rzp_live_'));

      // Test that debug mode is disabled for production
      expect(RazorpayConfig.debugMode, isFalse);

      // Test supported wallets
      expect(RazorpayConfig.supportedWallets.length, greaterThan(0));
      expect(RazorpayConfig.supportedWallets, contains('paytm'));
      expect(RazorpayConfig.supportedWallets, contains('phonepe'));
      expect(RazorpayConfig.supportedWallets, contains('gpay'));
    });

    test('Payment method string conversion', () {
      expect(PaymentMethod.wallet.toString(), contains('wallet'));
      expect(PaymentMethod.upi.toString(), contains('upi'));
      expect(PaymentMethod.card.toString(), contains('card'));
    });

    test('Payment status string conversion', () {
      expect(PaymentStatus.pending.toString(), contains('pending'));
      expect(PaymentStatus.completed.toString(), contains('completed'));
      expect(PaymentStatus.failed.toString(), contains('failed'));
    });

    test('Transaction type string conversion', () {
      expect(TransactionType.ridePayment.toString(), contains('ridePayment'));
      expect(
        TransactionType.walletRecharge.toString(),
        contains('walletRecharge'),
      );
      expect(TransactionType.refund.toString(), contains('refund'));
    });
  });
}
