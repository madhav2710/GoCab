import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get currentContext => navigatorKey.currentContext;

  // Navigate to rider home screen
  static void goToRiderHome() {
    if (currentContext != null) {
      Navigator.of(currentContext!).pushNamedAndRemoveUntil(
        '/rider-home',
        (route) => false,
      );
    }
  }

  // Navigate to driver home screen
  static void goToDriverHome() {
    if (currentContext != null) {
      Navigator.of(currentContext!).pushNamedAndRemoveUntil(
        '/driver-home',
        (route) => false,
      );
    }
  }

  // Navigate back with confirmation
  static void goBackWithConfirmation({
    required String title,
    required String message,
    String confirmText = 'Exit',
    String cancelText = 'Cancel',
    Color confirmColor = Colors.red,
    VoidCallback? onConfirm,
  }) {
    if (currentContext == null) return;

    showDialog(
      context: currentContext!,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              if (onConfirm != null) {
                onConfirm();
              } else {
                Navigator.of(context).pop(); // Go back
              }
            },
            child: Text(
              confirmText,
              style: TextStyle(color: confirmColor),
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to ride tracking screen
  static void goToRideTracking(dynamic ride) {
    if (currentContext != null) {
      Navigator.of(currentContext!).push(
        MaterialPageRoute(
          builder: (context) => _getRideTrackingScreen(ride),
        ),
      );
    }
  }

  // Navigate to driver ride screen
  static void goToDriverRide(dynamic ride) {
    if (currentContext != null) {
      Navigator.of(currentContext!).push(
        MaterialPageRoute(
          builder: (context) => _getDriverRideScreen(ride),
        ),
      );
    }
  }

  // Get appropriate ride tracking screen based on user role
  static Widget _getRideTrackingScreen(dynamic ride) {
    // Import the screens dynamically to avoid circular imports
    return Container(); // Placeholder - will be implemented in main.dart
  }

  // Get appropriate driver ride screen
  static Widget _getDriverRideScreen(dynamic ride) {
    // Import the screens dynamically to avoid circular imports
    return Container(); // Placeholder - will be implemented in main.dart
  }

  // Show success message and navigate
  static void showSuccessAndNavigate({
    required String message,
    required VoidCallback onNavigate,
  }) {
    if (currentContext == null) return;

    ScaffoldMessenger.of(currentContext!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate after showing message
    Future.delayed(const Duration(milliseconds: 500), onNavigate);
  }

  // Show error message
  static void showError(String message) {
    if (currentContext == null) return;

    ScaffoldMessenger.of(currentContext!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
