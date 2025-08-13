import 'package:cloud_firestore/cloud_firestore.dart';

class CarpoolRideModel {
  final String id;
  final String driverId;
  final List<CarpoolRider> riders;
  final List<CarpoolStop> stops;
  final int maxSeats;
  final int availableSeats;
  final double totalFare;
  final Map<String, double> riderFares; // riderId -> fare amount
  final CarpoolStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  CarpoolRideModel({
    required this.id,
    required this.driverId,
    required this.riders,
    required this.stops,
    required this.maxSeats,
    required this.availableSeats,
    required this.totalFare,
    required this.riderFares,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  factory CarpoolRideModel.fromMap(Map<String, dynamic> map) {
    return CarpoolRideModel(
      id: map['id'] ?? '',
      driverId: map['driverId'] ?? '',
      riders: (map['riders'] as List<dynamic>?)
              ?.map((rider) => CarpoolRider.fromMap(rider))
              .toList() ??
          [],
      stops: (map['stops'] as List<dynamic>?)
              ?.map((stop) => CarpoolStop.fromMap(stop))
              .toList() ??
          [],
      maxSeats: map['maxSeats'] ?? 4,
      availableSeats: map['availableSeats'] ?? 4,
      totalFare: (map['totalFare'] ?? 0.0).toDouble(),
      riderFares: Map<String, double>.from(map['riderFares'] ?? {}),
      status: _getStatusFromString(map['status'] ?? 'pending'),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
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
      'driverId': driverId,
      'riders': riders.map((rider) => rider.toMap()).toList(),
      'stops': stops.map((stop) => stop.toMap()).toList(),
      'maxSeats': maxSeats,
      'availableSeats': availableSeats,
      'totalFare': totalFare,
      'riderFares': riderFares,
      'status': status.name,
      'createdAt': createdAt,
      'startedAt': startedAt,
      'completedAt': completedAt,
    };
  }

  static CarpoolStatus _getStatusFromString(String status) {
    switch (status) {
      case 'pending':
        return CarpoolStatus.pending;
      case 'active':
        return CarpoolStatus.active;
      case 'inProgress':
        return CarpoolStatus.inProgress;
      case 'completed':
        return CarpoolStatus.completed;
      case 'cancelled':
        return CarpoolStatus.cancelled;
      default:
        return CarpoolStatus.pending;
    }
  }

  CarpoolRideModel copyWith({
    String? id,
    String? driverId,
    List<CarpoolRider>? riders,
    List<CarpoolStop>? stops,
    int? maxSeats,
    int? availableSeats,
    double? totalFare,
    Map<String, double>? riderFares,
    CarpoolStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return CarpoolRideModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      riders: riders ?? this.riders,
      stops: stops ?? this.stops,
      maxSeats: maxSeats ?? this.maxSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      totalFare: totalFare ?? this.totalFare,
      riderFares: riderFares ?? this.riderFares,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class CarpoolRider {
  final String riderId;
  final String riderName;
  final String pickupAddress;
  final String dropoffAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final double fare;
  final CarpoolRiderStatus status;
  final DateTime joinedAt;

  CarpoolRider({
    required this.riderId,
    required this.riderName,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.fare,
    required this.status,
    required this.joinedAt,
  });

  factory CarpoolRider.fromMap(Map<String, dynamic> map) {
    return CarpoolRider(
      riderId: map['riderId'] ?? '',
      riderName: map['riderName'] ?? '',
      pickupAddress: map['pickupAddress'] ?? '',
      dropoffAddress: map['dropoffAddress'] ?? '',
      pickupLatitude: (map['pickupLatitude'] ?? 0.0).toDouble(),
      pickupLongitude: (map['pickupLongitude'] ?? 0.0).toDouble(),
      dropoffLatitude: (map['dropoffLatitude'] ?? 0.0).toDouble(),
      dropoffLongitude: (map['dropoffLongitude'] ?? 0.0).toDouble(),
      fare: (map['fare'] ?? 0.0).toDouble(),
      status: _getRiderStatusFromString(map['status'] ?? 'waiting'),
      joinedAt: map['joinedAt'] != null
          ? (map['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'dropoffLatitude': dropoffLatitude,
      'dropoffLongitude': dropoffLongitude,
      'fare': fare,
      'status': status.name,
      'joinedAt': joinedAt,
    };
  }

  static CarpoolRiderStatus _getRiderStatusFromString(String status) {
    switch (status) {
      case 'waiting':
        return CarpoolRiderStatus.waiting;
      case 'pickedUp':
        return CarpoolRiderStatus.pickedUp;
      case 'droppedOff':
        return CarpoolRiderStatus.droppedOff;
      default:
        return CarpoolRiderStatus.waiting;
    }
  }
}

class CarpoolStop {
  final String id;
  final String address;
  final double latitude;
  final double longitude;
  final StopType type; // pickup or dropoff
  final List<String> riderIds; // riders associated with this stop
  final int order; // order in the route

  CarpoolStop({
    required this.id,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.riderIds,
    required this.order,
  });

  factory CarpoolStop.fromMap(Map<String, dynamic> map) {
    return CarpoolStop(
      id: map['id'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      type: map['type'] == 'dropoff' ? StopType.dropoff : StopType.pickup,
      riderIds: List<String>.from(map['riderIds'] ?? []),
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'type': type == StopType.dropoff ? 'dropoff' : 'pickup',
      'riderIds': riderIds,
      'order': order,
    };
  }
}

enum CarpoolStatus {
  pending,
  active,
  inProgress,
  completed,
  cancelled,
}

enum CarpoolRiderStatus {
  waiting,
  pickedUp,
  droppedOff,
}

enum StopType {
  pickup,
  dropoff,
}
