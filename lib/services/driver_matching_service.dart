import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/ride_model.dart';

class DriverMatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Find nearest available driver
  Future<UserModel?> findNearestDriver({
    required double pickupLatitude,
    required double pickupLongitude,
    required RideType rideType,
    double radiusInKm = 10.0, // Search radius in kilometers
  }) async {
    try {
      // Query for available drivers
      final availableDriversQuery = _firestore
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .where('isAvailable', isEqualTo: true)
          .where('isActive', isEqualTo: true);

      // Get available drivers
      final driversSnapshot = await availableDriversQuery.get();
      
      if (driversSnapshot.docs.isEmpty) {
        return null; // No available drivers
      }

      // Calculate distances and find the nearest driver
      UserModel? nearestDriver;
      double? shortestDistance;

      for (final doc in driversSnapshot.docs) {
        final driverData = doc.data();
        final driverLat = driverData['latitude']?.toDouble();
        final driverLng = driverData['longitude']?.toDouble();

        if (driverLat != null && driverLng != null) {
          final distance = _calculateDistance(
            pickupLatitude,
            pickupLongitude,
            driverLat,
            driverLng,
          );

          // Check if driver is within search radius
          if (distance <= radiusInKm) {
            if (shortestDistance == null || distance < shortestDistance) {
              shortestDistance = distance;
              nearestDriver = UserModel.fromMap(driverData);
            }
          }
        }
      }

      return nearestDriver;
    } catch (e) {
      print('Error finding nearest driver: $e');
      return null;
    }
  }

  // Find carpool groups with overlapping routes
  Future<List<RideModel>> findCarpoolGroups({
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
    double maxDistanceKm = 2.0, // Maximum distance for grouping
  }) async {
    try {
      final pendingCarpoolRides = await _firestore
          .collection('rides')
          .where('rideType', isEqualTo: 'carpool')
          .where('status', isEqualTo: 'pending')
          .get();

      final List<RideModel> matchingGroups = [];

      for (final doc in pendingCarpoolRides.docs) {
        final ride = RideModel.fromMap(doc.data());
        
        // Check if pickup locations are close
        final pickupDistance = _calculateDistance(
          pickupLatitude,
          pickupLongitude,
          ride.pickupLatitude,
          ride.pickupLongitude,
        );

        // Check if dropoff locations are close
        final dropoffDistance = _calculateDistance(
          dropoffLatitude,
          dropoffLongitude,
          ride.dropoffLatitude,
          ride.dropoffLongitude,
        );

        // If both pickup and dropoff are within range, consider for grouping
        if (pickupDistance <= maxDistanceKm && dropoffDistance <= maxDistanceKm) {
          matchingGroups.add(ride);
        }
      }

      return matchingGroups;
    } catch (e) {
      print('Error finding carpool groups: $e');
      return [];
    }
  }

  // Update driver availability
  Future<void> updateDriverAvailability({
    required String driverId,
    required bool isAvailable,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'isAvailable': isAvailable,
      };

      if (latitude != null && longitude != null) {
        updateData['latitude'] = latitude;
        updateData['longitude'] = longitude;
      }

      await _firestore
          .collection('users')
          .doc(driverId)
          .update(updateData);
    } catch (e) {
      print('Error updating driver availability: $e');
      rethrow;
    }
  }

  // Update driver location
  Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(driverId)
          .update({
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (e) {
      print('Error updating driver location: $e');
      rethrow;
    }
  }

  // Stream of available drivers for real-time updates
  Stream<List<UserModel>> getAvailableDriversStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .where('isAvailable', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  // Get driver details by ID
  Future<UserModel?> getDriverById(String driverId) async {
    try {
      final doc = await _firestore.collection('users').doc(driverId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting driver details: $e');
      return null;
    }
  }
}
