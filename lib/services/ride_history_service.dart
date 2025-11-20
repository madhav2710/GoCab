import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ride_model.dart';
import '../models/ride_request_model.dart';

class RideHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get ride history for a user
  Future<List<RideModel>> getRideHistory(
    String userId, {
    int limit = 20,
  }) async {
    try {
      // Use ride_requests collection (where our app actually stores rides)
      final querySnapshot = await _firestore
          .collection('ride_requests')
          .where('riderId', isEqualTo: userId)
          .get();

      final rides = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return RideModel.fromMap(data);
      }).toList();

      // Filter and sort in application code
      final filteredRides = rides
          .where(
            (ride) =>
                ride.status == RideStatus.completed ||
                ride.status == RideStatus.cancelled,
          )
          .toList();

      // Sort by creation date (newest first)
      filteredRides.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply limit
      return filteredRides.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting ride history: $e');
      return [];
    }
  }

  // Get recent rides (last 5)
  Future<List<RideModel>> getRecentRides(String userId) async {
    return getRideHistory(userId, limit: 5);
  }

  // Get ride history using RideRequestModel (for ride_requests collection)
  Future<List<RideRequestModel>> getRideRequestHistory(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('ride_requests')
          .where('riderId', isEqualTo: userId)
          .get();

      final rides = querySnapshot.docs.map((doc) {
        return RideRequestModel.fromMap(doc.data(), doc.id);
      }).toList();

      // Filter and sort in application code
      final filteredRides = rides
          .where(
            (ride) =>
                ride.status == RideRequestStatus.completed ||
                ride.status == RideRequestStatus.cancelled,
          )
          .toList();

      // Sort by creation date (newest first)
      filteredRides.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply limit
      return filteredRides.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting ride request history: $e');
      return [];
    }
  }

  // Get recent ride requests (last 5)
  Future<List<RideRequestModel>> getRecentRideRequests(String userId) async {
    return getRideRequestHistory(userId, limit: 5);
  }

  // Get ride statistics
  Future<Map<String, dynamic>> getRideStatistics(String userId) async {
    try {
      final rides = await getRideHistory(userId, limit: 100);

      int totalRides = rides.length;
      int completedRides = rides
          .where((ride) => ride.status == RideStatus.completed)
          .length;
      int cancelledRides = rides
          .where((ride) => ride.status == RideStatus.cancelled)
          .length;
      double totalSpent = rides
          .where((ride) => ride.status == RideStatus.completed)
          .fold(
            0.0,
            (sum, ride) => sum + (ride.actualFare ?? ride.estimatedFare),
          );

      return {
        'totalRides': totalRides,
        'completedRides': completedRides,
        'cancelledRides': cancelledRides,
        'totalSpent': totalSpent,
        'averageFare': totalRides > 0 ? totalSpent / completedRides : 0.0,
      };
    } catch (e) {
      debugPrint('Error getting ride statistics: $e');
      return {
        'totalRides': 0,
        'completedRides': 0,
        'cancelledRides': 0,
        'totalSpent': 0.0,
        'averageFare': 0.0,
      };
    }
  }

  // Stream ride history updates
  Stream<List<RideModel>> streamRideHistory(String userId, {int limit = 20}) {
    try {
      return _firestore
          .collection('ride_requests')
          .where('riderId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final rides = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return RideModel.fromMap(data);
            }).toList();

            // Filter and sort in application code
            final filteredRides = rides
                .where(
                  (ride) =>
                      ride.status == RideStatus.completed ||
                      ride.status == RideStatus.cancelled,
                )
                .toList();

            // Sort by creation date (newest first)
            filteredRides.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            // Apply limit
            return filteredRides.take(limit).toList();
          })
          .handleError((error) {
            debugPrint('Stream query failed: $error');
            return <RideModel>[];
          });
    } catch (e) {
      debugPrint('Error creating stream: $e');
      return Stream.value(<RideModel>[]);
    }
  }
}
