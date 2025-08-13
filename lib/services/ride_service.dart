import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';
import 'driver_matching_service.dart';
import 'notification_manager.dart';
import 'notification_service.dart';

class RideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DriverMatchingService _driverMatchingService = DriverMatchingService();
  final NotificationManager _notificationManager = NotificationManager();

  // Create a new ride request
  Future<String> createRideRequest({
    required String riderId,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required String pickupAddress,
    required String dropoffAddress,
    required RideType rideType,
    required double estimatedFare,
  }) async {
    try {
      final rideData = {
        'riderId': riderId,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'dropoffLat': dropoffLat,
        'dropoffLng': dropoffLng,
        'pickupAddress': pickupAddress,
        'dropoffAddress': dropoffAddress,
        'rideType': rideType.toString().split('.').last,
        'estimatedFare': estimatedFare,
        'status': RideStatus.pending.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('rides').add(rideData);

      // Try to find a driver for the ride
      await _findDriverForRide(docRef.id, pickupLat, pickupLng, rideType);

      return docRef.id;
    } catch (e) {
      print('Error creating ride request: $e');
      rethrow;
    }
  }

  // Get rides for a specific rider
  Stream<List<RideModel>> getRidesForRider(String riderId) {
    try {
      return _firestore
          .collection('rides')
          .where('riderId', isEqualTo: riderId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return RideModel.fromMap(data);
            }).toList();
          });
    } catch (e) {
      print('Error getting rides for rider: $e');
      // Return empty stream if there's an index error
      return Stream.value([]);
    }
  }

  // Get current ride for a rider
  Future<RideModel?> getCurrentRide(String riderId) async {
    try {
      // Try the complex query first
      final querySnapshot = await _firestore
          .collection('rides')
          .where('riderId', isEqualTo: riderId)
          .where(
            'status',
            whereIn: [
              RideStatus.pending.toString().split('.').last,
              RideStatus.accepted.toString().split('.').last,
              RideStatus.inProgress.toString().split('.').last,
              RideStatus.arrived.toString().split('.').last,
              RideStatus.pickupComplete.toString().split('.').last,
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
      print('Complex query failed, trying simple query: $e');

      // Fallback to simple query without ordering
      try {
        final querySnapshot = await _firestore
            .collection('rides')
            .where('riderId', isEqualTo: riderId)
            .where(
              'status',
              whereIn: [
                RideStatus.pending.toString().split('.').last,
                RideStatus.accepted.toString().split('.').last,
                RideStatus.inProgress.toString().split('.').last,
                RideStatus.arrived.toString().split('.').last,
                RideStatus.pickupComplete.toString().split('.').last,
              ],
            )
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          data['id'] = querySnapshot.docs.first.id;
          return RideModel.fromMap(data);
        }
        return null;
      } catch (e2) {
        print('Simple query also failed: $e2');
        return null;
      }
    }
  }

  // Get pending rides for drivers
  Stream<List<RideModel>> getPendingRides() {
    try {
      return _firestore
          .collection('rides')
          .where(
            'status',
            isEqualTo: RideStatus.pending.toString().split('.').last,
          )
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return RideModel.fromMap(data);
            }).toList();
          });
    } catch (e) {
      print('Complex pending rides query failed, trying simple query: $e');

      // Fallback to simple query without ordering
      try {
        return _firestore
            .collection('rides')
            .where(
              'status',
              isEqualTo: RideStatus.pending.toString().split('.').last,
            )
            .snapshots()
            .map((snapshot) {
              return snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return RideModel.fromMap(data);
              }).toList();
            });
      } catch (e2) {
        print('Simple pending rides query also failed: $e2');
        return Stream.value([]);
      }
    }
  }

  // Assign driver to a ride
  Future<void> assignDriverToRide(String rideId, String driverId) async {
    try {
      if (rideId.isEmpty) {
        throw Exception('Ride ID is required');
      }
      
      if (driverId.isEmpty) {
        throw Exception('Driver ID is required');
      }

      // First get the ride document to get the rider ID
      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      if (!rideDoc.exists) {
        throw Exception('Ride not found');
      }

      final rideData = rideDoc.data()!;
      final riderId = rideData['riderId'] as String?;
      
      if (riderId == null || riderId.isEmpty) {
        throw Exception('Rider ID not found in ride data');
      }

      // Check if ride is already assigned
      final currentStatus = rideData['status'] as String?;
      if (currentStatus == RideStatus.accepted.toString().split('.').last) {
        throw Exception('Ride is already assigned to a driver');
      }

      // Update the ride with driver ID and status
      await _firestore.collection('rides').doc(rideId).update({
        'driverId': driverId,
        'status': RideStatus.accepted.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to rider
      try {
        await _notificationManager.sendRideStatusToRider(
          rideId: rideId,
          riderId: riderId,
          title: 'Driver Found!',
          body: 'A driver has accepted your ride request.',
          type: NotificationType.rideStatus,
        );
      } catch (notificationError) {
        print('Error sending notification: $notificationError');
        // Don't throw here as the main operation succeeded
      }
    } catch (e) {
      print('Error assigning driver to ride: $e');
      rethrow;
    }
  }

  // Update ride status
  Future<void> updateRideStatus(String rideId, RideStatus status) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating ride status: $e');
      rethrow;
    }
  }

  // Calculate estimated fare (simple calculation)
  double calculateEstimatedFare(double distance, RideType rideType) {
    const baseFare = 2.0;
    const perKmRate = 1.5;
    const carpoolDiscount = 0.2; // 20% discount for carpool

    double fare = baseFare + (distance * perKmRate);

    if (rideType == RideType.carpool) {
      fare = fare * (1 - carpoolDiscount);
    }

    return double.parse(fare.toStringAsFixed(2));
  }

  // Find driver for a ride
  Future<void> _findDriverForRide(
    String rideId,
    double pickupLat,
    double pickupLng,
    RideType rideType,
  ) async {
    try {
      final nearestDriver = await _driverMatchingService.findNearestDriver(
        pickupLatitude: pickupLat,
        pickupLongitude: pickupLng,
        rideType: rideType,
      );

      if (nearestDriver != null) {
        // Auto-assign the nearest driver
        await assignDriverToRide(rideId, nearestDriver.uid);
      }
    } catch (e) {
      print('Error finding driver for ride: $e');
    }
  }

  // Get ride by ID
  Future<RideModel?> getRideById(String rideId) async {
    try {
      final doc = await _firestore.collection('rides').doc(rideId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return RideModel.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Error getting ride by ID: $e');
      return null;
    }
  }

  // Get driver for a ride
  Future<UserModel?> getDriverById(String driverId) async {
    try {
      final doc = await _firestore.collection('users').doc(driverId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting driver by ID: $e');
      return null;
    }
  }
}
