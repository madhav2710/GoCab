import 'package:flutter_test/flutter_test.dart';
import 'package:gocab/models/feedback_model.dart';

void main() {
  group('Feedback Models Tests', () {
    test('FeedbackModel creation and serialization', () {
      final feedback = FeedbackModel(
        id: 'feedback_123',
        rideId: 'ride_456',
        fromUserId: 'user_1',
        toUserId: 'user_2',
        fromUserRole: 'rider',
        toUserRole: 'driver',
        rating: 5,
        feedbackText: 'Great ride experience!',
        tags: ['Safe Driving', 'Friendly', 'Clean Vehicle'],
        createdAt: DateTime.now(),
        isAnonymous: false,
      );

      expect(feedback.id, 'feedback_123');
      expect(feedback.rideId, 'ride_456');
      expect(feedback.fromUserId, 'user_1');
      expect(feedback.toUserId, 'user_2');
      expect(feedback.rating, 5);
      expect(feedback.feedbackText, 'Great ride experience!');
      expect(feedback.tags.length, 3);
      expect(feedback.isAnonymous, false);
    });

    test('UserRating creation and serialization', () {
      final userRating = UserRating(
        userId: 'user_123',
        averageRating: 4.5,
        totalRatings: 10,
        ratingDistribution: {
          '1': 0,
          '2': 1,
          '3': 2,
          '4': 4,
          '5': 3,
        },
        commonTags: ['Safe Driving', 'Friendly', 'Punctual'],
        lastUpdated: DateTime.now(),
      );

      expect(userRating.userId, 'user_123');
      expect(userRating.averageRating, 4.5);
      expect(userRating.totalRatings, 10);
      expect(userRating.ratingDistribution.length, 5);
      expect(userRating.commonTags.length, 3);
    });

    test('FeedbackModel with anonymous feedback', () {
      final feedback = FeedbackModel(
        id: 'feedback_456',
        rideId: 'ride_789',
        fromUserId: 'user_1',
        toUserId: 'user_2',
        fromUserRole: 'rider',
        toUserRole: 'driver',
        rating: 4,
        tags: ['Professional'],
        createdAt: DateTime.now(),
        isAnonymous: true,
      );

      expect(feedback.isAnonymous, true);
      expect(feedback.feedbackText, null);
    });

    test('UserRating with no ratings', () {
      final userRating = UserRating(
        userId: 'user_456',
        averageRating: 0.0,
        totalRatings: 0,
        ratingDistribution: {},
        commonTags: [],
        lastUpdated: DateTime.now(),
      );

      expect(userRating.averageRating, 0.0);
      expect(userRating.totalRatings, 0);
      expect(userRating.ratingDistribution.isEmpty, true);
      expect(userRating.commonTags.isEmpty, true);
    });
  });
}
