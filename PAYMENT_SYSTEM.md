# GoCab Digital Payment System

## Overview

The GoCab app now includes a comprehensive digital payment system that supports multiple payment methods and integrates with Razorpay for secure transactions. The system handles wallet management, payment processing, and transaction history.

## Features

### 1. Multiple Payment Methods

- **Wallet**: In-app wallet for storing and using funds
- **UPI**: Unified Payment Interface for instant transfers
- **Card**: Credit and debit card payments

### 2. Wallet Management

- Real-time balance tracking
- Transaction history
- Wallet recharge functionality
- Automatic fare deduction

### 3. Payment Processing

- Secure payment processing via Razorpay
- Automatic fare deduction post-ride
- Payment status tracking
- Transaction receipts

### 4. User Experience

- Modern, intuitive payment UI
- Payment method selection during ride booking
- Real-time payment status updates
- Comprehensive transaction history

## Technical Implementation

### Models

#### PaymentModel

```dart
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
  // ... other fields
}
```

#### WalletModel

```dart
class WalletModel {
  final String id;
  final String userId;
  final double balance;
  final List<String> transactionIds;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### SavedPaymentMethod

```dart
class SavedPaymentMethod {
  final String id;
  final String userId;
  final PaymentMethod paymentMethod;
  final String? upiId;
  final String? cardLast4;
  final String? cardBrand;
  final bool isDefault;
  // ... other fields
}
```

### Services

#### PaymentService

The core service that handles all payment-related operations:

- **Wallet Management**: Create, update, and track wallet balances
- **Payment Processing**: Handle ride payments and wallet recharges
- **Razorpay Integration**: Create orders and process payments
- **Transaction History**: Retrieve and manage payment records
- **Saved Payment Methods**: Manage user's preferred payment methods

#### Key Methods:

```dart
// Wallet operations
Future<WalletModel?> getWallet(String userId)
Stream<WalletModel?> getWalletStream(String userId)
Future<PaymentModel?> rechargeWallet({...})

// Payment processing
Future<PaymentModel?> processRidePayment({...})
Future<PaymentModel?> processRefund({...})

// Payment history
Stream<List<PaymentModel>> getPaymentHistory(String userId)
```

### UI Components

#### PaymentMethodSelector

A reusable widget for selecting payment methods with visual indicators and balance display.

#### WalletRechargeWidget

A comprehensive widget for recharging the wallet with preset amounts and custom input.

#### PaymentHistoryWidget

Displays transaction history with detailed information about each payment.

#### WalletScreen

The main wallet interface showing balance, transaction history, and payment methods.

## Setup Instructions

### 1. Dependencies

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  razorpay_flutter: ^1.3.5
  http: ^1.1.0
```

### 2. Razorpay Configuration

Replace the placeholder keys in `lib/services/payment_service.dart`:

```dart
static const String _razorpayKeyId = 'rzp_test_YOUR_KEY_ID';
static const String _razorpayKeySecret = 'YOUR_KEY_SECRET';
```

### 3. Firebase Collections

The system uses the following Firestore collections:

- `wallets`: User wallet information
- `payments`: Payment transaction records
- `saved_payment_methods`: User's saved payment methods

## Usage Examples

### 1. Recharging Wallet

```dart
final payment = await paymentService.rechargeWallet(
  userId: user.uid,
  amount: 500.0,
  paymentMethod: PaymentMethod.upi,
);
```

### 2. Processing Ride Payment

```dart
final payment = await paymentService.processRidePayment(
  userId: user.uid,
  rideId: ride.id,
  amount: estimatedFare,
  paymentMethod: PaymentMethod.wallet,
);
```

### 3. Getting Payment History

```dart
paymentService.getPaymentHistory(userId).listen((payments) {
  // Handle payment history updates
});
```

### 4. Using Payment Method Selector

```dart
PaymentMethodSelector(
  selectedMethod: selectedMethod,
  onMethodSelected: (method) {
    setState(() {
      selectedMethod = method;
    });
  },
  walletBalance: wallet?.balance,
  showWallet: true,
)
```

## Payment Flow

### 1. Ride Booking Flow

1. User selects pickup and dropoff locations
2. User chooses payment method (Wallet/UPI/Card)
3. User confirms ride booking
4. System processes payment automatically
5. Payment status is updated in Firestore
6. User receives confirmation

### 2. Wallet Recharge Flow

1. User navigates to wallet screen
2. User selects recharge amount
3. User chooses payment method (UPI/Card)
4. System creates Razorpay order
5. User completes payment
6. Wallet balance is updated
7. Transaction is recorded

### 3. Payment Processing Flow

1. Payment request is initiated
2. System validates payment method and amount
3. For wallet payments: Check sufficient balance
4. For UPI/Card: Create Razorpay order
5. Process payment through Razorpay
6. Update payment status in Firestore
7. Update wallet balance if applicable
8. Send confirmation to user

## Security Features

### 1. Payment Validation

- Amount validation before processing
- Wallet balance verification
- Payment method validation

### 2. Transaction Security

- Secure Razorpay integration
- Transaction ID tracking
- Payment status monitoring

### 3. Data Protection

- Encrypted payment data
- Secure API communication
- User authentication required

## Error Handling

The system includes comprehensive error handling for:

- Insufficient wallet balance
- Payment processing failures
- Network connectivity issues
- Invalid payment methods
- Razorpay API errors

## Testing

Run the payment system tests:

```bash
flutter test test/payment_test.dart
```

## Future Enhancements

### Planned Features

1. **Split Payments**: Allow multiple payment methods for a single ride
2. **Payment Plans**: Installment-based payment options
3. **Loyalty Program**: Points and rewards system
4. **Corporate Accounts**: Business payment solutions
5. **International Payments**: Support for multiple currencies

### Technical Improvements

1. **Offline Support**: Cache payment data for offline usage
2. **Biometric Authentication**: Fingerprint/Face ID for payments
3. **Advanced Analytics**: Payment behavior insights
4. **Webhook Integration**: Real-time payment notifications

## Troubleshooting

### Common Issues

1. **Payment Failed**

   - Check internet connectivity
   - Verify payment method details
   - Ensure sufficient balance/wallet funds

2. **Wallet Not Updating**

   - Check Firestore connection
   - Verify user authentication
   - Refresh the wallet screen

3. **Razorpay Integration Issues**
   - Verify API keys
   - Check Razorpay account status
   - Review error logs

### Debug Mode

Enable debug logging by setting:

```dart
static const bool _debugMode = true;
```

## Support

For technical support or questions about the payment system:

1. Check the error logs in the console
2. Verify Firebase configuration
3. Test with different payment methods
4. Review Razorpay documentation

## License

This payment system is part of the GoCab application and follows the same licensing terms.
