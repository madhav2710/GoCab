import 'dart:async';
import 'dart:math' as math;
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
      final querySnapshot = await _firestore
          .collection('rides')
          .where('riderId', isEqualTo: userId)
          .where('status', whereIn: [
            RideStatus.pending.toString().split('.').last,
            RideStatus.accepted.toString().split('.').last,
            RideStatus.inProgress.toString().split('.').last,
            RideStatus.arrived.toString().split('.').last,
            RideStatus.pickupComplete.toString().split('.').last,
          ])
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
      print('Error getting current ride: $e');
      return null;
    }
  }

  // Stream current ride updates
  Stream<RideModel?> streamCurrentRide(String userId) {
    try {
      return _firestore
          .collection('rides')
          .where('riderId', isEqualTo: userId)
          .where('status', whereIn: [
            RideStatus.pending.toString().split('.').last,
            RideStatus.accepted.toString().split('.').last,
            RideStatus.inProgress.toString().split('.').last,
            RideStatus.arrived.toString().split('.').last,
            RideStatus.pickupComplete.toString().split('.').last,
          ])
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
      });
    } catch (e) {
      print('Error streaming current ride: $e');
      return Stream.value(null);
    }
  }

  // Get driver location updates
  Stream<UserModel?> streamDriverLocation(String driverId) {
    try {
      return _firestore
          .collection('users')
          .doc(driverId)
          .snapshots()
          .map((snapshot) {
        if (snapshot.exists) {
          return UserModel.fromMap(snapshot.data()!);
        }
        return null;
      });
    } catch (e) {
      print('Error streaming driver location: $e');
      return Stream.value(null);
    }
  }

  // Update driver location
  Future<void> updateDriverLocation(String driverId, double latitude, double longitude) async {
    try {
      await _firestore.collection('users').doc(driverId).update({
        'latitude': latitude,
        'longitude': longitude,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating driver location: $e');
    }
  }

  // Update ride status
  Future<void> updateRideStatus(String rideId, RideStatus status) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send appropriate notifications based on status
      await _sendStatusNotification(rideId, status);
    } catch (e) {
      print('Error updating ride status: $e');
    }
  }

  // Send status-specific notifications
  Future<void> _sendStatusNotification(String rideId, RideStatus status) async {
    try {
      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      if (!rideDoc.exists) return;

      final rideData = rideDoc.data()!;
      final riderId = rideData['riderId'];
      final driverId = rideData['driverId'];

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
      print('Error sending status notification: $e');
    }
  }

  // Calculate ETA between two points (simplified)
  Future<Duration> calculateETA(double fromLat, double fromLng, double toLat, double toLng) async {
    try {
      // Simple distance calculation using Haversine formula
      final distance = _calculateDistance(fromLat, fromLng, toLat, toLng);
      
      // Assume average speed of 30 km/h in city traffic
      const averageSpeedKmh = 30.0;
      final timeInHours = distance / averageSpeedKmh;
      final timeInMinutes = (timeInHours * 60).round();
      
      return Duration(minutes: timeInMinutes);
    } catch (e) {
      print('Error calculating ETA: $e');
      return const Duration(minutes: 10); // Default fallback
    }
  }

  // Haversine formula to calculate distance
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);

    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
