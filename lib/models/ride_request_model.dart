import 'package:cloud_firestore/cloud_firestore.dart';

enum RideRequestStatus { pending, accepted, inProgress, completed, cancelled }

enum RideType { standard, premium, carpool }

class RideRequestModel {
  final String id;
  final String riderId;
  final String riderName;
  final String riderPhone;
  final String pickupAddress;
  final String dropoffAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final double estimatedFare;
  final double actualFare;
  final RideType rideType;
  final RideRequestStatus status;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? vehicleNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;
  final String paymentMethod;
  final String paymentStatus;
  final String notes;
  final List<String>? declinedDrivers;

  RideRequestModel({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.riderPhone,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.estimatedFare,
    required this.actualFare,
    required this.rideType,
    required this.status,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.vehicleNumber,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.notes,
    this.declinedDrivers,
  });

  factory RideRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return RideRequestModel(
      id: id,
      riderId: map['riderId'] ?? '',
      riderName: map['riderName'] ?? '',
      riderPhone: map['riderPhone'] ?? '',
      pickupAddress: map['pickupAddress'] ?? '',
      dropoffAddress: map['dropoffAddress'] ?? '',
      pickupLatitude: (map['pickupLatitude'] as num?)?.toDouble() ?? 0.0,
      pickupLongitude: (map['pickupLongitude'] as num?)?.toDouble() ?? 0.0,
      dropoffLatitude: (map['dropoffLatitude'] as num?)?.toDouble() ?? 0.0,
      dropoffLongitude: (map['dropoffLongitude'] as num?)?.toDouble() ?? 0.0,
      estimatedFare: (map['estimatedFare'] as num?)?.toDouble() ?? 0.0,
      actualFare: (map['actualFare'] as num?)?.toDouble() ?? 0.0,
      rideType: RideType.values.firstWhere(
        (e) => e.name == map['rideType'],
        orElse: () => RideType.standard,
      ),
      status: RideRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RideRequestStatus.pending,
      ),
      driverId: map['driverId'],
      driverName: map['driverName'],
      driverPhone: map['driverPhone'],
      vehicleNumber: map['vehicleNumber'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
      startedAt: (map['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (map['cancelledAt'] as Timestamp?)?.toDate(),
      cancelledBy: map['cancelledBy'],
      cancellationReason: map['cancellationReason'],
      paymentMethod: map['paymentMethod'] ?? 'cash',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      notes: map['notes'] ?? '',
      declinedDrivers: map['declinedDrivers'] != null
          ? List<String>.from(map['declinedDrivers'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'dropoffLatitude': dropoffLatitude,
      'dropoffLongitude': dropoffLongitude,
      'estimatedFare': estimatedFare,
      'actualFare': actualFare,
      'rideType': rideType.name,
      'status': status.name,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehicleNumber': vehicleNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'cancelledAt': cancelledAt != null
          ? Timestamp.fromDate(cancelledAt!)
          : null,
      'cancelledBy': cancelledBy,
      'cancellationReason': cancellationReason,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'notes': notes,
      'declinedDrivers': declinedDrivers,
    };
  }

  RideRequestModel copyWith({
    String? id,
    String? riderId,
    String? riderName,
    String? riderPhone,
    String? pickupAddress,
    String? dropoffAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    double? dropoffLatitude,
    double? dropoffLongitude,
    double? estimatedFare,
    double? actualFare,
    RideType? rideType,
    RideRequestStatus? status,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? vehicleNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancelledBy,
    String? cancellationReason,
    String? paymentMethod,
    String? paymentStatus,
    String? notes,
    List<String>? declinedDrivers,
  }) {
    return RideRequestModel(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      dropoffLatitude: dropoffLatitude ?? this.dropoffLatitude,
      dropoffLongitude: dropoffLongitude ?? this.dropoffLongitude,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      actualFare: actualFare ?? this.actualFare,
      rideType: rideType ?? this.rideType,
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      declinedDrivers: declinedDrivers ?? this.declinedDrivers,
    );
  }

  bool get isActive {
    // For pending rides, check if they're not too old (30 minutes timeout)
    if (status == RideRequestStatus.pending) {
      final now = DateTime.now();
      final timeDifference = now.difference(createdAt);
      // If pending for more than 30 minutes, consider it inactive
      if (timeDifference.inMinutes > 30) {
        return false;
      }
    }

    return status == RideRequestStatus.pending ||
        status == RideRequestStatus.accepted ||
        status == RideRequestStatus.inProgress;
  }

  bool get isCompleted {
    return status == RideRequestStatus.completed;
  }

  bool get isCancelled {
    return status == RideRequestStatus.cancelled;
  }

  /// Check if this ride should be shown as a current ride to the user
  /// This is more restrictive than isActive - it filters out old pending rides
  bool get isCurrentRide {
    // Only show accepted and in-progress rides as current
    // Pending rides are only current if they're very recent (less than 10 minutes)
    if (status == RideRequestStatus.pending) {
      final now = DateTime.now();
      final timeDifference = now.difference(createdAt);
      // Only show pending rides that are less than 10 minutes old
      return timeDifference.inMinutes < 10;
    }

    return status == RideRequestStatus.accepted ||
        status == RideRequestStatus.inProgress;
  }

  String get statusDisplayName {
    switch (status) {
      case RideRequestStatus.pending:
        return 'Waiting for Driver';
      case RideRequestStatus.accepted:
        return 'Driver Assigned';
      case RideRequestStatus.inProgress:
        return 'Ride in Progress';
      case RideRequestStatus.completed:
        return 'Completed';
      case RideRequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get statusDescription {
    switch (status) {
      case RideRequestStatus.pending:
        return 'Your ride request is being processed. We\'re looking for a driver nearby.';
      case RideRequestStatus.accepted:
        return 'Great! A driver has accepted your ride. They\'re on their way to pick you up.';
      case RideRequestStatus.inProgress:
        return 'Your ride is in progress. Enjoy your journey!';
      case RideRequestStatus.completed:
        return 'Your ride has been completed. Thank you for using GoCab!';
      case RideRequestStatus.cancelled:
        return 'This ride has been cancelled. ${cancellationReason ?? 'No reason provided.'}';
    }
  }

  @override
  String toString() {
    return 'RideRequestModel(id: $id, status: $status, rider: $riderName, driver: $driverName, fare: ₹$actualFare)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RideRequestModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
