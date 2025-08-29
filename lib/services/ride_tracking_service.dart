import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';
import 'notification_manager.dart';
import 'notification_service.dart';

class RideTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationManager _notificationManager = NotificationManager();

  // Get current ride for a user
  Future<RideModel?> getCurrentRide(String userId) async {
    try {
      // Try the complex query first
      final querySnapshot = await _firestore
          .collection('rides')
          .where('riderId', isEqualTo: userId)
          .where(
            'status',
            whereIn: [
              'pending',
              'accepted',
              'inProgress',
              'arrived',
              'pickupComplete',
            ],
          )
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        data['id'] = querySnapshot.docs.first.id;
        return RideModel.fromMap(data);
      }
      return null;
    } catch (e) {
      debugPrint('Complex query failed, trying fallback: $e');
      // Fallback: simple query without orderBy
      try {
        final querySnapshot = await _firestore
            .collection('rides')
            .where('riderId', isEqualTo: userId)
            .where(
              'status',
              whereIn: [
                'pending',
                'accepted',
                'inProgress',
                'arrived',
                'pickupComplete',
              ],
            )
            .limit(10)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Sort manually and get the most recent
          final sortedDocs = querySnapshot.docs.toList()
            ..sort((a, b) {
              final aTime = a.data()['createdAt'] as Timestamp?;
              final bTime = b.data()['createdAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime);
            });

          final data = sortedDocs.first.data();
          data['id'] = sortedDocs.first.id;
          return RideModel.fromMap(data);
        }
        return null;
      } catch (fallbackError) {
        debugPrint('Fallback query also failed: $fallbackError');
        return null;
      }
    }
  }

  // Stream current ride updates
  Stream<RideModel?> streamCurrentRide(String userId) {
    try {
      return _firestore
          .collection('rides')
          .where('riderId', isEqualTo: userId)
          .where(
            'status',
            whereIn: [
              'pending',
              'accepted',
              'inProgress',
              'arrived',
              'pickupComplete',
            ],
          )
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              final data = snapshot.docs.first.data();
              data['id'] = snapshot.docs.first.id;
              return RideModel.fromMap(data);
            }
            return null;
          })
          .handleError((error) {
            debugPrint('Stream query failed: $error');
            return null;
          });
    } catch (e) {
      debugPrint('Error creating stream: $e');
      return Stream.value(null);
    }
  }

  // Get driver location updates
  Stream<UserModel?> streamDriverLocation(String driverId) {
    try {
      return _firestore.collection('users').doc(driverId).snapshots().map((
        snapshot,
      ) {
        if (snapshot.exists) {
          return UserModel.fromMap(snapshot.data()!);
        }
        return null;
      });
    } catch (e) {
      debugPrint('Error streaming driver location: $e');
      return Stream.value(null);
    }
  }

  // Update driver location
  Future<void> updateDriverLocation(
    String driverId,
    double latitude,
    double longitude,
  ) async {
    try {
      await _firestore.collection('users').doc(driverId).update({
        'latitude': latitude,
        'longitude': longitude,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating driver location: $e');
    }
  }

  // Update ride status
  Future<void> updateRideStatus(String rideId, RideStatus status) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send appropriate notifications based on status
      await _sendStatusNotification(rideId, status);
    } catch (e) {
      debugPrint('Error updating ride status: $e');
    }
  }

  // Send status-specific notifications
  Future<void> _sendStatusNotification(String rideId, RideStatus status) async {
    try {
      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      if (!rideDoc.exists) return;

      final rideData = rideDoc.data()!;
      final riderId = rideData['riderId'];
      // final driverId = rideData['driverId'];

      String title = '';
      String body = '';

      switch (status) {
        case RideStatus.accepted:
          title = 'Driver Found!';
          body = 'A driver has accepted your ride request.';
          break;
        case RideStatus.inProgress:
          title = 'Trip Started';
          body = 'Your driver has started the trip.';
          break;
        case RideStatus.arrived:
          title = 'Driver Arrived';
          body = 'Your driver has arrived at the pickup location.';
          break;
        case RideStatus.pickupComplete:
          title = 'On the Way';
          body = 'You\'re on your way to your destination.';
          break;
        case RideStatus.completed:
          title = 'Trip Completed';
          body = 'Your trip has been completed. Please rate your driver.';
          break;
        default:
          return;
      }

      if (riderId != null) {
        await _notificationManager.sendRideStatusToRider(
          rideId: rideId,
          riderId: riderId,
          title: title,
          body: body,
          type: NotificationType.rideStatus,
        );
      }
    } catch (e) {
      debugPrint('Error sending status notification: $e');
    }
  }

  // Calculate ETA between two points (simplified)
  Future<Duration> calculateETA(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) async {
    try {
      // Simple distance calculation using Haversine formula
      final distance = _calculateDistance(fromLat, fromLng, toLat, toLng);

      // Assume average speed of 30 km/h in city traffic
      const averageSpeedKmh = 30.0;
      final timeInHours = distance / averageSpeedKmh;
      final timeInMinutes = (timeInHours * 60).round();

      return Duration(minutes: timeInMinutes);
    } catch (e) {
      debugPrint('Error calculating ETA: $e');
      return const Duration(minutes: 10); // Default fallback
    }
  }

  // Haversine formula to calculate distance
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
