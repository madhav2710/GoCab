import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ride_request_model.dart';
import '../services/ride_request_service.dart';

class RideRequestProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RideRequestModel? _currentRide;
  List<RideRequestModel> _pendingRideRequests = [];
  List<RideRequestModel> _rideHistory = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<RideRequestModel>>? _pendingRequestsSubscription;
  StreamSubscription<List<RideRequestModel>>? _rideHistorySubscription;
  StreamSubscription<List<RideRequestModel>>? _currentRideSubscription;
  StreamSubscription<RideRequestModel?>? _specificRideSubscription;
  bool _isCleanedUp = false;

  // Getters
  RideRequestModel? get currentRide => _currentRide;
  List<RideRequestModel> get pendingRideRequests => _pendingRideRequests;
  List<RideRequestModel> get rideHistory => _rideHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveRide => _currentRide?.isActive ?? false;

  // Constructor
  RideRequestProvider() {
    // No longer need to setup auth state listener here
    // The AuthProvider will handle cleanup when user signs out
  }

  // Initialize the provider
  void initialize() {
    final user = _auth.currentUser;
    if (user != null) {
      _isCleanedUp = false; // Reset cleanup flag when user signs in
      _loadCurrentRide();
      _loadRideHistory();
    }
  }

  // Setup auth state listener - removed, handled by AuthProvider

  // Dispose resources
  @override
  void dispose() {
    _pendingRequestsSubscription?.cancel();
    _rideHistorySubscription?.cancel();
    _currentRideSubscription?.cancel();
    _specificRideSubscription?.cancel();
    super.dispose();
  }

  // Load current active ride for the user
  Future<void> _loadCurrentRide() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _currentRideSubscription?.cancel();
      _currentRideSubscription =
          RideRequestService.streamRiderRideRequests(user.uid).listen(
            (rides) {
              // Find the most recent current ride (using stricter criteria)
              final currentRides = rides
                  .where((ride) => ride.isCurrentRide)
                  .toList();
              if (currentRides.isNotEmpty) {
                // Sort by creation date and get the most recent
                currentRides.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                _currentRide = currentRides.first;
                notifyListeners();
              } else {
                // No current rides
                _currentRide = null;
                notifyListeners();
              }
            },
            onError: (error) {
              debugPrint('❌ Error listening to current ride: $error');
              _setError('Failed to load current ride: $error');
            },
          );
    } catch (e) {
      debugPrint('❌ Error setting up current ride listener: $e');
      _setError('Failed to setup ride listener: $e');
    }
  }

  // Load ride history
  Future<void> _loadRideHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _rideHistorySubscription?.cancel();
      _rideHistorySubscription =
          RideRequestService.streamRiderRideRequests(user.uid).listen(
            (rides) {
              _rideHistory = rides;
              notifyListeners();
            },
            onError: (error) {
              debugPrint('❌ Error loading ride history: $error');
              _setError('Failed to load ride history: $error');
            },
          );
    } catch (e) {
      debugPrint('❌ Error setting up ride history listener: $e');
      _setError('Failed to setup ride history listener: $e');
    }
  }

  // Start listening to pending ride requests (for drivers)
  void startListeningToPendingRequests() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint(
        '❌ Cannot start listening to pending requests: User not authenticated',
      );
      return;
    }

    try {
      _pendingRequestsSubscription?.cancel();
      _pendingRequestsSubscription =
          RideRequestService.streamPendingRideRequests().listen(
            (requests) {
              // Filter out rides that this driver has already declined
              final filteredRequests = requests.where((request) {
                // Check if this driver has declined this ride
                final declinedDrivers = request.declinedDrivers ?? [];
                return !declinedDrivers.contains(user.uid);
              }).toList();

              _pendingRideRequests = filteredRequests;
              notifyListeners();

              debugPrint(
                '📋 Filtered pending requests: ${filteredRequests.length} (from ${requests.length} total)',
              );
            },
            onError: (error) {
              debugPrint('❌ Error listening to pending requests: $error');
              _setError('Failed to load pending requests: $error');
            },
          );
    } catch (e) {
      debugPrint('❌ Error setting up pending requests listener: $e');
      _setError('Failed to setup pending requests listener: $e');
    }
  }

  // Stop listening to pending ride requests
  void stopListeningToPendingRequests() {
    _pendingRequestsSubscription?.cancel();
    _pendingRideRequests = [];
    // Don't call notifyListeners() during dispose to avoid widget tree lock issues
  }

  // Refresh pending ride requests manually
  void refreshPendingRequests() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ Cannot refresh pending requests: User not authenticated');
      return;
    }

    debugPrint('🔄 Manually refreshing pending requests...');
    startListeningToPendingRequests();
  }

  // Create a new ride request (for riders)
  Future<String?> createRideRequest({
    required String pickupAddress,
    required String dropoffAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required double estimatedFare,
    required RideType rideType,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final rideId = await RideRequestService.createRideRequest(
        pickupAddress: pickupAddress,
        dropoffAddress: dropoffAddress,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        dropoffLatitude: dropoffLatitude,
        dropoffLongitude: dropoffLongitude,
        estimatedFare: estimatedFare,
        rideType: rideType,
      );

      if (rideId != null) {
        // Start listening to this specific ride
        listenToRideUpdates(rideId);
      }

      return rideId;
    } catch (e) {
      debugPrint('❌ Error creating ride request: $e');
      _setError('Failed to create ride request: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Listen to specific ride updates
  void listenToRideUpdates(String rideId) {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ Cannot listen to ride updates: User not authenticated');
      return;
    }

    _specificRideSubscription?.cancel();
    _specificRideSubscription = RideRequestService.streamRideRequest(rideId).listen(
      (ride) {
        if (ride != null) {
          debugPrint(
            '🎯 RideRequestProvider received update: ${ride.id} - Status: ${ride.status.name}',
          );
          _currentRide = ride;
          notifyListeners();

          // If ride is completed or cancelled, clear current ride after a delay
          if (ride.isCompleted || ride.isCancelled) {
            debugPrint(
              '🏁 Ride completed/cancelled, clearing current ride in 5 seconds',
            );
            Timer(const Duration(seconds: 5), () {
              _currentRide = null;
              notifyListeners();
            });
          }
        } else {
          debugPrint(
            '🎯 RideRequestProvider received null ride for ID: $rideId',
          );
        }
      },
      onError: (error) {
        debugPrint('❌ Error listening to ride updates: $error');
        _setError('Failed to track ride: $error');
      },
    );
  }

  // Accept a ride request (for drivers)
  Future<bool> acceptRideRequest({
    required String rideId,
    required String driverName,
    required String driverPhone,
    required String vehicleNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final success = await RideRequestService.acceptRideRequest(
        rideId: rideId,
        driverId: user.uid,
        driverName: driverName,
        driverPhone: driverPhone,
        vehicleNumber: vehicleNumber,
      );

      if (success) {
        // Remove from pending requests
        _pendingRideRequests.removeWhere((ride) => ride.id == rideId);
        notifyListeners();
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error accepting ride request: $e');
      _setError('Failed to accept ride request: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Decline a ride request (for drivers)
  Future<bool> declineRideRequest({
    required String rideId,
    String? declineReason,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final success = await RideRequestService.declineRideRequest(
        rideId: rideId,
        driverId: user.uid,
        declineReason: declineReason,
      );

      if (success) {
        // Remove from pending requests
        _pendingRideRequests.removeWhere((ride) => ride.id == rideId);
        notifyListeners();
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error declining ride request: $e');
      _setError('Failed to decline ride request: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update ride status
  Future<bool> updateRideStatus({
    required String rideId,
    required RideRequestStatus status,
    String? cancellationReason,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await RideRequestService.updateRideRequestStatus(
        rideId: rideId,
        status: status,
        cancellationReason: cancellationReason,
      );

      return success;
    } catch (e) {
      debugPrint('❌ Error updating ride status: $e');
      _setError('Failed to update ride status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cancel a ride request
  Future<bool> cancelRideRequest({
    required String rideId,
    required String cancellationReason,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final success = await RideRequestService.cancelRideRequest(
        rideId: rideId,
        cancelledBy: 'rider', // Could be determined based on user role
        cancellationReason: cancellationReason,
      );

      if (success) {
        _currentRide = null;
        notifyListeners();
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error cancelling ride request: $e');
      _setError('Failed to cancel ride request: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get current active ride
  Future<void> refreshCurrentRide() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final ride = await RideRequestService.getCurrentActiveRide(user.uid);
      _currentRide = ride;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing current ride: $e');
      _setError('Failed to refresh current ride: $e');
    }
  }

  // Clear current ride (for UI purposes)
  void clearCurrentRide() {
    _currentRide = null;
    notifyListeners();
  }

  // Clear all data and cancel listeners (for sign out)
  void clearAllData() {
    _clearAllDataAndListeners();
  }

  // Force cleanup - can be called from UI before sign out
  void forceCleanup() {
    debugPrint('🛑 Force cleanup requested');
    _clearAllDataAndListeners();
  }

  // Internal method to clear all data and listeners
  void _clearAllDataAndListeners() {
    if (_isCleanedUp) {
      debugPrint('🧹 RideRequestProvider already cleaned up, skipping');
      return;
    }

    _isCleanedUp = true;

    // Cancel all Firestore listeners IMMEDIATELY to prevent permission errors
    debugPrint('🛑 Cancelling all Firestore listeners...');
    _currentRideSubscription?.cancel();
    _pendingRequestsSubscription?.cancel();
    _rideHistorySubscription?.cancel();
    _specificRideSubscription?.cancel();

    // Clear all data
    _currentRide = null;
    _pendingRideRequests = [];
    _rideHistory = [];
    _isLoading = false;
    _error = null;

    // Reset subscriptions to null
    _currentRideSubscription = null;
    _pendingRequestsSubscription = null;
    _rideHistorySubscription = null;
    _specificRideSubscription = null;

    debugPrint('🧹 RideRequestProvider data and listeners cleared');
    notifyListeners();
  }

  // Helper methods
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

  // Get ride by ID
  RideRequestModel? getRideById(String rideId) {
    if (_currentRide?.id == rideId) return _currentRide;

    for (final ride in _rideHistory) {
      if (ride.id == rideId) return ride;
    }

    for (final ride in _pendingRideRequests) {
      if (ride.id == rideId) return ride;
    }

    return null;
  }

  // Check if user has any active rides
  bool get hasActiveRideAsRider {
    return _currentRide?.riderId == _auth.currentUser?.uid &&
        _currentRide?.isActive == true;
  }

  bool get hasActiveRideAsDriver {
    return _currentRide?.driverId == _auth.currentUser?.uid &&
        _currentRide?.isActive == true;
  }

  // Get pending requests count
  int get pendingRequestsCount => _pendingRideRequests.length;

  // Get recent rides count
  int get recentRidesCount => _rideHistory.length;
}
