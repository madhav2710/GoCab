import 'dart:math';
import '../models/ride_model.dart';
import '../models/user_model.dart';
import '../models/payment_model.dart';
import '../models/feedback_model.dart';

class DemoService {
  static final DemoService _instance = DemoService._internal();
  factory DemoService() => _instance;
  DemoService._internal();

  // Mock user data
  UserModel getMockUser() {
    return UserModel(
      uid: 'demo_user_123',
      name: 'Demo User',
      email: 'demo@example.com',
      phone: '+1234567890',
      role: UserRole.rider,
      isActive: true,
      isAvailable: false,
      latitude: 37.7749,
      longitude: -122.4194,
      fcmToken: 'demo_fcm_token',
      createdAt: DateTime.now(),
    );
  }

  // Mock ride data
  List<RideModel> getMockRides() {
    return [
      RideModel(
        id: 'ride_1',
        riderId: 'demo_user_123',
        driverId: 'demo_driver_1',
        pickupAddress: '123 Main St, San Francisco, CA',
        dropoffAddress: '456 Market St, San Francisco, CA',
        pickupLatitude: 37.7749,
        pickupLongitude: -122.4194,
        dropoffLatitude: 37.7849,
        dropoffLongitude: -122.4094,
        rideType: RideType.solo,
        status: RideStatus.completed,
        estimatedFare: 15.50,
        actualFare: 16.20,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      RideModel(
        id: 'ride_2',
        riderId: 'demo_user_123',
        driverId: 'demo_driver_2',
        pickupAddress: '789 Mission St, San Francisco, CA',
        dropoffAddress: '321 Castro St, San Francisco, CA',
        pickupLatitude: 37.7849,
        pickupLongitude: -122.4094,
        dropoffLatitude: 37.7949,
        dropoffLongitude: -122.3994,
        rideType: RideType.carpool,
        status: RideStatus.pending,
        estimatedFare: 12.00,
        actualFare: null,
        createdAt: DateTime.now(),
      ),
    ];
  }

  // Mock wallet data
  WalletModel getMockWallet() {
    return WalletModel(
      id: 'wallet_1',
      userId: 'demo_user_123',
      balance: 45.75,
      transactionIds: ['txn_1', 'txn_2', 'txn_3'],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  // Mock payment transactions
  List<PaymentModel> getMockPayments() {
    return [
      PaymentModel(
        id: 'txn_1',
        userId: 'demo_user_123',
        rideId: 'ride_1',
        amount: 16.20,
        paymentMethod: PaymentMethod.wallet,
        status: PaymentStatus.completed,
        transactionType: TransactionType.ridePayment,
        description: 'Ride from 123 Main St to 456 Market St',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        completedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      PaymentModel(
        id: 'txn_2',
        userId: 'demo_user_123',
        amount: 50.00,
        paymentMethod: PaymentMethod.card,
        status: PaymentStatus.completed,
        transactionType: TransactionType.walletRecharge,
        description: 'Wallet recharge',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  // Mock feedback data
  List<FeedbackModel> getMockFeedback() {
    return [
      FeedbackModel(
        id: 'feedback_1',
        fromUserId: 'demo_user_123',
        toUserId: 'demo_driver_1',
        rideId: 'ride_1',
        fromUserRole: 'rider',
        toUserRole: 'driver',
        rating: 5,
        feedbackText: 'Great driver, very professional and on time!',
        tags: ['professional', 'on_time', 'clean_vehicle'],
        isAnonymous: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      FeedbackModel(
        id: 'feedback_2',
        fromUserId: 'demo_driver_1',
        toUserId: 'demo_user_123',
        rideId: 'ride_1',
        fromUserRole: 'driver',
        toUserRole: 'rider',
        rating: 5,
        feedbackText: 'Excellent passenger, very polite and punctual.',
        tags: ['polite', 'punctual', 'clean'],
        isAnonymous: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }

  // Mock driver data
  List<UserModel> getMockDrivers() {
    return [
      UserModel(
        uid: 'demo_driver_1',
        name: 'John Driver',
        email: 'john.driver@example.com',
        phone: '+1987654321',
        role: UserRole.driver,
        isActive: true,
        isAvailable: true,
        latitude: 37.7749,
        longitude: -122.4194,
        fcmToken: 'demo_driver_fcm_token',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      UserModel(
        uid: 'demo_driver_2',
        name: 'Sarah Driver',
        email: 'sarah.driver@example.com',
        phone: '+1122334455',
        role: UserRole.driver,
        isActive: true,
        isAvailable: false,
        latitude: 37.7849,
        longitude: -122.4094,
        fcmToken: 'demo_driver_2_fcm_token',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
    ];
  }

  // Generate random location near San Francisco
  Map<String, double> getRandomLocation() {
    final random = Random();
    final lat = 37.7749 + (random.nextDouble() - 0.5) * 0.1; // ±0.05 degrees
    final lng = -122.4194 + (random.nextDouble() - 0.5) * 0.1; // ±0.05 degrees
    return {'latitude': lat, 'longitude': lng};
  }

  // Get random address
  String getRandomAddress() {
    final addresses = [
      '123 Main St, San Francisco, CA',
      '456 Market St, San Francisco, CA',
      '789 Mission St, San Francisco, CA',
      '321 Castro St, San Francisco, CA',
      '654 Haight St, San Francisco, CA',
      '987 Valencia St, San Francisco, CA',
      '147 16th St, San Francisco, CA',
      '258 24th St, San Francisco, CA',
    ];
    return addresses[Random().nextInt(addresses.length)];
  }

  // Calculate mock fare
  double calculateMockFare(double distance, RideType rideType) {
    final baseFare = 2.0;
    final perKmRate = 1.5;
    final carpoolDiscount = 0.2;

    double fare = baseFare + (distance * perKmRate);
    
    if (rideType == RideType.carpool) {
      fare = fare * (1 - carpoolDiscount);
    }

    // Add some randomness
    fare += (Random().nextDouble() - 0.5) * 2.0;
    
    return double.parse(fare.toStringAsFixed(2));
  }
}
