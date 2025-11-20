import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/carpool_ride_model.dart';
import '../models/carpool_request_model.dart';

class CarpoolRequestFlowService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  static const String _carpoolRidesCollection = 'carpool_rides';
  static const String _carpoolRequestsCollection = 'carpool_requests';

  /// Create a new carpool ride (Driver creates carpool)
  static Future<String?> createCarpoolRide({
    required String pickupAddress,
    required String dropoffAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required DateTime departureTime,
    required int maxSeats,
    required double farePerPerson,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user found');
        return null;
      }

      final carpoolData = {
        'driverId': user.uid,
        'driverName': user.displayName ?? 'Driver',
        'driverPhone': user.phoneNumber ?? '',
        'pickupAddress': pickupAddress,
        'dropoffAddress': dropoffAddress,
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'dropoffLatitude': dropoffLatitude,
        'dropoffLongitude': dropoffLongitude,
        'departureTime': Timestamp.fromDate(departureTime),
        'maxSeats': maxSeats,
        'availableSeats': maxSeats,
        'farePerPerson': farePerPerson,
        'status': CarpoolStatus.pending.name,
        'riders': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection(_carpoolRidesCollection)
          .add(carpoolData);

      debugPrint('✅ Carpool ride created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating carpool ride: $e');
      rethrow;
    }
  }

  /// Stream of available carpool rides for riders to browse
  static Stream<List<CarpoolRideModel>> streamAvailableCarpoolRides() {
    try {
      return _firestore
          .collection(_carpoolRidesCollection)
          .where('status', isEqualTo: CarpoolStatus.pending.name)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return CarpoolRideModel.fromMap(data);
            }).toList();
          })
          .handleError((error) {
            debugPrint('❌ Stream error for available carpool rides: $error');
            return <CarpoolRideModel>[];
          });
    } catch (e) {
      debugPrint('❌ Error creating available carpool rides stream: $e');
      return Stream.value(<CarpoolRideModel>[]);
    }
  }

  /// Stream of driver's carpool rides
  static Stream<List<CarpoolRideModel>> streamDriverCarpoolRides(
    String driverId,
  ) {
    try {
      return _firestore
          .collection(_carpoolRidesCollection)
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return CarpoolRideModel.fromMap(data);
            }).toList();
          })
          .handleError((error) {
            debugPrint('❌ Stream error for driver carpool rides: $error');
            return <CarpoolRideModel>[];
          });
    } catch (e) {
      debugPrint('❌ Error creating driver carpool rides stream: $e');
      return Stream.value(<CarpoolRideModel>[]);
    }
  }

  /// Rider requests to join a carpool
  static Future<String?> requestToJoinCarpool({
    required String carpoolRideId,
    required String pickupAddress,
    required String dropoffAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required double estimatedFare,
    String? message,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user found');
        return null;
      }

      // Check if carpool still has available seats
      final carpoolDoc = await _firestore
          .collection(_carpoolRidesCollection)
          .doc(carpoolRideId)
          .get();

      if (!carpoolDoc.exists) {
        debugPrint('❌ Carpool ride not found');
        return null;
      }

      final carpoolData = carpoolDoc.data()!;
      final availableSeats = carpoolData['availableSeats'] as int;

      if (availableSeats <= 0) {
        debugPrint('❌ No available seats in this carpool');
        return null;
      }

      // Create carpool request
      final requestData = {
        'carpoolRideId': carpoolRideId,
        'requesterId': user.uid,
        'requesterName': user.displayName ?? 'Rider',
        'requesterPhone': user.phoneNumber ?? '',
        'pickupAddress': pickupAddress,
        'dropoffAddress': dropoffAddress,
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'dropoffLatitude': dropoffLatitude,
        'dropoffLongitude': dropoffLongitude,
        'estimatedFare': estimatedFare,
        'status': CarpoolRequestStatus.pending.name,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
        'responseMessage': null,
      };

      final docRef = await _firestore
          .collection(_carpoolRequestsCollection)
          .add(requestData);

      debugPrint('✅ Carpool join request created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating carpool join request: $e');
      rethrow;
    }
  }

  /// Stream of carpool requests for a specific carpool (Driver view)
  static Stream<List<CarpoolRequestModel>> streamCarpoolRequests(
    String carpoolRideId,
  ) {
    try {
      return _firestore
          .collection(_carpoolRequestsCollection)
          .where('carpoolRideId', isEqualTo: carpoolRideId)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return CarpoolRequestModel.fromMap(data);
            }).toList();
          })
          .handleError((error) {
            debugPrint('❌ Stream error for carpool requests: $error');
            return <CarpoolRequestModel>[];
          });
    } catch (e) {
      debugPrint('❌ Error creating carpool requests stream: $e');
      return Stream.value(<CarpoolRequestModel>[]);
    }
  }

  /// Stream of all carpool requests for a driver (across all their carpools)
  static Stream<List<CarpoolRequestModel>> streamDriverCarpoolRequests(
    String driverId,
  ) {
    try {
      return _firestore
          .collection(_carpoolRequestsCollection)
          .snapshots()
          .map((snapshot) async {
            // Get all carpool rides for this driver
            final carpoolSnapshot = await _firestore
                .collection(_carpoolRidesCollection)
                .where('driverId', isEqualTo: driverId)
                .get();

            final carpoolIds = carpoolSnapshot.docs
                .map((doc) => doc.id)
                .toList();

            // Filter requests for this driver's carpools
            final requests = <CarpoolRequestModel>[];
            for (final doc in snapshot.docs) {
              final data = doc.data();
              if (carpoolIds.contains(data['carpoolRideId'])) {
                data['id'] = doc.id;
                requests.add(CarpoolRequestModel.fromMap(data));
              }
            }

            // Sort by creation time (newest first)
            requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return requests;
          })
          .asyncMap((future) => future)
          .handleError((error) {
            debugPrint('❌ Stream error for driver carpool requests: $error');
            return <CarpoolRequestModel>[];
          });
    } catch (e) {
      debugPrint('❌ Error creating driver carpool requests stream: $e');
      return Stream.value(<CarpoolRequestModel>[]);
    }
  }

  /// Driver approves a carpool request
  static Future<bool> approveCarpoolRequest(String requestId) async {
    try {
      // Use transaction to ensure atomic update
      return await _firestore.runTransaction<bool>((transaction) async {
        // Get the request
        final requestRef = _firestore
            .collection(_carpoolRequestsCollection)
            .doc(requestId);
        final requestDoc = await transaction.get(requestRef);

        if (!requestDoc.exists) {
          debugPrint('❌ Carpool request not found');
          return false;
        }

        final requestData = requestDoc.data()!;
        final carpoolRideId = requestData['carpoolRideId'] as String;
        final requesterId = requestData['requesterId'] as String;

        // Get the carpool ride
        final carpoolRef = _firestore
            .collection(_carpoolRidesCollection)
            .doc(carpoolRideId);
        final carpoolDoc = await transaction.get(carpoolRef);

        if (!carpoolDoc.exists) {
          debugPrint('❌ Carpool ride not found');
          return false;
        }

        final carpoolData = carpoolDoc.data()!;
        final availableSeats = carpoolData['availableSeats'] as int;

        if (availableSeats <= 0) {
          debugPrint('❌ No available seats in carpool');
          return false;
        }

        // Update request status
        transaction.update(requestRef, {
          'status': CarpoolRequestStatus.approved.name,
          'respondedAt': FieldValue.serverTimestamp(),
          'responseMessage': 'Request approved',
        });

        // Add rider to carpool and update available seats
        final riders = List<String>.from(carpoolData['riders'] ?? []);
        riders.add(requesterId);

        transaction.update(carpoolRef, {
          'riders': riders,
          'availableSeats': availableSeats - 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      debugPrint('❌ Error approving carpool request: $e');
      return false;
    }
  }

  /// Driver rejects a carpool request
  static Future<bool> rejectCarpoolRequest(
    String requestId, {
    String? reason,
  }) async {
    try {
      await _firestore
          .collection(_carpoolRequestsCollection)
          .doc(requestId)
          .update({
            'status': CarpoolRequestStatus.rejected.name,
            'respondedAt': FieldValue.serverTimestamp(),
            'responseMessage': reason ?? 'Request rejected',
          });

      debugPrint('✅ Carpool request rejected successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error rejecting carpool request: $e');
      return false;
    }
  }

  /// Rider cancels their carpool request
  static Future<bool> cancelCarpoolRequest(String requestId) async {
    try {
      await _firestore
          .collection(_carpoolRequestsCollection)
          .doc(requestId)
          .update({
            'status': CarpoolRequestStatus.cancelled.name,
            'respondedAt': FieldValue.serverTimestamp(),
            'responseMessage': 'Request cancelled by rider',
          });

      debugPrint('✅ Carpool request cancelled successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error cancelling carpool request: $e');
      return false;
    }
  }

  /// Get user's carpool requests
  static Future<List<CarpoolRequestModel>> getUserCarpoolRequests(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_carpoolRequestsCollection)
          .where('requesterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final requests = <CarpoolRequestModel>[];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        requests.add(CarpoolRequestModel.fromMap(data));
      }

      return requests;
    } catch (e) {
      debugPrint('❌ Failed to get user carpool requests: $e');
      return [];
    }
  }

  /// Stream of user's carpool requests
  static Stream<List<CarpoolRequestModel>> streamUserCarpoolRequests(
    String userId,
  ) {
    try {
      return _firestore
          .collection(_carpoolRequestsCollection)
          .where('requesterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return CarpoolRequestModel.fromMap(data);
            }).toList();
          })
          .handleError((error) {
            debugPrint('❌ Stream error for user carpool requests: $error');
            return <CarpoolRequestModel>[];
          });
    } catch (e) {
      debugPrint('❌ Error creating user carpool requests stream: $e');
      return Stream.value(<CarpoolRequestModel>[]);
    }
  }
}
