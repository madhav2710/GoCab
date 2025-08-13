import 'package:flutter_test/flutter_test.dart';
import 'package:gocab/models/payment_model.dart';

void main() {
  group('Payment Models Tests', () {
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
      expect(payment.amount, 150.0);
      expect(payment.paymentMethod, PaymentMethod.wallet);
      expect(payment.status, PaymentStatus.completed);
      expect(payment.transactionType, TransactionType.ridePayment);
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

    test('PaymentMethod enum values', () {
      expect(PaymentMethod.values.length, 3);
      expect(PaymentMethod.wallet, PaymentMethod.wallet);
      expect(PaymentMethod.upi, PaymentMethod.upi);
      expect(PaymentMethod.card, PaymentMethod.card);
    });

    test('PaymentStatus enum values', () {
      expect(PaymentStatus.values.length, 5);
      expect(PaymentStatus.pending, PaymentStatus.pending);
      expect(PaymentStatus.processing, PaymentStatus.processing);
      expect(PaymentStatus.completed, PaymentStatus.completed);
      expect(PaymentStatus.failed, PaymentStatus.failed);
      expect(PaymentStatus.refunded, PaymentStatus.refunded);
    });

    test('TransactionType enum values', () {
      expect(TransactionType.values.length, 3);
      expect(TransactionType.ridePayment, TransactionType.ridePayment);
      expect(TransactionType.walletRecharge, TransactionType.walletRecharge);
      expect(TransactionType.refund, TransactionType.refund);
    });
  });
}
