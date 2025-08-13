import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod { wallet, upi, card }
enum PaymentStatus { pending, processing, completed, failed, refunded }
enum TransactionType { ridePayment, walletRecharge, refund }

class PaymentModel {
  final String id;
  final String userId;
  final String? rideId;
  final double amount;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final TransactionType transactionType;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? upiId;
  final String? cardLast4;
  final String? cardBrand;
  final String? walletId;
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;

  PaymentModel({
    required this.id,
    required this.userId,
    this.rideId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.transactionType,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.upiId,
    this.cardLast4,
    this.cardBrand,
    this.walletId,
    this.description,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      userId: map['userId'] ?? '',
      rideId: map['rideId'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${map['paymentMethod']}',
        orElse: () => PaymentMethod.wallet,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${map['status']}',
        orElse: () => PaymentStatus.pending,
      ),
      transactionType: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${map['transactionType']}',
        orElse: () => TransactionType.ridePayment,
      ),
      razorpayOrderId: map['razorpayOrderId'],
      razorpayPaymentId: map['razorpayPaymentId'],
      upiId: map['upiId'],
      cardLast4: map['cardLast4'],
      cardBrand: map['cardBrand'],
      walletId: map['walletId'],
      description: map['description'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      failureReason: map['failureReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'rideId': rideId,
      'amount': amount,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'status': status.toString().split('.').last,
      'transactionType': transactionType.toString().split('.').last,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'upiId': upiId,
      'cardLast4': cardLast4,
      'cardBrand': cardBrand,
      'walletId': walletId,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'failureReason': failureReason,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? userId,
    String? rideId,
    double? amount,
    PaymentMethod? paymentMethod,
    PaymentStatus? status,
    TransactionType? transactionType,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? upiId,
    String? cardLast4,
    String? cardBrand,
    String? walletId,
    String? description,
    DateTime? createdAt,
    DateTime? completedAt,
    String? failureReason,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      rideId: rideId ?? this.rideId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      transactionType: transactionType ?? this.transactionType,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      upiId: upiId ?? this.upiId,
      cardLast4: cardLast4 ?? this.cardLast4,
      cardBrand: cardBrand ?? this.cardBrand,
      walletId: walletId ?? this.walletId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}

class WalletModel {
  final String id;
  final String userId;
  final double balance;
  final List<String> transactionIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletModel({
    required this.id,
    required this.userId,
    required this.balance,
    required this.transactionIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletModel.fromMap(Map<String, dynamic> map, String id) {
    return WalletModel(
      id: id,
      userId: map['userId'] ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
      transactionIds: List<String>.from(map['transactionIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'balance': balance,
      'transactionIds': transactionIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  WalletModel copyWith({
    String? id,
    String? userId,
    double? balance,
    List<String>? transactionIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      transactionIds: transactionIds ?? this.transactionIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SavedPaymentMethod {
  final String id;
  final String userId;
  final PaymentMethod paymentMethod;
  final String? upiId;
  final String? cardLast4;
  final String? cardBrand;
  final String? cardExpiry;
  final String? cardHolderName;
  final bool isDefault;
  final DateTime createdAt;

  SavedPaymentMethod({
    required this.id,
    required this.userId,
    required this.paymentMethod,
    this.upiId,
    this.cardLast4,
    this.cardBrand,
    this.cardExpiry,
    this.cardHolderName,
    required this.isDefault,
    required this.createdAt,
  });

  factory SavedPaymentMethod.fromMap(Map<String, dynamic> map, String id) {
    return SavedPaymentMethod(
      id: id,
      userId: map['userId'] ?? '',
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${map['paymentMethod']}',
        orElse: () => PaymentMethod.wallet,
      ),
      upiId: map['upiId'],
      cardLast4: map['cardLast4'],
      cardBrand: map['cardBrand'],
      cardExpiry: map['cardExpiry'],
      cardHolderName: map['cardHolderName'],
      isDefault: map['isDefault'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'upiId': upiId,
      'cardLast4': cardLast4,
      'cardBrand': cardBrand,
      'cardExpiry': cardExpiry,
      'cardHolderName': cardHolderName,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  SavedPaymentMethod copyWith({
    String? id,
    String? userId,
    PaymentMethod? paymentMethod,
    String? upiId,
    String? cardLast4,
    String? cardBrand,
    String? cardExpiry,
    String? cardHolderName,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return SavedPaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      upiId: upiId ?? this.upiId,
      cardLast4: cardLast4 ?? this.cardLast4,
      cardBrand: cardBrand ?? this.cardBrand,
      cardExpiry: cardExpiry ?? this.cardExpiry,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
