import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_model.dart';

class RideHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get ride history for a user
  Future<List<RideModel>> getRideHistory(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('rides')
          .where('riderId', isEqualTo: userId)
          .where('status', whereIn: ['completed', 'cancelled'])
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return RideModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error getting ride history: $e');
      // Fallback: simple query without orderBy
      try {
        final querySnapshot = await _firestore
            .collection('rides')
            .where('riderId', isEqualTo: userId)
            .where('status', whereIn: ['completed', 'cancelled'])
            .limit(limit)
            .get();

        final rides = querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return RideModel.fromMap(data);
        }).toList();

        // Sort manually
        rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return rides;
      } catch (fallbackError) {
        print('Fallback query also failed: $fallbackError');
        return [];
      }
    }
  }

  // Get recent rides (last 5)
  Future<List<RideModel>> getRecentRides(String userId) async {
    return getRideHistory(userId, limit: 5);
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
      print('Error getting ride statistics: $e');
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
          .collection('rides')
          .where('riderId', isEqualTo: userId)
          .where('status', whereIn: ['completed', 'cancelled'])
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return RideModel.fromMap(data);
            }).toList();
          })
          .handleError((error) {
            print('Stream query failed: $error');
            return <RideModel>[];
          });
    } catch (e) {
      print('Error creating stream: $e');
      return Stream.value(<RideModel>[]);
    }
  }
}
