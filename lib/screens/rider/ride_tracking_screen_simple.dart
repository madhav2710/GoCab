import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import '../../services/auth_provider.dart';
import '../../services/ride_tracking_service.dart';
import '../../services/navigation_service.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
// import '../../utils/color_utils.dart';

class RideTrackingScreenSimple extends StatefulWidget {
  final RideModel ride;

  const RideTrackingScreenSimple({super.key, required this.ride});

  @override
  State<RideTrackingScreenSimple> createState() =>
      _RideTrackingScreenSimpleState();
}

class _RideTrackingScreenSimpleState extends State<RideTrackingScreenSimple> {
  RideModel? _currentRide;
  UserModel? _driverInfo;
  bool _isLoading = true;
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

      // Load driver information
      await _loadDriverInfo();

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

  Future<void> _loadDriverInfo() async {
    try {
      if (widget.ride.driverId != null) {
        final driverDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.ride.driverId!)
            .get();

        if (driverDoc.exists) {
          setState(() {
            _driverInfo = UserModel.fromMap(driverDoc.data()!);
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading driver info: $e');
      }
    }
  }

  Future<void> _cancelRide() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Ride',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to cancel this ride?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _trackingService.updateRideStatus(
          widget.ride.id,
          RideStatus.cancelled,
        );

        if (mounted) {
          NavigationService.showSuccessAndNavigate(
            message: 'Ride cancelled successfully',
            onNavigate: () => NavigationService.goToRiderHome(),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel ride: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Exit Tracking?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to exit ride tracking? You can still track your ride from the home screen.',
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
                color: Colors.blue,
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
    String statusDescription;

    switch (_currentRide!.status) {
      case RideStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Looking for Driver';
        statusDescription = 'We are finding the best driver for you';
        break;
      case RideStatus.accepted:
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        statusText = 'Driver Assigned';
        statusDescription = 'Your driver is on the way';
        break;
      case RideStatus.arrived:
        statusColor = Colors.green;
        statusIcon = Icons.location_on;
        statusText = 'Driver Arrived';
        statusDescription = 'Your driver has arrived at pickup location';
        break;
      case RideStatus.inProgress:
        statusColor = Colors.purple;
        statusIcon = Icons.directions_car;
        statusText = 'Trip in Progress';
        statusDescription = 'Enjoy your ride!';
        break;
      case RideStatus.pickupComplete:
        statusColor = Colors.indigo;
        statusIcon = Icons.person;
        statusText = 'On the Way';
        statusDescription = 'Heading to your destination';
        break;
      case RideStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Trip Completed';
        statusDescription = 'Thank you for using GoCab!';
        break;
      case RideStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Ride Cancelled';
        statusDescription = 'This ride has been cancelled';
        break;
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
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
                        statusDescription,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fare: ₹${_currentRide!.estimatedFare.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                if (_currentRide!.status != RideStatus.completed &&
                    _currentRide!.status != RideStatus.cancelled)
                  TextButton.icon(
                    onPressed: _cancelRide,
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfo() {
    if (_driverInfo == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver Details',
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
                    _driverInfo!.name.isNotEmpty
                        ? _driverInfo!.name[0].toUpperCase()
                        : 'D',
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
                        _driverInfo!.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _driverInfo!.phone,
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                      if (_driverInfo!.vehicleNumber != null)
                        Text(
                          'Vehicle: ${_driverInfo!.vehicleNumber}',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Implement call functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Call functionality not implemented'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone, color: Colors.green),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Track Ride',
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
          'Track Ride',
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusCard(),
            if (_currentRide?.status != RideStatus.pending) _buildDriverInfo(),
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
          ],
        ),
      ),
    );
  }
}
