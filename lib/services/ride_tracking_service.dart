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
      // Use simple query to avoid index issues
      final querySnapshot = await _firestore
          .collection('rides')
          .where('riderId', isEqualTo: userId)
          .get();

      final rides = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return RideModel.fromMap(data);
      }).toList();

      // Filter active rides in application code
      final activeRides = rides
          .where(
            (ride) =>
                ride.status == RideStatus.pending ||
                ride.status == RideStatus.accepted ||
                ride.status == RideStatus.inProgress ||
                ride.status == RideStatus.arrived ||
                ride.status == RideStatus.pickupComplete,
          )
          .toList();

      if (activeRides.isNotEmpty) {
        // Sort by creation date (newest first) and return the most recent
        activeRides.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return activeRides.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current ride: $e');
      return null;
    }
  }

  // Stream current ride updates
  Stream<RideModel?> streamCurrentRide(String userId) {
    try {
      return _firestore
          .collection('rides')
          .where('riderId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final rides = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return RideModel.fromMap(data);
            }).toList();

            // Filter active rides in application code
            final activeRides = rides
                .where(
                  (ride) =>
                      ride.status == RideStatus.pending ||
                      ride.status == RideStatus.accepted ||
                      ride.status == RideStatus.inProgress ||
                      ride.status == RideStatus.arrived ||
                      ride.status == RideStatus.pickupComplete,
                )
                .toList();

            if (activeRides.isNotEmpty) {
              // Sort by creation date (newest first) and return the most recent
              activeRides.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              return activeRides.first;
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

  // Stream ride updates for a specific ride
  Stream<RideModel?> streamRideUpdates(String rideId) {
    try {
      return _firestore
          .collection('rides')
          .doc(rideId)
          .snapshots()
          .map((snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data()!;
              data['id'] = snapshot.id;
              return RideModel.fromMap(data);
            }
            return null;
          })
          .handleError((error) {
            debugPrint('Stream ride updates failed: $error');
            return null;
          });
    } catch (e) {
      debugPrint('Error creating ride updates stream: $e');
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
