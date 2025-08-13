import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class AuthService {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  final NotificationService _notificationService = NotificationService();

  AuthService() {
    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      print('Firebase services not available: $e');
    }
  }

  // Get current user
  User? get currentUser => _auth?.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? Stream.value(null);

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    if (_auth == null || _firestore == null) {
      throw Exception('Firebase services not available');
    }
    
    try {
      UserCredential userCredential = await _auth!
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Get FCM token for notifications
        final fcmToken = await _notificationService.getFCMToken();

        // Create user document in Firestore
        UserModel userModel = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          name: name,
          phone: phone,
          role: role,
          createdAt: DateTime.now(),
          fcmToken: fcmToken,
        );

        await _firestore!
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toMap());

        // Update display name
        await userCredential.user!.updateDisplayName(name);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_auth == null) {
      throw Exception('Firebase Auth not available');
    }
    
    try {
      return await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (_auth == null) {
      throw Exception('Firebase Auth not available');
    }
    await _auth!.signOut();
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    if (_firestore == null) {
      return null;
    }
    
    try {
      DocumentSnapshot doc = await _firestore!
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      // Error getting user data
      return null;
    }
  }

  // Stream user data
  Stream<UserModel?> getUserDataStream(String uid) {
    if (_firestore == null) {
      return Stream.value(null);
    }
    
    return _firestore!.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Update user data
  Future<void> updateUserData(UserModel user) async {
    if (_firestore == null) {
      throw Exception('Firestore not available');
    }
    
    try {
      await _firestore!.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      // Error updating user data
      rethrow;
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
