import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/ride_tracking_service.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverRideScreen extends StatefulWidget {
  final RideModel ride;

  const DriverRideScreen({
    super.key,
    required this.ride,
  });

  @override
  State<DriverRideScreen> createState() => _DriverRideScreenState();
}

class _DriverRideScreenState extends State<DriverRideScreen> {
  final RideTrackingService _trackingService = RideTrackingService();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  
  RideModel? _currentRide;
  UserModel? _rider;
  bool _isLoading = true;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _initializeRide();
  }

  void _initializeRide() {
    // Stream ride updates
    _trackingService.streamCurrentRide(widget.ride.riderId).listen((ride) {
      if (ride != null) {
        setState(() {
          _currentRide = ride;
        });
      }
    });

    // Get rider information
    _loadRiderInfo();
  }

  Future<void> _loadRiderInfo() async {
    try {
      // Get rider information from Firestore directly
      final riderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.ride.riderId)
          .get();
      
      if (riderDoc.exists) {
        final rider = UserModel.fromMap(riderDoc.data()!);
        setState(() {
          _rider = rider;
        });
      }
    } catch (e) {
      print('Error loading rider info: $e');
    }
  }

  Future<void> _updateMapMarkers() async {
    final markers = <Marker>{};
    
    // Add pickup marker
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(widget.ride.pickupLatitude, widget.ride.pickupLongitude),
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: widget.ride.pickupAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // Add dropoff marker
    markers.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(widget.ride.dropoffLatitude, widget.ride.dropoffLongitude),
        infoWindow: InfoWindow(
          title: 'Dropoff Location',
          snippet: widget.ride.dropoffAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _updateRideStatus(RideStatus status) async {
    try {
      await _trackingService.updateRideStatus(
        widget.ride.id,
        status,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ride status updated to ${status.toString().split('.').last}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating ride status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStatusText(RideStatus status) {
    switch (status) {
      case RideStatus.pending:
        return 'Pending';
      case RideStatus.accepted:
        return 'Accepted';
      case RideStatus.inProgress:
        return 'In Progress';
      case RideStatus.arrived:
        return 'Arrived';
      case RideStatus.pickupComplete:
        return 'Pickup Complete';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.pending:
        return Colors.orange;
      case RideStatus.accepted:
        return Colors.blue;
      case RideStatus.inProgress:
        return Colors.green;
      case RideStatus.arrived:
        return Colors.purple;
      case RideStatus.pickupComplete:
        return Colors.green;
      case RideStatus.completed:
        return Colors.grey;
      case RideStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionButton(RideStatus status, String text, IconData icon) {
    final currentStatus = _currentRide?.status ?? widget.ride.status;
    final isEnabled = _canTransitionToStatus(currentStatus, status);
    
    return Expanded(
      child: CustomButton(
        text: text,
        onPressed: isEnabled ? () => _updateRideStatus(status) : () {},
        isLoading: false,
      ),
    );
  }

  bool _canTransitionToStatus(RideStatus currentStatus, RideStatus targetStatus) {
    switch (currentStatus) {
      case RideStatus.accepted:
        return targetStatus == RideStatus.inProgress || targetStatus == RideStatus.arrived;
      case RideStatus.inProgress:
        return targetStatus == RideStatus.arrived;
      case RideStatus.arrived:
        return targetStatus == RideStatus.pickupComplete;
      case RideStatus.pickupComplete:
        return targetStatus == RideStatus.completed;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = _currentRide?.status ?? widget.ride.status;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ride Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map Section
                Expanded(
                  flex: 2,
                  child: GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _fitBounds();
                    },
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        widget.ride.pickupLatitude,
                        widget.ride.pickupLongitude,
                      ),
                      zoom: 15,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                  ),
                ),

                // Ride Details Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Header
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(currentStatus),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getStatusText(currentStatus),
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (_isTracking)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Live',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Rider Info
                      if (_rider != null) ...[
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                color: Theme.of(context).primaryColor,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _rider!.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Your passenger',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone, color: Colors.green),
                              onPressed: () {
                                // TODO: Implement call functionality
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Ride Details
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildLocationRow(
                              'Pickup',
                              widget.ride.pickupAddress,
                              Icons.location_on,
                              Colors.green,
                            ),
                            const SizedBox(height: 12),
                            _buildLocationRow(
                              'Dropoff',
                              widget.ride.dropoffAddress,
                              Icons.location_on,
                              Colors.red,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.attach_money, color: Colors.green, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fare',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        '\$${widget.ride.estimatedFare.toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      if (currentStatus == RideStatus.accepted) ...[
                        Row(
                          children: [
                            _buildActionButton(
                              RideStatus.arrived,
                              'Arrived',
                              Icons.location_on,
                            ),
                            const SizedBox(width: 12),
                            _buildActionButton(
                              RideStatus.inProgress,
                              'Start Trip',
                              Icons.play_arrow,
                            ),
                          ],
                        ),
                      ] else if (currentStatus == RideStatus.inProgress) ...[
                        Row(
                          children: [
                            _buildActionButton(
                              RideStatus.arrived,
                              'Arrived',
                              Icons.location_on,
                            ),
                          ],
                        ),
                      ] else if (currentStatus == RideStatus.arrived) ...[
                        Row(
                          children: [
                            _buildActionButton(
                              RideStatus.pickupComplete,
                              'Pickup Complete',
                              Icons.check_circle,
                            ),
                          ],
                        ),
                      ] else if (currentStatus == RideStatus.pickupComplete) ...[
                        Row(
                          children: [
                            _buildActionButton(
                              RideStatus.completed,
                              'Complete Trip',
                              Icons.flag,
                            ),
                          ],
                        ),
                      ] else if (currentStatus == RideStatus.completed) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Trip completed successfully!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLocationRow(String title, String address, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                address,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
                      ],
                    );
                  }

  void _fitBounds() {
    if (_mapController != null && _markers.isNotEmpty) {
      final bounds = _calculateBounds();
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    }
  }

  LatLngBounds _calculateBounds() {
    double? minLat, maxLat, minLng, maxLng;

    for (final marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      minLat = minLat == null ? lat : (minLat < lat ? minLat : lat);
      maxLat = maxLat == null ? lat : (maxLat > lat ? maxLat : lat);
      minLng = minLng == null ? lng : (minLng < lng ? minLng : lng);
      maxLng = maxLng == null ? lng : (maxLng > lng ? maxLng : lng);
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  @override
  void dispose() {
    // No need to dispose tracking service
    super.dispose();
  }
}
