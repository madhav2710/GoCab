import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String rideId;
  final String fromUserId; // User giving the feedback
  final String toUserId; // User receiving the feedback
  final String fromUserRole; // 'rider' or 'driver'
  final String toUserRole; // 'rider' or 'driver'
  final int rating; // 1-5 stars
  final String? feedbackText;
  final List<String> tags; // e.g., ['clean', 'safe', 'friendly', 'punctual']
  final DateTime createdAt;
  final bool isAnonymous;

  FeedbackModel({
    required this.id,
    required this.rideId,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserRole,
    required this.toUserRole,
    required this.rating,
    this.feedbackText,
    required this.tags,
    required this.createdAt,
    this.isAnonymous = false,
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      rideId: map['rideId'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      toUserId: map['toUserId'] ?? '',
      fromUserRole: map['fromUserRole'] ?? '',
      toUserRole: map['toUserRole'] ?? '',
      rating: map['rating'] ?? 0,
      feedbackText: map['feedbackText'],
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isAnonymous: map['isAnonymous'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rideId': rideId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromUserRole': fromUserRole,
      'toUserRole': toUserRole,
      'rating': rating,
      'feedbackText': feedbackText,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAnonymous': isAnonymous,
    };
  }

  FeedbackModel copyWith({
    String? id,
    String? rideId,
    String? fromUserId,
    String? toUserId,
    String? fromUserRole,
    String? toUserRole,
    int? rating,
    String? feedbackText,
    List<String>? tags,
    DateTime? createdAt,
    bool? isAnonymous,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      fromUserRole: fromUserRole ?? this.fromUserRole,
      toUserRole: toUserRole ?? this.toUserRole,
      rating: rating ?? this.rating,
      feedbackText: feedbackText ?? this.feedbackText,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }
}

class UserRating {
  final String userId;
  final double averageRating;
  final int totalRatings;
  final Map<String, int> ratingDistribution; // 1: count, 2: count, etc.
  final List<String> commonTags;
  final DateTime lastUpdated;

  UserRating({
    required this.userId,
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
    required this.commonTags,
    required this.lastUpdated,
  });

  factory UserRating.fromMap(Map<String, dynamic> map, String userId) {
    return UserRating(
      userId: userId,
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
      ratingDistribution: Map<String, int>.from(map['ratingDistribution'] ?? {}),
      commonTags: List<String>.from(map['commonTags'] ?? []),
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'ratingDistribution': ratingDistribution,
      'commonTags': commonTags,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  UserRating copyWith({
    String? userId,
    double? averageRating,
    int? totalRatings,
    Map<String, int>? ratingDistribution,
    List<String>? commonTags,
    DateTime? lastUpdated,
  }) {
    return UserRating(
      userId: userId ?? this.userId,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
      commonTags: commonTags ?? this.commonTags,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
