import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/carpool_service.dart';
import '../../services/ride_tracking_service.dart';
import '../../models/carpool_ride_model.dart';
import '../../widgets/carpool_riders_widget.dart';
import '../../widgets/custom_button.dart';

class CarpoolTrackingScreen extends StatefulWidget {
  final CarpoolRideModel carpoolRide;

  const CarpoolTrackingScreen({
    super.key,
    required this.carpoolRide,
  });

  @override
  State<CarpoolTrackingScreen> createState() => _CarpoolTrackingScreenState();
}

class _CarpoolTrackingScreenState extends State<CarpoolTrackingScreen> {
  final CarpoolService _carpoolService = CarpoolService();
  final RideTrackingService _trackingService = RideTrackingService();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  
  CarpoolRideModel? _currentCarpoolRide;
  bool _isLoading = true;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _initializeCarpoolTracking();
  }

  Future<void> _initializeCarpoolTracking() async {
    try {
      // Start location tracking
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.userModel;
      
      if (user != null) {
        await _trackingService.startLocationTracking(user.uid);
        setState(() {
          _isTracking = true;
        });
      }

      // Listen to carpool ride updates
      _carpoolService.getCarpoolRideStream(widget.carpoolRide.id).listen((carpoolRide) {
        setState(() {
          _currentCarpoolRide = carpoolRide;
        });
        _updateMapMarkers();
      });

      // Initial setup
      await _updateMapMarkers();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing carpool tracking: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateMapMarkers() async {
    final markers = <Marker>{};
    final carpoolRide = _currentCarpoolRide ?? widget.carpoolRide;
    
    // Add pickup and dropoff markers for all stops
    for (int i = 0; i < carpoolRide.stops.length; i++) {
      final stop = carpoolRide.stops[i];
      final isPickup = stop.type == StopType.pickup;
      
      markers.add(
        Marker(
          markerId: MarkerId('stop_${stop.id}'),
          position: LatLng(stop.latitude, stop.longitude),
          infoWindow: InfoWindow(
            title: isPickup ? 'Pickup ${i + 1}' : 'Dropoff ${i + 1}',
            snippet: stop.address,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isPickup ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _updateCarpoolStatus(CarpoolStatus status) async {
    try {
      await _carpoolService.updateCarpoolRideStatus(
        carpoolRideId: widget.carpoolRide.id,
        status: status,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Carpool status updated to ${_getStatusText(status)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateRiderStatus(String riderId, CarpoolRiderStatus status) async {
    try {
      await _carpoolService.updateRiderStatus(
        carpoolRideId: widget.carpoolRide.id,
        riderId: riderId,
        status: status,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rider status updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update rider status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStatusText(CarpoolStatus status) {
    switch (status) {
      case CarpoolStatus.pending:
        return 'Pending';
      case CarpoolStatus.active:
        return 'Active';
      case CarpoolStatus.inProgress:
        return 'In Progress';
      case CarpoolStatus.completed:
        return 'Completed';
      case CarpoolStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(CarpoolStatus status) {
    switch (status) {
      case CarpoolStatus.pending:
        return Colors.orange;
      case CarpoolStatus.active:
        return Colors.blue;
      case CarpoolStatus.inProgress:
        return Colors.green;
      case CarpoolStatus.completed:
        return Colors.grey;
      case CarpoolStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final carpoolRide = _currentCarpoolRide ?? widget.carpoolRide;
    final currentStatus = carpoolRide.status;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Carpool Ride',
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
                        carpoolRide.stops.first.latitude,
                        carpoolRide.stops.first.longitude,
                      ),
                      zoom: 15,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                  ),
                ),

                // Carpool Details Section
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

                      // Carpool Riders Widget
                      CarpoolRidersWidget(
                        riders: carpoolRide.riders,
                        stops: carpoolRide.stops,
                        maxSeats: carpoolRide.maxSeats,
                        availableSeats: carpoolRide.availableSeats,
                        riderFares: carpoolRide.riderFares,
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      if (currentStatus == CarpoolStatus.active) ...[
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Start Trip',
                                onPressed: () => _updateCarpoolStatus(CarpoolStatus.inProgress),
                                isLoading: false,
                              ),
                            ),
                          ],
                        ),
                      ] else if (currentStatus == CarpoolStatus.inProgress) ...[
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Complete Trip',
                                onPressed: () => _updateCarpoolStatus(CarpoolStatus.completed),
                                isLoading: false,
                              ),
                            ),
                          ],
                        ),
                      ] else if (currentStatus == CarpoolStatus.completed) ...[
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
                                  'Carpool trip completed successfully!',
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
    // Stop location tracking
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user != null) {
      _trackingService.stopLocationTracking(user.uid);
    }
    _trackingService.dispose();
    super.dispose();
  }
}
