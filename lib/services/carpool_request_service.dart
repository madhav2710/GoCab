import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/carpool_request_model.dart';
import '../models/carpool_ride_model.dart';
import 'carpool_service.dart';

class CarpoolRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CarpoolService _carpoolService = CarpoolService();

  // Create a carpool request
  Future<CarpoolRequestModel> createCarpoolRequest({
    required String carpoolRideId,
    required String requesterId,
    required String requesterName,
    required String requesterPhone,
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
      final requestId = _firestore.collection('carpool_requests').doc().id;

      final carpoolRequest = CarpoolRequestModel(
        id: requestId,
        carpoolRideId: carpoolRideId,
        requesterId: requesterId,
        requesterName: requesterName,
        requesterPhone: requesterPhone,
        pickupAddress: pickupAddress,
        dropoffAddress: dropoffAddress,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        dropoffLatitude: dropoffLatitude,
        dropoffLongitude: dropoffLongitude,
        estimatedFare: estimatedFare,
        status: CarpoolRequestStatus.pending,
        message: message,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('carpool_requests')
          .doc(requestId)
          .set(carpoolRequest.toMap());

      debugPrint('Carpool request created: $requestId');
      return carpoolRequest;
    } catch (e) {
      debugPrint('Failed to create carpool request: $e');
      throw Exception('Failed to create carpool request: $e');
    }
  }

  // Get carpool requests for a specific carpool ride
  Future<List<CarpoolRequestModel>> getCarpoolRequests(
    String carpoolRideId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('carpool_requests')
          .where('carpoolRideId', isEqualTo: carpoolRideId)
          .get();

      final requests = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CarpoolRequestModel.fromMap(data);
      }).toList();

      // Sort by creation date (newest first)
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return requests;
    } catch (e) {
      debugPrint('Failed to get carpool requests: $e');
      return []; // Return empty list instead of throwing error
    }
  }

  // Get carpool requests by a specific user
  Future<List<CarpoolRequestModel>> getUserCarpoolRequests(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('carpool_requests')
          .where('requesterId', isEqualTo: userId)
          .get();

      final requests = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CarpoolRequestModel.fromMap(data);
      }).toList();

      // Sort by creation date (newest first)
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return requests;
    } catch (e) {
      debugPrint('Failed to get user carpool requests: $e');
      return []; // Return empty list instead of throwing error
    }
  }

  // Approve a carpool request
  Future<bool> approveCarpoolRequest(String requestId) async {
    try {
      final requestDoc = await _firestore
          .collection('carpool_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Carpool request not found');
      }

      final request = CarpoolRequestModel.fromMap(requestDoc.data()!);

      // Check if the carpool ride still has available seats
      final carpoolRide = await _carpoolService.getCarpoolRideById(
        request.carpoolRideId,
      );
      if (carpoolRide == null) {
        throw Exception('Carpool ride not found');
      }

      if (carpoolRide.availableSeats <= 0) {
        // Update request status to rejected
        await _firestore.collection('carpool_requests').doc(requestId).update({
          'status': CarpoolRequestStatus.rejected.name,
          'respondedAt': DateTime.now(),
          'responseMessage': 'No available seats',
        });
        return false;
      }

      // Create carpool rider
      final carpoolRider = CarpoolRider(
        riderId: request.requesterId,
        riderName: request.requesterName,
        pickupAddress: request.pickupAddress,
        dropoffAddress: request.dropoffAddress,
        pickupLatitude: request.pickupLatitude,
        pickupLongitude: request.pickupLongitude,
        dropoffLatitude: request.dropoffLatitude,
        dropoffLongitude: request.dropoffLongitude,
        fare: request.estimatedFare,
        status: CarpoolRiderStatus.waiting,
        joinedAt: DateTime.now(),
      );

      // Add rider to carpool
      final success = await _carpoolService.joinCarpoolRide(
        carpoolRideId: request.carpoolRideId,
        newRider: carpoolRider,
      );

      if (success) {
        // Update request status to approved
        await _firestore.collection('carpool_requests').doc(requestId).update({
          'status': CarpoolRequestStatus.approved.name,
          'respondedAt': DateTime.now(),
          'responseMessage': 'Request approved! Welcome to the carpool.',
        });
        debugPrint('Carpool request approved: $requestId');
        return true;
      } else {
        // Update request status to rejected
        await _firestore.collection('carpool_requests').doc(requestId).update({
          'status': CarpoolRequestStatus.rejected.name,
          'respondedAt': DateTime.now(),
          'responseMessage': 'Failed to join carpool',
        });
        return false;
      }
    } catch (e) {
      debugPrint('Failed to approve carpool request: $e');
      throw Exception('Failed to approve carpool request: $e');
    }
  }

  // Reject a carpool request
  Future<void> rejectCarpoolRequest(String requestId, String reason) async {
    try {
      await _firestore.collection('carpool_requests').doc(requestId).update({
        'status': CarpoolRequestStatus.rejected.name,
        'respondedAt': DateTime.now(),
        'responseMessage': reason,
      });
      debugPrint('Carpool request rejected: $requestId');
    } catch (e) {
      debugPrint('Failed to reject carpool request: $e');
      throw Exception('Failed to reject carpool request: $e');
    }
  }

  // Cancel a carpool request
  Future<void> cancelCarpoolRequest(String requestId) async {
    try {
      await _firestore.collection('carpool_requests').doc(requestId).update({
        'status': CarpoolRequestStatus.cancelled.name,
        'respondedAt': DateTime.now(),
        'responseMessage': 'Request cancelled by user',
      });
      debugPrint('Carpool request cancelled: $requestId');
    } catch (e) {
      debugPrint('Failed to cancel carpool request: $e');
      throw Exception('Failed to cancel carpool request: $e');
    }
  }

  // Get carpool requests for a driver (requests for their carpool rides)
  Future<List<CarpoolRequestModel>> getDriverCarpoolRequests(
    String driverId,
  ) async {
    try {
      // First get all carpool rides by this driver
      final carpoolRides = await _carpoolService.getDriverCarpoolRides(
        driverId,
      );
      final carpoolRideIds = carpoolRides.map((ride) => ride.id).toList();

      if (carpoolRideIds.isEmpty) {
        return [];
      }

      // Get all requests for these carpool rides (simplified query)
      final querySnapshot = await _firestore
          .collection('carpool_requests')
          .get();

      final allRequests = querySnapshot.docs
          .map((doc) => CarpoolRequestModel.fromMap(doc.data()))
          .where((request) => carpoolRideIds.contains(request.carpoolRideId))
          .toList();

      // Sort by creation date (newest first)
      allRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return allRequests;
    } catch (e) {
      debugPrint('Failed to get driver carpool requests: $e');
      return []; // Return empty list instead of throwing error
    }
  }

  // Stream of carpool requests for a specific carpool ride
  Stream<List<CarpoolRequestModel>> getCarpoolRequestsStream(
    String carpoolRideId,
  ) {
    return _firestore
        .collection('carpool_requests')
        .where('carpoolRideId', isEqualTo: carpoolRideId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CarpoolRequestModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Stream of carpool requests for a driver
  Stream<List<CarpoolRequestModel>> getDriverCarpoolRequestsStream(
    String driverId,
  ) {
    return _firestore.collection('carpool_requests').snapshots().asyncMap((
      snapshot,
    ) async {
      // Get driver's carpool rides
      final carpoolRides = await _carpoolService.getDriverCarpoolRides(
        driverId,
      );
      final carpoolRideIds = carpoolRides.map((ride) => ride.id).toSet();

      // Filter requests for driver's carpool rides
      return snapshot.docs
          .map((doc) => CarpoolRequestModel.fromMap(doc.data()))
          .where((request) => carpoolRideIds.contains(request.carpoolRideId))
          .toList();
    });
  }

  // Check if user has already requested to join a carpool
  Future<bool> hasUserRequestedCarpool(
    String userId,
    String carpoolRideId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('carpool_requests')
          .where('requesterId', isEqualTo: userId)
          .where('carpoolRideId', isEqualTo: carpoolRideId)
          .where('status', whereIn: ['pending', 'approved'])
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Failed to check if user has requested carpool: $e');
      return false;
    }
  }
}
