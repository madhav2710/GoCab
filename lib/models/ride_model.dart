import 'package:cloud_firestore/cloud_firestore.dart';

enum RideType { solo, carpool }

enum RideStatus {
  pending,
  accepted,
  inProgress,
  arrived,
  pickupComplete,
  completed,
  cancelled,
}

class RideModel {
  final String id;
  final String riderId;
  final String? driverId;
  final String pickupAddress;
  final String dropoffAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final RideType rideType;
  final RideStatus status;
  final double estimatedFare;
  final double? actualFare;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  RideModel({
    required this.id,
    required this.riderId,
    this.driverId,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.rideType,
    required this.status,
    required this.estimatedFare,
    this.actualFare,
    required this.createdAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
  });

  factory RideModel.fromMap(Map<String, dynamic> map) {
    return RideModel(
      id: map['id'] ?? '',
      riderId: map['riderId'] ?? '',
      driverId: map['driverId'],
      pickupAddress: map['pickupAddress'] ?? '',
      dropoffAddress: map['dropoffAddress'] ?? '',
      pickupLatitude: (map['pickupLatitude'] ?? 0.0).toDouble(),
      pickupLongitude: (map['pickupLongitude'] ?? 0.0).toDouble(),
      dropoffLatitude: (map['dropoffLatitude'] ?? 0.0).toDouble(),
      dropoffLongitude: (map['dropoffLongitude'] ?? 0.0).toDouble(),
      rideType: map['rideType'] == 'carpool' ? RideType.carpool : RideType.solo,
      status: _getStatusFromString(map['status'] ?? 'pending'),
      estimatedFare: (map['estimatedFare'] ?? 0.0).toDouble(),
      actualFare: map['actualFare'] != null
          ? (map['actualFare'] as num).toDouble()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      acceptedAt: map['acceptedAt'] != null
          ? (map['acceptedAt'] as Timestamp).toDate()
          : null,
      startedAt: map['startedAt'] != null
          ? (map['startedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'riderId': riderId,
      'driverId': driverId,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'dropoffLatitude': dropoffLatitude,
      'dropoffLongitude': dropoffLongitude,
      'rideType': rideType == RideType.carpool ? 'carpool' : 'solo',
      'status': status.name,
      'estimatedFare': estimatedFare,
      'actualFare': actualFare,
      'createdAt': createdAt,
      'acceptedAt': acceptedAt,
      'startedAt': startedAt,
      'completedAt': completedAt,
    };
  }

  static RideStatus _getStatusFromString(String status) {
    switch (status) {
      case 'accepted':
        return RideStatus.accepted;
      case 'inProgress':
        return RideStatus.inProgress;
      case 'arrived':
        return RideStatus.arrived;
      case 'pickupComplete':
        return RideStatus.pickupComplete;
      case 'completed':
        return RideStatus.completed;
      case 'cancelled':
        return RideStatus.cancelled;
      default:
        return RideStatus.pending;
    }
  }

  RideModel copyWith({
    String? id,
    String? riderId,
    String? driverId,
    String? pickupAddress,
    String? dropoffAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    double? dropoffLatitude,
    double? dropoffLongitude,
    RideType? rideType,
    RideStatus? status,
    double? estimatedFare,
    double? actualFare,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return RideModel(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      driverId: driverId ?? this.driverId,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      dropoffLatitude: dropoffLatitude ?? this.dropoffLatitude,
      dropoffLongitude: dropoffLongitude ?? this.dropoffLongitude,
      rideType: rideType ?? this.rideType,
      status: status ?? this.status,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      actualFare: actualFare ?? this.actualFare,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
