import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'notification_manager.dart';
import 'notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationManager _notificationManager = NotificationManager();

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    try {
      _authService.authStateChanges.listen((User? user) {
        print('Auth state changed: ${user?.uid ?? 'null'}');
        _firebaseUser = user;
        if (user != null) {
          _loadUserData(user.uid);
        } else {
          _userModel = null;
        }
        notifyListeners();
      });
    } catch (e) {
      print('Firebase Auth not available: $e');
      // Set loading to false so the app can continue
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      _userModel = await _authService.getUserData(uid);

      // Update FCM token for the user
      await _updateFCMToken(uid);

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load user data';
      notifyListeners();
    }
  }

  Future<void> _updateFCMToken(String uid) async {
    try {
      // Get FCM token and update it for the user
      final notificationService = NotificationService();
      final token = await notificationService.getFCMToken();
      await _notificationManager.updateUserFCMToken(uid, token);
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
      );
      
      // Sign out after successful signup so user can manually sign in
      await signOut();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithEmail(email: email, password: password);
      
      // Manually update the authentication state
      _firebaseUser = _authService.currentUser;
      if (_firebaseUser != null) {
        await _loadUserData(_firebaseUser!.uid);
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _firebaseUser = null;
      _userModel = null;
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
