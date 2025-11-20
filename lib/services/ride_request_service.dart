import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/ride_request_model.dart';

class RideRequestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  static const String _rideRequestsCollection = 'ride_requests';

  /// Creates a new ride request by a rider
  static Future<String?> createRideRequest({
    required String pickupAddress,
    required String dropoffAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required double estimatedFare,
    required RideType rideType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user found');
        return null;
      }

      final rideRequestData = {
        'riderId': user.uid,
        'riderName': user.displayName ?? 'Unknown Rider',
        'riderPhone': user.phoneNumber ?? '',
        'pickupAddress': pickupAddress,
        'dropoffAddress': dropoffAddress,
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'dropoffLatitude': dropoffLatitude,
        'dropoffLongitude': dropoffLongitude,
        'estimatedFare': estimatedFare,
        'actualFare': estimatedFare, // Initially same as estimated
        'rideType': rideType.name,
        'status': RideRequestStatus.pending.name,
        'driverId': null,
        'driverName': null,
        'driverPhone': null,
        'vehicleNumber': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'acceptedAt': null,
        'startedAt': null,
        'completedAt': null,
        'cancelledAt': null,
        'cancellationReason': null,
        'paymentMethod': 'cash', // Default payment method
        'paymentStatus': 'pending',
        'notes': '',
      };

      final docRef = await _firestore
          .collection(_rideRequestsCollection)
          .add(rideRequestData);

      debugPrint('✅ Ride request created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating ride request: $e');
      rethrow;
    }
  }

  /// Stream of pending ride requests for drivers
  static Stream<List<RideRequestModel>> streamPendingRideRequests() {
    try {
      return _firestore
          .collection(_rideRequestsCollection)
          .where('status', isEqualTo: RideRequestStatus.pending.name)
          .snapshots()
          .map((snapshot) {
            final rides = snapshot.docs
                .map((doc) => RideRequestModel.fromMap(doc.data(), doc.id))
                .toList();

            // Sort by creation date in application code to avoid index requirement
            rides.sort((a, b) => a.createdAt.compareTo(b.createdAt));

            debugPrint(
              '📋 Pending ride requests stream updated: ${rides.length} requests',
            );
            for (final ride in rides) {
              debugPrint(
                '   - ${ride.id}: ${ride.pickupAddress} → ${ride.dropoffAddress}',
              );
            }

            return rides;
          })
          .handleError((error) {
            debugPrint('❌ Stream error for pending ride requests: $error');
            return <RideRequestModel>[];
          });
    } catch (e) {
      debugPrint('❌ Error creating pending ride requests stream: $e');
      return Stream.value(<RideRequestModel>[]);
    }
  }

  /// Stream of pending ride requests for a specific driver (excluding declined ones)
  static Stream<List<RideRequestModel>> streamPendingRideRequestsForDriver(
    String driverId,
  ) {
    try {
      return _firestore
          .collection(_rideRequestsCollection)
          .where('status', isEqualTo: RideRequestStatus.pending.name)
          .snapshots()
          .map((snapshot) {
            final rides = snapshot.docs
                .map((doc) {
                  final data = doc.data();
                  return RideRequestModel.fromMap(data, doc.id);
                })
                .where((ride) {
                  // Filter out rides that this driver has already declined
                  // Note: This filtering happens in the app since Firestore doesn't support
                  // complex queries on array fields easily
                  return true; // We'll filter in the provider
                })
                .toList();

            // Sort by creation date in application code to avoid index requirement
            rides.sort((a, b) => a.createdAt.compareTo(b.createdAt));

            debugPrint(
              '📋 Pending ride requests for driver $driverId: ${rides.length} requests',
            );

            return rides;
          })
          .handleError((error) {
            debugPrint('❌ Stream error for pending ride requests: $error');
            return <RideRequestModel>[];
          });
    } catch (e) {
      debugPrint('❌ Error creating pending ride requests stream: $e');
      return Stream.value(<RideRequestModel>[]);
    }
  }

  /// Stream of ride requests for a specific rider
  static Stream<List<RideRequestModel>> streamRiderRideRequests(
    String riderId,
  ) {
    try {
      return _firestore
          .collection(_rideRequestsCollection)
          .where('riderId', isEqualTo: riderId)
          .snapshots()
          .map((snapshot) {
            final rides = snapshot.docs
                .map((doc) => RideRequestModel.fromMap(doc.data(), doc.id))
                .toList();

            // Sort by creation date in application code to avoid index requirement
            rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            // Limit to 10 most recent rides
            return rides.take(10).toList();
          })
          .handleError((error) {
            debugPrint('❌ Stream error for rider ride requests: $error');
            return <RideRequestModel>[];
          });
    } catch (e) {
      debugPrint('❌ Error creating rider ride requests stream: $e');
      return Stream.value(<RideRequestModel>[]);
    }
  }

  /// Stream of ride requests for a specific driver
  static Stream<List<RideRequestModel>> streamDriverRideRequests(
    String driverId,
  ) {
    try {
      return _firestore
          .collection(_rideRequestsCollection)
          .where('driverId', isEqualTo: driverId)
          .snapshots()
          .map((snapshot) {
            final rides = snapshot.docs
                .map((doc) => RideRequestModel.fromMap(doc.data(), doc.id))
                .toList();

            // Sort by creation date in application code to avoid index requirement
            rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            // Limit to 10 most recent rides
            return rides.take(10).toList();
          })
          .handleError((error) {
            debugPrint('❌ Stream error for driver ride requests: $error');
            return <RideRequestModel>[];
          });
    } catch (e) {
      debugPrint('❌ Error creating driver ride requests stream: $e');
      return Stream.value(<RideRequestModel>[]);
    }
  }

  /// Stream of a specific ride request by ID
  static Stream<RideRequestModel?> streamRideRequest(String rideId) {
    try {
      return _firestore
          .collection(_rideRequestsCollection)
          .doc(rideId)
          .snapshots()
          .map((snapshot) {
            if (snapshot.exists) {
              final ride = RideRequestModel.fromMap(
                snapshot.data()!,
                snapshot.id,
              );
              debugPrint(
                '🔄 Ride stream update: ${ride.id} - Status: ${ride.status.name}',
              );
              return ride;
            }
            debugPrint('🔄 Ride stream: Document $rideId does not exist');
            return null;
          })
          .handleError((error) {
            debugPrint('❌ Stream error for ride request $rideId: $error');
            return null;
          });
    } catch (e) {
      debugPrint('❌ Error creating ride request stream: $e');
      return Stream.value(null);
    }
  }

  /// Driver accepts a ride request
  static Future<bool> acceptRideRequest({
    required String rideId,
    required String driverId,
    required String driverName,
    required String driverPhone,
    required String vehicleNumber,
  }) async {
    try {
      final rideRef = _firestore
          .collection(_rideRequestsCollection)
          .doc(rideId);

      // Use transaction to ensure atomic update
      return await _firestore.runTransaction<bool>((transaction) async {
        final rideDoc = await transaction.get(rideRef);

        if (!rideDoc.exists) {
          debugPrint('❌ Ride request $rideId does not exist');
          return false;
        }

        final rideData = rideDoc.data()!;
        debugPrint('📄 Ride data: $rideData');

        final currentStatus = rideData['status'] as String?;
        debugPrint('📊 Current status: $currentStatus');
        debugPrint('📊 Expected status: ${RideRequestStatus.pending.name}');

        // Check if ride is still pending
        if (currentStatus != RideRequestStatus.pending.name) {
          debugPrint(
            '❌ Ride request $rideId is no longer pending (status: $currentStatus)',
          );
          return false;
        }

        // Update the ride request
        transaction.update(rideRef, {
          'status': RideRequestStatus.accepted.name,
          'driverId': driverId,
          'driverName': driverName,
          'driverPhone': driverPhone,
          'vehicleNumber': vehicleNumber,
          'acceptedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      debugPrint('❌ Error accepting ride request: $e');
      return false;
    }
  }

  /// Update ride request status
  static Future<bool> updateRideRequestStatus({
    required String rideId,
    required RideRequestStatus status,
    String? cancellationReason,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add timestamp based on status
      switch (status) {
        case RideRequestStatus.inProgress:
          updateData['startedAt'] = FieldValue.serverTimestamp();
          break;
        case RideRequestStatus.completed:
          updateData['completedAt'] = FieldValue.serverTimestamp();
          break;
        case RideRequestStatus.cancelled:
          updateData['cancelledAt'] = FieldValue.serverTimestamp();
          if (cancellationReason != null) {
            updateData['cancellationReason'] = cancellationReason;
          }
          break;
        default:
          break;
      }

      await _firestore
          .collection(_rideRequestsCollection)
          .doc(rideId)
          .update(updateData);

      debugPrint('✅ Ride request $rideId status updated to ${status.name}');
      debugPrint('📝 Update data: $updateData');

      // If this is a carpool ride request, also update the carpool ride status
      if (status == RideRequestStatus.completed) {
        final rideDoc = await _firestore
            .collection(_rideRequestsCollection)
            .doc(rideId)
            .get();

        if (rideDoc.exists) {
          final rideData = rideDoc.data()!;
          final carpoolRideId = rideData['carpoolRideId'] as String?;

          if (carpoolRideId != null) {
            // Update carpool ride status to completed
            await _firestore
                .collection('carpool_rides')
                .doc(carpoolRideId)
                .update({
                  'status': 'completed',
                  'completedAt': FieldValue.serverTimestamp(),
                });
            debugPrint(
              '✅ Carpool ride $carpoolRideId status updated to completed',
            );
          }
        }
      }

      debugPrint('✅ Ride request $rideId status updated to ${status.name}');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating ride request status: $e');
      return false;
    }
  }

  /// Decline a ride request (for drivers)
  static Future<bool> declineRideRequest({
    required String rideId,
    required String driverId,
    String? declineReason,
  }) async {
    try {
      final rideRef = _firestore
          .collection(_rideRequestsCollection)
          .doc(rideId);

      // Use transaction to ensure atomic update
      return await _firestore.runTransaction<bool>((transaction) async {
        final rideDoc = await transaction.get(rideRef);

        if (!rideDoc.exists) {
          debugPrint('❌ Ride request $rideId does not exist');
          return false;
        }

        final rideData = rideDoc.data()!;
        final currentStatus = rideData['status'] as String?;

        // Check if ride is still pending
        if (currentStatus != RideRequestStatus.pending.name) {
          debugPrint(
            '❌ Ride request $rideId is no longer pending (status: $currentStatus)',
          );
          return false;
        }

        // Add driver to declined drivers list to prevent showing it again
        final declinedDrivers = List<String>.from(
          rideData['declinedDrivers'] ?? [],
        );
        if (!declinedDrivers.contains(driverId)) {
          declinedDrivers.add(driverId);
        }

        // Update the ride request
        transaction.update(rideRef, {
          'declinedDrivers': declinedDrivers,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Ride request $rideId declined by driver $driverId');
        return true;
      });
    } catch (e) {
      debugPrint('❌ Error declining ride request: $e');
      return false;
    }
  }

  /// Cancel a ride request
  static Future<bool> cancelRideRequest({
    required String rideId,
    required String cancelledBy, // 'rider' or 'driver'
    required String cancellationReason,
  }) async {
    try {
      await _firestore.collection(_rideRequestsCollection).doc(rideId).update({
        'status': RideRequestStatus.cancelled.name,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': cancelledBy,
        'cancellationReason': cancellationReason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Ride request $rideId cancelled by $cancelledBy');
      return true;
    } catch (e) {
      debugPrint('❌ Error cancelling ride request: $e');
      return false;
    }
  }

  /// Get current active ride for a user (rider or driver)
  static Future<RideRequestModel?> getCurrentActiveRide(String userId) async {
    try {
      // Check as rider - get all active rides and sort in app code
      final riderQuery = await _firestore
          .collection(_rideRequestsCollection)
          .where('riderId', isEqualTo: userId)
          .where(
            'status',
            whereIn: [
              RideRequestStatus.pending.name,
              RideRequestStatus.accepted.name,
              RideRequestStatus.inProgress.name,
            ],
          )
          .get();

      if (riderQuery.docs.isNotEmpty) {
        final rides = riderQuery.docs
            .map((doc) => RideRequestModel.fromMap(doc.data(), doc.id))
            .toList();

        // Filter to only current rides (using stricter criteria)
        final currentRides = rides.where((ride) => ride.isCurrentRide).toList();
        if (currentRides.isNotEmpty) {
          // Sort by creation date and get the most recent
          currentRides.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return currentRides.first;
        }
      }

      // Check as driver - get all active rides and sort in app code
      final driverQuery = await _firestore
          .collection(_rideRequestsCollection)
          .where('driverId', isEqualTo: userId)
          .where(
            'status',
            whereIn: [
              RideRequestStatus.accepted.name,
              RideRequestStatus.inProgress.name,
            ],
          )
          .get();

      if (driverQuery.docs.isNotEmpty) {
        final rides = driverQuery.docs
            .map((doc) => RideRequestModel.fromMap(doc.data(), doc.id))
            .toList();

        // Filter to only current rides (using stricter criteria)
        final currentRides = rides.where((ride) => ride.isCurrentRide).toList();
        if (currentRides.isNotEmpty) {
          // Sort by creation date and get the most recent
          currentRides.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return currentRides.first;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting current active ride: $e');
      return null;
    }
  }

  /// Delete old completed/cancelled ride requests (cleanup)
  static Future<void> cleanupOldRideRequests() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));

      final oldRides = await _firestore
          .collection(_rideRequestsCollection)
          .where(
            'status',
            whereIn: [
              RideRequestStatus.completed.name,
              RideRequestStatus.cancelled.name,
            ],
          )
          .where('updatedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldRides.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ Cleaned up ${oldRides.docs.length} old ride requests');
    } catch (e) {
      debugPrint('❌ Error cleaning up old ride requests: $e');
    }
  }
}
