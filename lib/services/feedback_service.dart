import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/feedback_model.dart';
import '../models/ride_model.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit feedback for a ride
  Future<FeedbackModel?> submitFeedback({
    required String rideId,
    required String fromUserId,
    required String toUserId,
    required String fromUserRole,
    required String toUserRole,
    required int rating,
    String? feedbackText,
    required List<String> tags,
    bool isAnonymous = false,
  }) async {
    try {
      // Validate rating
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      // Create feedback document
      final feedbackDoc = await _firestore.collection('feedback').add({
        'rideId': rideId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'fromUserRole': fromUserRole,
        'toUserRole': toUserRole,
        'rating': rating,
        'feedbackText': feedbackText,
        'tags': tags,
        'createdAt': Timestamp.now(),
        'isAnonymous': isAnonymous,
      });

      // Update user rating
      await _updateUserRating(toUserId);

      // Mark ride as rated
      await _markRideAsRated(rideId, fromUserId);

      return FeedbackModel.fromMap({
        'rideId': rideId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'fromUserRole': fromUserRole,
        'toUserRole': toUserRole,
        'rating': rating,
        'feedbackText': feedbackText,
        'tags': tags,
        'createdAt': Timestamp.now(),
        'isAnonymous': isAnonymous,
      }, feedbackDoc.id);
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      return null;
    }
  }

  // Get feedback for a specific ride
  Future<List<FeedbackModel>> getRideFeedback(String rideId) async {
    try {
      final feedbackDocs = await _firestore
          .collection('feedback')
          .where('rideId', isEqualTo: rideId)
          .orderBy('createdAt', descending: true)
          .get();

      return feedbackDocs.docs
          .map((doc) => FeedbackModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting ride feedback: $e');
      return [];
    }
  }

  // Get user's feedback history (feedback given by user)
  Stream<List<FeedbackModel>> getUserFeedbackHistory(String userId) {
    return _firestore
        .collection('feedback')
        .where('fromUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FeedbackModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get feedback received by a user
  Stream<List<FeedbackModel>> getFeedbackReceived(String userId) {
    try {
      return _firestore
          .collection('feedback')
          .where('toUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return FeedbackModel.fromMap(doc.data(), doc.id);
            }).toList();
          });
    } catch (e) {
      debugPrint(
        'Complex feedback received query failed, trying simple query: $e',
      );

      // Fallback to simple query without ordering
      try {
        return _firestore
            .collection('feedback')
            .where('toUserId', isEqualTo: userId)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs.map((doc) {
                return FeedbackModel.fromMap(doc.data(), doc.id);
              }).toList();
            });
      } catch (e2) {
        debugPrint('Simple feedback received query also failed: $e2');
        return Stream.value([]);
      }
    }
  }

  // Get feedback given by a user
  Stream<List<FeedbackModel>> getFeedbackGiven(String userId) {
    try {
      return _firestore
          .collection('feedback')
          .where('fromUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return FeedbackModel.fromMap(doc.data(), doc.id);
            }).toList();
          });
    } catch (e) {
      debugPrint(
        'Complex feedback given query failed, trying simple query: $e',
      );

      // Fallback to simple query without ordering
      try {
        return _firestore
            .collection('feedback')
            .where('fromUserId', isEqualTo: userId)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs.map((doc) {
                return FeedbackModel.fromMap(doc.data(), doc.id);
              }).toList();
            });
      } catch (e2) {
        debugPrint('Simple feedback given query also failed: $e2');
        return Stream.value([]);
      }
    }
  }

  // Get user rating
  Future<UserRating?> getUserRating(String userId) async {
    try {
      final ratingDoc = await _firestore
          .collection('user_ratings')
          .doc(userId)
          .get();

      if (ratingDoc.exists) {
        return UserRating.fromMap(ratingDoc.data()!, userId);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user rating: $e');
      return null;
    }
  }

  // Stream user rating updates
  Stream<UserRating?> getUserRatingStream(String userId) {
    return _firestore.collection('user_ratings').doc(userId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return UserRating.fromMap(doc.data()!, userId);
      }
      return null;
    });
  }

  // Check if user has already rated a ride
  Future<bool> hasUserRatedRide(String rideId, String userId) async {
    try {
      final feedbackDoc = await _firestore
          .collection('feedback')
          .where('rideId', isEqualTo: rideId)
          .where('fromUserId', isEqualTo: userId)
          .get();

      return feedbackDoc.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user rated ride: $e');
      return false;
    }
  }

  // Get rides that need feedback from user
  Future<List<RideModel>> getRidesNeedingFeedback(String userId) async {
    try {
      // Get completed rides for the user
      final ridesQuery = _firestore
          .collection('rides')
          .where('riderId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed');

      final ridesDocs = await ridesQuery.get();
      final rides = ridesDocs.docs
          .map((doc) => RideModel.fromMap(doc.data()))
          .toList();

      // Filter rides that haven't been rated yet
      final ridesNeedingFeedback = <RideModel>[];
      for (final ride in rides) {
        final hasRated = await hasUserRatedRide(ride.id, userId);
        if (!hasRated) {
          ridesNeedingFeedback.add(ride);
        }
      }

      return ridesNeedingFeedback;
    } catch (e) {
      debugPrint('Error getting rides needing feedback: $e');
      return [];
    }
  }

  // Get driver rides that need feedback
  Future<List<RideModel>> getDriverRidesNeedingFeedback(String driverId) async {
    try {
      // Get completed rides for the driver
      final ridesQuery = _firestore
          .collection('rides')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'completed');

      final ridesDocs = await ridesQuery.get();
      final rides = ridesDocs.docs
          .map((doc) => RideModel.fromMap(doc.data()))
          .toList();

      // Filter rides that haven't been rated yet
      final ridesNeedingFeedback = <RideModel>[];
      for (final ride in rides) {
        final hasRated = await hasUserRatedRide(ride.id, driverId);
        if (!hasRated) {
          ridesNeedingFeedback.add(ride);
        }
      }

      return ridesNeedingFeedback;
    } catch (e) {
      debugPrint('Error getting driver rides needing feedback: $e');
      return [];
    }
  }

  // Update user rating based on all feedback received
  Future<void> _updateUserRating(String userId) async {
    try {
      // Get all feedback for the user
      final feedbackDocs = await _firestore
          .collection('feedback')
          .where('toUserId', isEqualTo: userId)
          .get();

      if (feedbackDocs.docs.isEmpty) return;

      final feedbacks = feedbackDocs.docs
          .map((doc) => FeedbackModel.fromMap(doc.data(), doc.id))
          .toList();

      // Calculate average rating
      final totalRating = feedbacks.fold<int>(
        0,
        (sum, feedback) => sum + feedback.rating,
      );
      final averageRating = totalRating / feedbacks.length;

      // Calculate rating distribution
      final ratingDistribution = <String, int>{};
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i.toString()] = feedbacks
            .where((f) => f.rating == i)
            .length;
      }

      // Get common tags
      final tagCounts = <String, int>{};
      for (final feedback in feedbacks) {
        for (final tag in feedback.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      final commonTags = tagCounts.entries
          .where((entry) => entry.value >= 2) // Tags mentioned at least twice
          .map((entry) => entry.key)
          .toList();

      // Update user rating document
      await _firestore.collection('user_ratings').doc(userId).set({
        'averageRating': averageRating,
        'totalRatings': feedbacks.length,
        'ratingDistribution': ratingDistribution,
        'commonTags': commonTags,
        'lastUpdated': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error updating user rating: $e');
    }
  }

  // Mark ride as rated by user
  Future<void> _markRideAsRated(String rideId, String userId) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'ratedBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error marking ride as rated: $e');
    }
  }

  // Get feedback statistics for a user
  Future<Map<String, dynamic>> getUserFeedbackStats(String userId) async {
    try {
      final feedbackDocs = await _firestore
          .collection('feedback')
          .where('toUserId', isEqualTo: userId)
          .get();

      final feedbacks = feedbackDocs.docs
          .map((doc) => FeedbackModel.fromMap(doc.data(), doc.id))
          .toList();

      if (feedbacks.isEmpty) {
        return {
          'totalFeedback': 0,
          'averageRating': 0.0,
          'ratingDistribution': {},
          'commonTags': [],
          'recentFeedback': [],
        };
      }

      // Calculate statistics
      final totalRating = feedbacks.fold<int>(
        0,
        (sum, feedback) => sum + feedback.rating,
      );
      final averageRating = totalRating / feedbacks.length;

      final ratingDistribution = <String, int>{};
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i.toString()] = feedbacks
            .where((f) => f.rating == i)
            .length;
      }

      final tagCounts = <String, int>{};
      for (final feedback in feedbacks) {
        for (final tag in feedback.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      final commonTags = tagCounts.entries
          .where((entry) => entry.value >= 2)
          .map((entry) => entry.key)
          .toList();

      // Get recent feedback (last 5)
      final recentFeedback = feedbacks
          .take(5)
          .map(
            (f) => {
              'rating': f.rating,
              'feedbackText': f.feedbackText,
              'tags': f.tags,
              'createdAt': f.createdAt,
              'isAnonymous': f.isAnonymous,
            },
          )
          .toList();

      return {
        'totalFeedback': feedbacks.length,
        'averageRating': averageRating,
        'ratingDistribution': ratingDistribution,
        'commonTags': commonTags,
        'recentFeedback': recentFeedback,
      };
    } catch (e) {
      debugPrint('Error getting user feedback stats: $e');
      return {};
    }
  }

  // Delete feedback (admin only or user who created it)
  Future<bool> deleteFeedback(String feedbackId, String userId) async {
    try {
      final feedbackDoc = await _firestore
          .collection('feedback')
          .doc(feedbackId)
          .get();

      if (!feedbackDoc.exists) return false;

      final feedback = FeedbackModel.fromMap(feedbackDoc.data()!, feedbackId);

      // Only allow deletion if user created the feedback
      if (feedback.fromUserId != userId) return false;

      await _firestore.collection('feedback').doc(feedbackId).delete();

      // Update user rating after deletion
      await _updateUserRating(feedback.toUserId);

      return true;
    } catch (e) {
      debugPrint('Error deleting feedback: $e');
      return false;
    }
  }
}
