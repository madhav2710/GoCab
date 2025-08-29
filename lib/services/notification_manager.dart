import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class NotificationManager {
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize notification manager
  Future<void> initialize() async {
    await _notificationService.initialize();
  }

  // Update user's FCM token
  Future<void> updateUserFCMToken(String userId, String? token) async {
    await _notificationService.updateFCMToken(userId, token);

    // Subscribe to role-based topics
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      final role = userData['role'] == 'driver'
          ? UserRole.driver
          : UserRole.rider;
      await _notificationService.subscribeToRoleTopics(role);
    }
  }

  // Send ride request notification to available drivers
  Future<void> sendRideRequestToDrivers(
    RideModel ride,
    String riderName,
  ) async {
    try {
      // Get available drivers near the pickup location
      final driversQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .where('isAvailable', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      for (final driverDoc in driversQuery.docs) {
        final driverData = driverDoc.data();
        final fcmToken = driverData['fcmToken'];

        if (fcmToken != null) {
          await _notificationService.sendRideRequestNotification(
            driverFCMToken: fcmToken,
            ride: ride,
            riderName: riderName,
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending ride request notifications: $e');
    }
  }

  // Send ride status update to rider
  Future<void> sendRideStatusToRider({
    required String rideId,
    required String riderId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final riderDoc = await _firestore.collection('users').doc(riderId).get();
      if (riderDoc.exists) {
        final riderData = riderDoc.data()!;
        final fcmToken = riderData['fcmToken'];

        if (fcmToken != null) {
          await _notificationService.sendRideStatusNotification(
            fcmToken: fcmToken,
            title: title,
            body: body,
            rideId: rideId,
            type: type,
            additionalData: additionalData,
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending ride status notification: $e');
    }
  }

  // Send ride status update to driver
  Future<void> sendRideStatusToDriver({
    required String rideId,
    required String driverId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final driverDoc = await _firestore
          .collection('users')
          .doc(driverId)
          .get();
      if (driverDoc.exists) {
        final driverData = driverDoc.data()!;
        final fcmToken = driverData['fcmToken'];

        if (fcmToken != null) {
          await _notificationService.sendRideStatusNotification(
            fcmToken: fcmToken,
            title: title,
            body: body,
            rideId: rideId,
            type: type,
            additionalData: additionalData,
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending ride status notification to driver: $e');
    }
  }

  // Send driver arrival notification
  Future<void> sendDriverArrivalNotification({
    required String rideId,
    required String riderId,
    required String driverId,
    required String pickupAddress,
  }) async {
    try {
      final driverDoc = await _firestore
          .collection('users')
          .doc(driverId)
          .get();
      final riderDoc = await _firestore.collection('users').doc(riderId).get();

      if (driverDoc.exists && riderDoc.exists) {
        final driverData = driverDoc.data()!;
        final riderData = riderDoc.data()!;
        final riderFCMToken = riderData['fcmToken'];
        final driverName = driverData['name'] ?? 'Driver';

        if (riderFCMToken != null) {
          await _notificationService.sendDriverArrivalNotification(
            riderFCMToken: riderFCMToken,
            driverName: driverName,
            rideId: rideId,
            pickupAddress: pickupAddress,
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending driver arrival notification: $e');
    }
  }

  // Send ride completion notification
  Future<void> sendRideCompletionNotification({
    required String rideId,
    required String riderId,
    required String driverId,
    required double fare,
  }) async {
    try {
      // Send to rider
      await sendRideStatusToRider(
        rideId: rideId,
        riderId: riderId,
        title: 'Ride Completed',
        body:
            'Your ride has been completed. Fare: \$${fare.toStringAsFixed(2)}',
        type: NotificationType.rideCompleted,
        additionalData: {'fare': fare},
      );

      // Send to driver
      await sendRideStatusToDriver(
        rideId: rideId,
        driverId: driverId,
        title: 'Ride Completed',
        body:
            'Ride completed successfully. Earnings: \$${fare.toStringAsFixed(2)}',
        type: NotificationType.rideCompleted,
        additionalData: {'fare': fare},
      );
    } catch (e) {
      debugPrint('Error sending ride completion notification: $e');
    }
  }

  // Send payment notification
  Future<void> sendPaymentNotification({
    required String userId,
    required String title,
    required String body,
    required String paymentId,
    required double amount,
    required String status,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final fcmToken = userData['fcmToken'];

        if (fcmToken != null) {
          await _notificationService.sendPaymentNotification(
            fcmToken: fcmToken,
            title: title,
            body: body,
            paymentId: paymentId,
            amount: amount,
            status: status,
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending payment notification: $e');
    }
  }

  // Send feedback reminder
  Future<void> sendFeedbackReminder({
    required String rideId,
    required String riderId,
    required String driverId,
  }) async {
    try {
      final driverDoc = await _firestore
          .collection('users')
          .doc(driverId)
          .get();
      final riderDoc = await _firestore.collection('users').doc(riderId).get();

      if (driverDoc.exists && riderDoc.exists) {
        final driverData = driverDoc.data()!;
        final riderData = riderDoc.data()!;
        final riderFCMToken = riderData['fcmToken'];
        final driverName = driverData['name'] ?? 'Driver';

        if (riderFCMToken != null) {
          await _notificationService.sendFeedbackReminder(
            fcmToken: riderFCMToken,
            rideId: rideId,
            driverName: driverName,
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending feedback reminder: $e');
    }
  }

  // Send promotion notification to all users
  Future<void> sendPromotionToAllUsers({
    required String title,
    required String body,
    required String promotionId,
    String? imageUrl,
  }) async {
    try {
      // Send to topic for all users
      await _notificationService.sendPromotionNotification(
        fcmToken: 'topic_all_users', // This would be handled by your backend
        title: title,
        body: body,
        promotionId: promotionId,
        imageUrl: imageUrl,
      );
    } catch (e) {
      debugPrint('Error sending promotion notification: $e');
    }
  }

  // Send promotion notification to specific user role
  Future<void> sendPromotionToRole({
    required UserRole role,
    required String title,
    required String body,
    required String promotionId,
    String? imageUrl,
  }) async {
    try {
      final topic = role == UserRole.driver ? 'topic_drivers' : 'topic_riders';
      await _notificationService.sendPromotionNotification(
        fcmToken: topic, // This would be handled by your backend
        title: title,
        body: body,
        promotionId: promotionId,
        imageUrl: imageUrl,
      );
    } catch (e) {
      debugPrint('Error sending promotion notification to role: $e');
    }
  }

  // Send emergency alert
  Future<void> sendEmergencyAlert({
    required String title,
    required String body,
    required String alertType,
    Map<String, dynamic>? emergencyData,
    String? specificUserId,
  }) async {
    try {
      if (specificUserId != null) {
        // Send to specific user
        final userDoc = await _firestore
            .collection('users')
            .doc(specificUserId)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final fcmToken = userData['fcmToken'];

          if (fcmToken != null) {
            await _notificationService.sendEmergencyAlert(
              fcmToken: fcmToken,
              title: title,
              body: body,
              alertType: alertType,
              emergencyData: emergencyData,
            );
          }
        }
      } else {
        // Send to all users (this would be handled by your backend)
        await _notificationService.sendEmergencyAlert(
          fcmToken: 'topic_all_users',
          title: title,
          body: body,
          alertType: alertType,
          emergencyData: emergencyData,
        );
      }
    } catch (e) {
      debugPrint('Error sending emergency alert: $e');
    }
  }

  // Send system notification
  Future<void> sendSystemNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final fcmToken = userData['fcmToken'];

        if (fcmToken != null) {
          // Send system notification using the public method
          await _notificationService.sendRideStatusNotification(
            fcmToken: fcmToken,
            title: title,
            body: body,
            rideId: 'system',
            type: NotificationType.system,
            additionalData: data,
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending system notification: $e');
    }
  }

  // Handle ride status changes and send appropriate notifications
  Future<void> handleRideStatusChange({
    required RideModel ride,
    required RideStatus oldStatus,
    required RideStatus newStatus,
  }) async {
    try {
      switch (newStatus) {
        case RideStatus.accepted:
          await sendRideStatusToRider(
            rideId: ride.id,
            riderId: ride.riderId,
            title: 'Driver Assigned',
            body: 'A driver has been assigned to your ride',
            type: NotificationType.rideStatus,
            additionalData: {'driverId': ride.driverId},
          );
          break;

        case RideStatus.inProgress:
          await sendRideStatusToRider(
            rideId: ride.id,
            riderId: ride.riderId,
            title: 'Ride Started',
            body: 'Your ride has started',
            type: NotificationType.rideStatus,
          );
          break;

        case RideStatus.arrived:
          if (ride.driverId != null) {
            await sendDriverArrivalNotification(
              rideId: ride.id,
              riderId: ride.riderId,
              driverId: ride.driverId!,
              pickupAddress: ride.pickupAddress,
            );
          }
          break;

        case RideStatus.completed:
          if (ride.driverId != null) {
            await sendRideCompletionNotification(
              rideId: ride.id,
              riderId: ride.riderId,
              driverId: ride.driverId!,
              fare: ride.actualFare ?? ride.estimatedFare,
            );
          }
          break;

        case RideStatus.cancelled:
          await sendRideStatusToRider(
            rideId: ride.id,
            riderId: ride.riderId,
            title: 'Ride Cancelled',
            body: 'Your ride has been cancelled',
            type: NotificationType.rideStatus,
          );
          if (ride.driverId != null) {
            await sendRideStatusToDriver(
              rideId: ride.id,
              driverId: ride.driverId!,
              title: 'Ride Cancelled',
              body: 'The ride has been cancelled',
              type: NotificationType.rideStatus,
            );
          }
          break;

        default:
          break;
      }
    } catch (e) {
      debugPrint('Error handling ride status change: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _notificationService.clearAllNotifications();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await _notificationService.areNotificationsEnabled();
  }

  // Get notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    return await _notificationService.getNotificationSettings();
  }
}
