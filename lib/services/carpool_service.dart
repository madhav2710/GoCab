import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/carpool_ride_model.dart';
import '../models/ride_model.dart';
import 'ride_service.dart';

class CarpoolService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RideService _rideService = RideService();

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
      final querySnapshot = await _firestore
          .collection('carpool_rides')
          .where('status', isEqualTo: 'pending')
          .where('availableSeats', isGreaterThan: 0)
          .get();

      final List<CarpoolRideModel> availableRides = [];

      for (final doc in querySnapshot.docs) {
        final carpoolRide = CarpoolRideModel.fromMap(doc.data());
        
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

      return availableRides;
    } catch (e) {
      throw Exception('Failed to find available carpool rides: $e');
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
      final updateData = <String, dynamic>{
        'status': status.name,
      };

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

      await _firestore
          .collection('carpool_rides')
          .doc(carpoolRideId)
          .update({
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

      // Calculate individual fare using existing ride service logic
      final individualFare = _rideService.calculateEstimatedFare(
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
      stops.add(CarpoolStop(
        id: 'pickup_${rider.riderId}',
        address: rider.pickupAddress,
        latitude: rider.pickupLatitude,
        longitude: rider.pickupLongitude,
        type: StopType.pickup,
        riderIds: [rider.riderId],
        order: order++,
      ));
    }

    // Add dropoff stops
    for (final rider in riders) {
      stops.add(CarpoolStop(
        id: 'dropoff_${rider.riderId}',
        address: rider.dropoffAddress,
        latitude: rider.dropoffLatitude,
        longitude: rider.dropoffLongitude,
        type: StopType.dropoff,
        riderIds: [rider.riderId],
        order: order++,
      ));
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

    final double a = sin(dLat / 2) * sin(dLat / 2) +
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
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CarpoolRideModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get driver carpool rides: $e');
    }
  }

  // Get carpool rides for a specific rider
  Future<List<CarpoolRideModel>> getRiderCarpoolRides(String riderId) async {
    try {
      final querySnapshot = await _firestore
          .collection('carpool_rides')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CarpoolRideModel.fromMap(doc.data()))
          .where((carpoolRide) => 
              carpoolRide.riders.any((rider) => rider.riderId == riderId))
          .toList();
    } catch (e) {
      throw Exception('Failed to get rider carpool rides: $e');
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
}
