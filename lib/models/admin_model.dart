import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminRole { super_admin, admin, moderator }

class AdminModel {
  final String id;
  final String email;
  final String name;
  final AdminRole role;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isActive;

  AdminModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.permissions,
    required this.createdAt,
    required this.lastLoginAt,
    this.isActive = true,
  });

  factory AdminModel.fromMap(Map<String, dynamic> map, String id) {
    return AdminModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: _getRoleFromString(map['role'] ?? 'admin'),
      permissions: List<String>.from(map['permissions'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (map['lastLoginAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.name,
      'permissions': permissions,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isActive': isActive,
    };
  }

  static AdminRole _getRoleFromString(String role) {
    switch (role) {
      case 'super_admin':
        return AdminRole.super_admin;
      case 'moderator':
        return AdminRole.moderator;
      default:
        return AdminRole.admin;
    }
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission) || role == AdminRole.super_admin;
  }
}

class SystemConfig {
  final String id;
  final String key;
  final dynamic value;
  final String description;
  final String category;
  final DateTime updatedAt;
  final String updatedBy;

  SystemConfig({
    required this.id,
    required this.key,
    required this.value,
    required this.description,
    required this.category,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory SystemConfig.fromMap(Map<String, dynamic> map, String id) {
    return SystemConfig(
      id: id,
      key: map['key'] ?? '',
      value: map['value'],
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      updatedBy: map['updatedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
      'description': description,
      'category': category,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }
}

class ComplaintModel {
  final String id;
  final String userId;
  final String userRole; // 'rider' or 'driver'
  final String complaintType;
  final String title;
  final String description;
  final String? rideId;
  final String? relatedUserId;
  final List<String> attachments;
  final ComplaintStatus status;
  final ComplaintPriority priority;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolution;
  final List<ComplaintNote> notes;

  ComplaintModel({
    required this.id,
    required this.userId,
    required this.userRole,
    required this.complaintType,
    required this.title,
    required this.description,
    this.rideId,
    this.relatedUserId,
    required this.attachments,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolution,
    required this.notes,
  });

  factory ComplaintModel.fromMap(Map<String, dynamic> map, String id) {
    return ComplaintModel(
      id: id,
      userId: map['userId'] ?? '',
      userRole: map['userRole'] ?? '',
      complaintType: map['complaintType'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      rideId: map['rideId'],
      relatedUserId: map['relatedUserId'],
      attachments: List<String>.from(map['attachments'] ?? []),
      status: _getStatusFromString(map['status'] ?? 'open'),
      priority: _getPriorityFromString(map['priority'] ?? 'medium'),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      resolvedAt: map['resolvedAt'] != null
          ? (map['resolvedAt'] as Timestamp).toDate()
          : null,
      resolvedBy: map['resolvedBy'],
      resolution: map['resolution'],
      notes:
          (map['notes'] as List<dynamic>?)
              ?.map((note) => ComplaintNote.fromMap(note))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userRole': userRole,
      'complaintType': complaintType,
      'title': title,
      'description': description,
      'rideId': rideId,
      'relatedUserId': relatedUserId,
      'attachments': attachments,
      'status': status.name,
      'priority': priority.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
      'resolution': resolution,
      'notes': notes.map((note) => note.toMap()).toList(),
    };
  }

  static ComplaintStatus _getStatusFromString(String status) {
    switch (status) {
      case 'resolved':
        return ComplaintStatus.resolved;
      case 'in_progress':
        return ComplaintStatus.inProgress;
      case 'closed':
        return ComplaintStatus.closed;
      default:
        return ComplaintStatus.open;
    }
  }

  static ComplaintPriority _getPriorityFromString(String priority) {
    switch (priority) {
      case 'high':
        return ComplaintPriority.high;
      case 'low':
        return ComplaintPriority.low;
      default:
        return ComplaintPriority.medium;
    }
  }

  ComplaintModel copyWith({
    String? id,
    String? userId,
    String? userRole,
    String? complaintType,
    String? title,
    String? description,
    String? rideId,
    String? relatedUserId,
    List<String>? attachments,
    ComplaintStatus? status,
    ComplaintPriority? priority,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? resolution,
    List<ComplaintNote>? notes,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      complaintType: complaintType ?? this.complaintType,
      title: title ?? this.title,
      description: description ?? this.description,
      rideId: rideId ?? this.rideId,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolution: resolution ?? this.resolution,
      notes: notes ?? this.notes,
    );
  }
}

enum ComplaintStatus { open, inProgress, resolved, closed }

enum ComplaintPriority { low, medium, high }

class ComplaintNote {
  final String id;
  final String adminId;
  final String adminName;
  final String note;
  final DateTime createdAt;
  final bool isInternal;

  ComplaintNote({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.note,
    required this.createdAt,
    this.isInternal = false,
  });

  factory ComplaintNote.fromMap(Map<String, dynamic> map) {
    return ComplaintNote(
      id: map['id'] ?? '',
      adminId: map['adminId'] ?? '',
      adminName: map['adminName'] ?? '',
      note: map['note'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isInternal: map['isInternal'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adminId': adminId,
      'adminName': adminName,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'isInternal': isInternal,
    };
  }
}
