import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/ride_tracking_service.dart';
import '../../services/navigation_service.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../utils/color_utils.dart';

class DriverRideScreenSimple extends StatefulWidget {
  final RideModel ride;

  const DriverRideScreenSimple({super.key, required this.ride});

  @override
  State<DriverRideScreenSimple> createState() => _DriverRideScreenSimpleState();
}

class _DriverRideScreenSimpleState extends State<DriverRideScreenSimple> {
  RideModel? _currentRide;
  UserModel? _riderInfo;
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  final RideTrackingService _trackingService = RideTrackingService();
  StreamSubscription<RideModel?>? _rideSubscription;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load rider information
      await _loadRiderInfo();

      // Listen to ride updates
      _rideSubscription = _trackingService
          .streamRideUpdates(widget.ride.id)
          .listen((ride) {
            if (mounted && ride != null) {
              setState(() {
                _currentRide = ride;
              });
            }
          });

      setState(() {
        _currentRide = widget.ride;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing tracking: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRiderInfo() async {
    try {
      final riderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.ride.riderId)
          .get();

      if (riderDoc.exists) {
        setState(() {
          _riderInfo = UserModel.fromMap(riderDoc.data()!);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading rider info: $e');
      }
    }
  }

  Future<void> _updateRideStatus(RideStatus newStatus) async {
    if (_isUpdatingStatus) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await _trackingService.updateRideStatus(widget.ride.id, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ride status updated to ${newStatus.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update ride status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  Future<void> _startTrip() async {
    await _updateRideStatus(RideStatus.inProgress);

    if (mounted) {
      _showTripStartedDialog();
    }
  }

  void _showTripStartedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Trip Started!',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Navigate to pickup location:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _currentRide?.pickupAddress ?? 'Unknown',
              style: GoogleFonts.poppins(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Then proceed to destination:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _currentRide?.dropoffAddress ?? 'Unknown',
              style: GoogleFonts.poppins(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Got it!',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeTrip() async {
    await _updateRideStatus(RideStatus.completed);

    if (mounted) {
      NavigationService.showSuccessAndNavigate(
        message: 'Trip completed successfully!',
        onNavigate: () => NavigationService.goToDriverHome(),
      );
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Exit Ride?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to exit this ride? The ride will remain active.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: Text(
              'Exit',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_currentRide == null) return const SizedBox.shrink();

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_currentRide!.status) {
      case RideStatus.accepted:
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        statusText = 'Ride Accepted';
        break;
      case RideStatus.arrived:
        statusColor = Colors.orange;
        statusIcon = Icons.location_on;
        statusText = 'Arrived at Pickup';
        break;
      case RideStatus.inProgress:
        statusColor = Colors.green;
        statusIcon = Icons.directions_car;
        statusText = 'Trip in Progress';
        break;
      case RideStatus.pickupComplete:
        statusColor = Colors.purple;
        statusIcon = Icons.person;
        statusText = 'Passenger Picked Up';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Unknown Status';
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fare: ₹${_currentRide!.estimatedFare.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiderInfo() {
    if (_riderInfo == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Passenger Details',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    _riderInfo!.name.isNotEmpty
                        ? _riderInfo!.name[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _riderInfo!.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _riderInfo!.phone,
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(String title, String address, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(address, style: GoogleFonts.poppins(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_currentRide == null) return const SizedBox.shrink();

    List<Widget> buttons = [];

    switch (_currentRide!.status) {
      case RideStatus.accepted:
        buttons.addAll([
          ElevatedButton.icon(
            onPressed: _isUpdatingStatus
                ? null
                : () => _updateRideStatus(RideStatus.arrived),
            icon: const Icon(Icons.location_on),
            label: const Text('Mark Arrived'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isUpdatingStatus ? null : _startTrip,
            icon: const Icon(Icons.directions_car),
            label: const Text('Start Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ]);
        break;
      case RideStatus.arrived:
        buttons.addAll([
          ElevatedButton.icon(
            onPressed: _isUpdatingStatus
                ? null
                : () => _updateRideStatus(RideStatus.pickupComplete),
            icon: const Icon(Icons.person),
            label: const Text('Passenger Picked Up'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ]);
        break;
      case RideStatus.pickupComplete:
        buttons.addAll([
          ElevatedButton.icon(
            onPressed: _isUpdatingStatus ? null : _completeTrip,
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ]);
        break;
      case RideStatus.inProgress:
        buttons.addAll([
          ElevatedButton.icon(
            onPressed: _isUpdatingStatus
                ? null
                : () => _updateRideStatus(RideStatus.pickupComplete),
            icon: const Icon(Icons.person),
            label: const Text('Passenger Picked Up'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isUpdatingStatus ? null : _completeTrip,
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ]);
        break;
      default:
        break;
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Ride Details',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ride Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _showExitConfirmation();
          },
        ),
        actions: [
          if (_isUpdatingStatus)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusCard(),
            _buildRiderInfo(),
            _buildLocationCard(
              'Pickup Location',
              _currentRide?.pickupAddress ?? 'Unknown',
              Icons.location_on,
            ),
            _buildLocationCard(
              'Destination',
              _currentRide?.dropoffAddress ?? 'Unknown',
              Icons.flag,
            ),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
