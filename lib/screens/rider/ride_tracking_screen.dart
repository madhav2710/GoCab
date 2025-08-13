import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/ride_tracking_service.dart';
import '../../services/feedback_service.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_button.dart';
import '../feedback/feedback_screen.dart';

class RideTrackingScreen extends StatefulWidget {
  final RideModel ride;

  const RideTrackingScreen({
    super.key,
    required this.ride,
  });

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  final RideTrackingService _trackingService = RideTrackingService();
  final FeedbackService _feedbackService = FeedbackService();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  RideModel? _currentRide;
  UserModel? _driver;
  Duration? _eta;
  bool _isLoading = true;
  bool _hasShownFeedbackPrompt = false;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  void _initializeTracking() {
    // Stream ride updates
    _trackingService.streamCurrentRide(widget.ride.riderId).listen((ride) {
      if (ride != null) {
        setState(() {
          _currentRide = ride;
        });
      }
    });

    // Stream driver location if driver is assigned
    if (widget.ride.driverId != null) {
      _trackingService.streamDriverLocation(widget.ride.driverId!).listen((driver) {
        if (driver != null) {
          setState(() {
            _driver = driver;
          });
          _updateETA();
        }
      });
    }
  }

  Future<void> _updateETA() async {
    if (_driver != null && _currentRide != null) {
      final eta = await _trackingService.calculateETA(
        _driver!.latitude!,
        _driver!.longitude!,
        _currentRide!.pickupLatitude,
        _currentRide!.pickupLongitude,
      );
      setState(() {
        _eta = eta;
      });
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

    // Add driver marker if available
    if (_driver?.latitude != null && _driver?.longitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(_driver!.latitude!, _driver!.longitude!),
          infoWindow: InfoWindow(
            title: 'Driver',
            snippet: _driver?.name ?? 'Your driver',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  String _getStatusMessage() {
    switch (_currentRide?.status ?? widget.ride.status) {
      case RideStatus.pending:
        return 'Looking for a driver...';
      case RideStatus.accepted:
        return 'Driver is on the way';
      case RideStatus.inProgress:
        return 'Trip in progress';
      case RideStatus.arrived:
        return 'Driver has arrived';
      case RideStatus.pickupComplete:
        return 'On the way to destination';
      case RideStatus.completed:
        return 'Trip completed';
      case RideStatus.cancelled:
        return 'Trip cancelled';
      default:
        return 'Unknown status';
    }
  }

  Color _getStatusColor() {
    switch (_currentRide?.status ?? widget.ride.status) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Track Your Ride',
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
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                  ),
                ),

                // Status Section
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
                              color: _getStatusColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getStatusMessage(),
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Driver Info
                      if (_driver != null) ...[
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
                                    _driver!.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Your driver',
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

                      // ETA and Fare Info
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              'ETA',
                              _eta != null 
                                  ? '${_eta!.inMinutes} min'
                                  : 'Calculating...',
                              Icons.access_time,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoCard(
                              'Fare',
                              '\$${widget.ride.estimatedFare.toStringAsFixed(2)}',
                              Icons.attach_money,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

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
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      if (_currentRide?.status == RideStatus.completed) ...[
                        CustomButton(
                          text: 'Rate Your Trip',
                          onPressed: () {
                            // TODO: Implement rating functionality
                          },
                          isLoading: false,
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Contact Driver',
                                onPressed: () {
                                  // TODO: Implement contact functionality
                                },
                                isLoading: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomButton(
                                text: 'Cancel Ride',
                                onPressed: () {
                                  _showCancelDialog();
                                },
                                isLoading: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
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

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Ride',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to cancel this ride?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelRide();
            },
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRide() async {
    try {
      await _trackingService.updateRideStatus(
        widget.ride.id,
        RideStatus.cancelled,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride cancelled successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling ride: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFeedbackPrompt() {
    setState(() {
      _hasShownFeedbackPrompt = true;
    });

    // Check if user has already rated this ride
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) return;

    _feedbackService.hasUserRatedRide(widget.ride.id, currentUser.uid).then((hasRated) {
      if (!hasRated && mounted) {
        _showFeedbackDialog();
      }
    });
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Rate Your Ride',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'How was your experience with this ride? Your feedback helps improve our service.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Skip',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FeedbackScreen(
                    ride: widget.ride,
                    otherUser: _driver,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Rate Now',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // No need to dispose tracking service
    super.dispose();
  }
}
