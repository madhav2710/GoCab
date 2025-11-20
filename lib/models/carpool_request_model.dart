import 'package:cloud_firestore/cloud_firestore.dart';

class CarpoolRequestModel {
  final String id;
  final String carpoolRideId;
  final String requesterId;
  final String requesterName;
  final String requesterPhone;
  final String pickupAddress;
  final String dropoffAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final double estimatedFare;
  final CarpoolRequestStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? responseMessage;

  CarpoolRequestModel({
    required this.id,
    required this.carpoolRideId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterPhone,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.estimatedFare,
    required this.status,
    this.message,
    required this.createdAt,
    this.respondedAt,
    this.responseMessage,
  });

  factory CarpoolRequestModel.fromMap(Map<String, dynamic> map) {
    return CarpoolRequestModel(
      id: map['id'] ?? '',
      carpoolRideId: map['carpoolRideId'] ?? '',
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      requesterPhone: map['requesterPhone'] ?? '',
      pickupAddress: map['pickupAddress'] ?? '',
      dropoffAddress: map['dropoffAddress'] ?? '',
      pickupLatitude: (map['pickupLatitude'] ?? 0.0).toDouble(),
      pickupLongitude: (map['pickupLongitude'] ?? 0.0).toDouble(),
      dropoffLatitude: (map['dropoffLatitude'] ?? 0.0).toDouble(),
      dropoffLongitude: (map['dropoffLongitude'] ?? 0.0).toDouble(),
      estimatedFare: (map['estimatedFare'] ?? 0.0).toDouble(),
      status: _getStatusFromString(map['status'] ?? 'pending'),
      message: map['message'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      respondedAt: map['respondedAt'] != null
          ? (map['respondedAt'] as Timestamp).toDate()
          : null,
      responseMessage: map['responseMessage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carpoolRideId': carpoolRideId,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterPhone': requesterPhone,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'dropoffLatitude': dropoffLatitude,
      'dropoffLongitude': dropoffLongitude,
      'estimatedFare': estimatedFare,
      'status': status.name,
      'message': message,
      'createdAt': createdAt,
      'respondedAt': respondedAt,
      'responseMessage': responseMessage,
    };
  }

  static CarpoolRequestStatus _getStatusFromString(String status) {
    switch (status) {
      case 'pending':
        return CarpoolRequestStatus.pending;
      case 'approved':
        return CarpoolRequestStatus.approved;
      case 'rejected':
        return CarpoolRequestStatus.rejected;
      case 'cancelled':
        return CarpoolRequestStatus.cancelled;
      default:
        return CarpoolRequestStatus.pending;
    }
  }

  CarpoolRequestModel copyWith({
    String? id,
    String? carpoolRideId,
    String? requesterId,
    String? requesterName,
    String? requesterPhone,
    String? pickupAddress,
    String? dropoffAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    double? dropoffLatitude,
    double? dropoffLongitude,
    double? estimatedFare,
    CarpoolRequestStatus? status,
    String? message,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? responseMessage,
  }) {
    return CarpoolRequestModel(
      id: id ?? this.id,
      carpoolRideId: carpoolRideId ?? this.carpoolRideId,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterPhone: requesterPhone ?? this.requesterPhone,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      dropoffLatitude: dropoffLatitude ?? this.dropoffLatitude,
      dropoffLongitude: dropoffLongitude ?? this.dropoffLongitude,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      responseMessage: responseMessage ?? this.responseMessage,
    );
  }
}

enum CarpoolRequestStatus { pending, approved, rejected, cancelled }
