import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  // Admin Authentication
  Future<bool> isAdmin(String email) async {
    try {
      final adminDoc = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .where('isActive', isEqualTo: true)
          .get();

      return adminDoc.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getAdminData(String email) async {
    try {
      final adminDoc = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .get();

      if (adminDoc.docs.isNotEmpty) {
        final data = adminDoc.docs.first.data();
        data['id'] = adminDoc.docs.first.id;
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting admin data: $e');
      return null;
    }
  }

  Future<void> updateLastLogin(String adminId) async {
    try {
      await _firestore.collection('admins').doc(adminId).update({
        'lastLoginAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error updating last login: $e');
    }
  }

  // User Management
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<UserModel>> getUsersByRole(UserRole role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
      });
    } catch (e) {
      debugPrint('Error updating user status: $e');
      throw Exception('Failed to update user status');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      throw Exception('Failed to delete user');
    }
  }

  // Ride Analytics
  Stream<QuerySnapshot> getRidesStream() {
    return _firestore
        .collection('rides')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>> getRideAnalytics() async {
    try {
      final ridesSnapshot = await _firestore.collection('rides').get();
      final rides = ridesSnapshot.docs;

      final totalRides = rides.length;
      final completedRides = rides
          .where((ride) => ride.data()['status'] == 'completed')
          .length;
      final cancelledRides = rides
          .where((ride) => ride.data()['status'] == 'cancelled')
          .length;
      final pendingRides = rides
          .where((ride) => ride.data()['status'] == 'pending')
          .length;

      double totalRevenue = 0;
      for (final ride in rides) {
        final actualFare = ride.data()['actualFare'];
        if (actualFare != null && ride.data()['status'] == 'completed') {
          totalRevenue += (actualFare as num).toDouble();
        }
      }

      return {
        'totalRides': totalRides,
        'completedRides': completedRides,
        'cancelledRides': cancelledRides,
        'pendingRides': pendingRides,
        'totalRevenue': totalRevenue,
        'completionRate': totalRides > 0
            ? (completedRides / totalRides) * 100
            : 0,
      };
    } catch (e) {
      debugPrint('Error getting ride analytics: $e');
      return {};
    }
  }

  // System Configuration
  Future<List<Map<String, dynamic>>> getSystemConfigs() async {
    try {
      final configsSnapshot = await _firestore
          .collection('system_configs')
          .get();
      return configsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting system configs: $e');
      return [];
    }
  }

  Future<void> updateSystemConfig(
    String configId,
    dynamic value,
    String updatedBy,
  ) async {
    try {
      await _firestore.collection('system_configs').doc(configId).update({
        'value': value,
        'updatedAt': Timestamp.now(),
        'updatedBy': updatedBy,
      });
    } catch (e) {
      debugPrint('Error updating system config: $e');
      throw Exception('Failed to update system configuration');
    }
  }

  // Dashboard Statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final ridesSnapshot = await _firestore.collection('rides').get();
      final feedbackSnapshot = await _firestore.collection('feedback').get();

      final totalUsers = usersSnapshot.docs.length;
      final totalRiders = usersSnapshot.docs
          .where((doc) => doc.data()['role'] == 'rider')
          .length;
      final totalDrivers = usersSnapshot.docs
          .where((doc) => doc.data()['role'] == 'driver')
          .length;
      final totalRides = ridesSnapshot.docs.length;
      final totalFeedback = feedbackSnapshot.docs.length;

      // Calculate average rating
      double totalRating = 0;
      int ratingCount = 0;
      for (final feedback in feedbackSnapshot.docs) {
        final rating = feedback.data()['rating'] as int?;
        if (rating != null) {
          totalRating += rating;
          ratingCount++;
        }
      }
      final averageRating = ratingCount > 0 ? totalRating / ratingCount : 0;

      return {
        'totalUsers': totalUsers,
        'totalRiders': totalRiders,
        'totalDrivers': totalDrivers,
        'totalRides': totalRides,
        'totalFeedback': totalFeedback,
        'averageRating': averageRating,
      };
    } catch (e) {
      debugPrint('Error getting dashboard stats: $e');
      return {};
    }
  }
}
