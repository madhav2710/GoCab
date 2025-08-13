import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { rider, driver }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final UserRole role;
  final DateTime createdAt;
  final bool isActive;
  final bool? isAvailable;
  final double? latitude;
  final double? longitude;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.isActive = true,
    this.isAvailable = false,
    this.latitude,
    this.longitude,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] == 'driver' ? UserRole.driver : UserRole.rider,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
      isAvailable: map['isAvailable'] ?? false,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role == UserRole.driver ? 'driver' : 'rider',
      'createdAt': createdAt,
      'isActive': isActive,
      'isAvailable': isAvailable,
      'latitude': latitude,
      'longitude': longitude,
      'fcmToken': fcmToken,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    UserRole? role,
    DateTime? createdAt,
    bool? isActive,
    bool? isAvailable,
    double? latitude,
    double? longitude,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
