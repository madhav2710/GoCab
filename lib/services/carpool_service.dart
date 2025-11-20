import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/carpool_ride_model.dart';
import '../models/carpool_request_model.dart';
import '../models/ride_model.dart';
import '../utils/fare_calculator.dart';

class CarpoolService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new carpool ride
  Future<CarpoolRideModel> createCarpoolRide({
    required String driverId,
    required List<CarpoolRider> riders,
    required int maxSeats,
  }) async {
    try {
      // Calculate total fare and split among riders
      final totalFare = _calculateTotalFare(riders);
      final riderFares = _splitFareAmongRiders(riders, totalFare);

      // Create optimized route with stops
      final stops = _createOptimizedStops(riders);

      final carpoolRide = CarpoolRideModel(
        id: _firestore.collection('carpool_rides').doc().id,
        driverId: driverId,
        riders: riders,
        stops: stops,
        maxSeats: maxSeats,
        availableSeats: maxSeats - riders.length,
        totalFare: totalFare,
        riderFares: riderFares,
        status: CarpoolStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('carpool_rides')
          .doc(carpoolRide.id)
          .set(carpoolRide.toMap());

      return carpoolRide;
    } catch (e) {
      throw Exception('Failed to create carpool ride: $e');
    }
  }

  // Join an existing carpool ride
  Future<bool> joinCarpoolRide({
    required String carpoolRideId,
    required CarpoolRider newRider,
  }) async {
    try {
      final carpoolDoc = await _firestore
          .collection('carpool_rides')
          .doc(carpoolRideId)
          .get();

      if (!carpoolDoc.exists) {
        throw Exception('Carpool ride not found');
      }

      final carpoolRide = CarpoolRideModel.fromMap(carpoolDoc.data()!);

      // Check if there are available seats
      if (carpoolRide.availableSeats <= 0) {
        throw Exception('No available seats in this carpool');
      }

      // Add new rider
      final updatedRiders = List<CarpoolRider>.from(carpoolRide.riders);
      updatedRiders.add(newRider);

      // Recalculate fares
      final totalFare = _calculateTotalFare(updatedRiders);
      final riderFares = _splitFareAmongRiders(updatedRiders, totalFare);

      // Update stops
      final updatedStops = _createOptimizedStops(updatedRiders);

      // Update carpool ride
      await _firestore.collection('carpool_rides').doc(carpoolRideId).update({
        'riders': updatedRiders.map((rider) => rider.toMap()).toList(),
        'stops': updatedStops.map((stop) => stop.toMap()).toList(),
        'availableSeats': carpoolRide.maxSeats - updatedRiders.length,
        'totalFare': totalFare,
        'riderFares': riderFares,
      });

      return true;
    } catch (e) {
      throw Exception('Failed to join carpool ride: $e');
    }
  }

  // Find available carpool rides near a location
  Future<List<CarpoolRideModel>> findAvailableCarpoolRides({
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
    double radiusInKm = 2.0,
  }) async {
    try {
      // Use a simpler query to avoid index issues
      final querySnapshot = await _firestore
          .collection('carpool_rides')
          .where('status', isEqualTo: 'pending')
          .get();

      final List<CarpoolRideModel> availableRides = [];

      for (final doc in querySnapshot.docs) {
        final carpoolRide = CarpoolRideModel.fromMap(doc.data());

        // Check if there are available seats and ride is still active
        if (carpoolRide.availableSeats <= 0 ||
            carpoolRide.status != CarpoolStatus.pending ||
            carpoolRide.completedAt != null)
          continue;

        // Check if pickup and dropoff are within reasonable distance
        final isPickupNearby = _isLocationNearby(
          pickupLatitude,
          pickupLongitude,
          carpoolRide.stops,
          radiusInKm,
        );

        final isDropoffNearby = _isLocationNearby(
          dropoffLatitude,
          dropoffLongitude,
          carpoolRide.stops,
          radiusInKm,
        );

        if (isPickupNearby && isDropoffNearby) {
          availableRides.add(carpoolRide);
        }
      }

      // Sort by creation date (newest first)
      availableRides.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return availableRides;
    } catch (e) {
      debugPrint('Failed to find available carpool rides: $e');
      // Return empty list instead of throwing error
      return [];
    }
  }

  // Get carpool ride by ID
  Future<CarpoolRideModel?> getCarpoolRideById(String carpoolRideId) async {
    try {
      final doc = await _firestore
          .collection('carpool_rides')
          .doc(carpoolRideId)
          .get();

      if (doc.exists) {
        return CarpoolRideModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get carpool ride: $e');
    }
  }

  // Update carpool ride status
  Future<void> updateCarpoolRideStatus({
    required String carpoolRideId,
    required CarpoolStatus status,
  }) async {
    try {
      final updateData = <String, dynamic>{'status': status.name};

      switch (status) {
        case CarpoolStatus.inProgress:
          updateData['startedAt'] = DateTime.now();
          break;
        case CarpoolStatus.completed:
          updateData['completedAt'] = DateTime.now();
          break;
        default:
          break;
      }

      await _firestore
          .collection('carpool_rides')
          .doc(carpoolRideId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update carpool ride status: $e');
    }
  }

  // Update rider status in carpool
  Future<void> updateRiderStatus({
    required String carpoolRideId,
    required String riderId,
    required CarpoolRiderStatus status,
  }) async {
    try {
      final carpoolRide = await getCarpoolRideById(carpoolRideId);
      if (carpoolRide == null) {
        throw Exception('Carpool ride not found');
      }

      final updatedRiders = carpoolRide.riders.map((rider) {
        if (rider.riderId == riderId) {
          return CarpoolRider(
            riderId: rider.riderId,
            riderName: rider.riderName,
            pickupAddress: rider.pickupAddress,
            dropoffAddress: rider.dropoffAddress,
            pickupLatitude: rider.pickupLatitude,
            pickupLongitude: rider.pickupLongitude,
            dropoffLatitude: rider.dropoffLatitude,
            dropoffLongitude: rider.dropoffLongitude,
            fare: rider.fare,
            status: status,
            joinedAt: rider.joinedAt,
          );
        }
        return rider;
      }).toList();

      await _firestore.collection('carpool_rides').doc(carpoolRideId).update({
        'riders': updatedRiders.map((rider) => rider.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to update rider status: $e');
    }
  }

  // Calculate total fare for all riders
  double _calculateTotalFare(List<CarpoolRider> riders) {
    double totalFare = 0.0;

    for (final rider in riders) {
      // Calculate distance for this rider
      final distance = _calculateDistance(
        rider.pickupLatitude,
        rider.pickupLongitude,
        rider.dropoffLatitude,
        rider.dropoffLongitude,
      );

      // Calculate individual fare using fare calculator
      final individualFare = FareCalculator.calculateEstimatedFareFromRideModel(
        distance,
        RideType.carpool,
      );
      totalFare += individualFare;
    }

    // Apply carpool discount (20% off total)
    return totalFare * 0.8;
  }

  // Split fare among riders based on distance and complexity
  Map<String, double> _splitFareAmongRiders(
    List<CarpoolRider> riders,
    double totalFare,
  ) {
    final Map<String, double> riderFares = {};

    if (riders.isEmpty) return riderFares;

    // Calculate individual distances
    final List<double> distances = riders.map((rider) {
      return _calculateDistance(
        rider.pickupLatitude,
        rider.pickupLongitude,
        rider.dropoffLatitude,
        rider.dropoffLongitude,
      );
    }).toList();

    final totalDistance = distances.reduce((a, b) => a + b);

    // Split fare proportionally based on distance
    for (int i = 0; i < riders.length; i++) {
      final rider = riders[i];
      final distance = distances[i];
      final fareShare = (distance / totalDistance) * totalFare;
      riderFares[rider.riderId] = double.parse(fareShare.toStringAsFixed(2));
    }

    return riderFares;
  }

  // Create optimized stops for the carpool route
  List<CarpoolStop> _createOptimizedStops(List<CarpoolRider> riders) {
    final List<CarpoolStop> stops = [];
    int order = 0;

    // Add pickup stops
    for (final rider in riders) {
      stops.add(
        CarpoolStop(
          id: 'pickup_${rider.riderId}',
          address: rider.pickupAddress,
          latitude: rider.pickupLatitude,
          longitude: rider.pickupLongitude,
          type: StopType.pickup,
          riderIds: [rider.riderId],
          order: order++,
        ),
      );
    }

    // Add dropoff stops
    for (final rider in riders) {
      stops.add(
        CarpoolStop(
          id: 'dropoff_${rider.riderId}',
          address: rider.dropoffAddress,
          latitude: rider.dropoffLatitude,
          longitude: rider.dropoffLongitude,
          type: StopType.dropoff,
          riderIds: [rider.riderId],
          order: order++,
        ),
      );
    }

    // Sort stops by order for optimized route
    stops.sort((a, b) => a.order.compareTo(b.order));

    return stops;
  }

  // Check if a location is nearby any of the carpool stops
  bool _isLocationNearby(
    double latitude,
    double longitude,
    List<CarpoolStop> stops,
    double radiusInKm,
  ) {
    for (final stop in stops) {
      final distance = _calculateDistance(
        latitude,
        longitude,
        stop.latitude,
        stop.longitude,
      );

      if (distance <= radiusInKm) {
        return true;
      }
    }
    return false;
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

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Get carpool rides for a specific driver
  Future<List<CarpoolRideModel>> getDriverCarpoolRides(String driverId) async {
    try {
      final querySnapshot = await _firestore
          .collection('carpool_rides')
          .where('driverId', isEqualTo: driverId)
          .get();

      final rides = querySnapshot.docs
          .map((doc) => CarpoolRideModel.fromMap(doc.data()))
          .toList();

      // Sort by creation date (newest first)
      rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return rides;
    } catch (e) {
      debugPrint('Failed to get driver carpool rides: $e');
      return []; // Return empty list instead of throwing error
    }
  }

  // Get carpool rides for a specific rider
  Future<List<CarpoolRideModel>> getRiderCarpoolRides(String riderId) async {
    try {
      final querySnapshot = await _firestore.collection('carpool_rides').get();

      final rides = querySnapshot.docs
          .map((doc) => CarpoolRideModel.fromMap(doc.data()))
          .where(
            (carpoolRide) =>
                carpoolRide.riders.any((rider) => rider.riderId == riderId),
          )
          .toList();

      // Sort by creation date (newest first)
      rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return rides;
    } catch (e) {
      debugPrint('Failed to get rider carpool rides: $e');
      return []; // Return empty list instead of throwing error
    }
  }

  // Stream of carpool ride updates
  Stream<CarpoolRideModel> getCarpoolRideStream(String carpoolRideId) {
    return _firestore
        .collection('carpool_rides')
        .doc(carpoolRideId)
        .snapshots()
        .map((doc) => CarpoolRideModel.fromMap(doc.data()!));
  }

  // Get carpool requests for a specific carpool
  Future<List<CarpoolRequestModel>> getCarpoolRequests(
    String carpoolRideId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('carpool_requests')
          .where('carpoolRideId', isEqualTo: carpoolRideId)
          .get();

      final requests = <CarpoolRequestModel>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          requests.add(CarpoolRequestModel.fromMap(data));
        } catch (e) {
          debugPrint('Error parsing carpool request ${doc.id}: $e');
        }
      }

      // Sort by creation time (newest first)
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    } catch (e) {
      debugPrint('❌ Failed to get carpool requests: $e');
      return [];
    }
  }

  // Get user's carpool requests
  Future<List<CarpoolRequestModel>> getUserCarpoolRequests(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('carpool_requests')
          .where('requesterId', isEqualTo: userId)
          .get();

      final requests = <CarpoolRequestModel>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          requests.add(CarpoolRequestModel.fromMap(data));
        } catch (e) {
          debugPrint('Error parsing user carpool request ${doc.id}: $e');
        }
      }

      // Sort by creation time (newest first)
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    } catch (e) {
      debugPrint('❌ Failed to get user carpool requests: $e');
      return [];
    }
  }

  // Get driver's carpool requests (for all their carpools)
  Future<List<CarpoolRequestModel>> getDriverCarpoolRequests(
    String driverId,
  ) async {
    try {
      // First get all carpool rides for this driver
      final carpoolSnapshot = await _firestore
          .collection('carpool_rides')
          .where('driverId', isEqualTo: driverId)
          .get();

      if (carpoolSnapshot.docs.isEmpty) {
        return [];
      }

      final carpoolIds = carpoolSnapshot.docs.map((doc) => doc.id).toList();

      // Get all requests for these carpools
      final querySnapshot = await _firestore
          .collection('carpool_requests')
          .get();

      final requests = <CarpoolRequestModel>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          if (carpoolIds.contains(data['carpoolRideId'])) {
            data['id'] = doc.id;
            requests.add(CarpoolRequestModel.fromMap(data));
          }
        } catch (e) {
          debugPrint('Error parsing driver carpool request ${doc.id}: $e');
        }
      }

      // Sort by creation time (newest first)
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    } catch (e) {
      debugPrint('❌ Failed to get driver carpool requests: $e');
      return [];
    }
  }
}
