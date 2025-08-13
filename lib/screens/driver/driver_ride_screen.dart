import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/ride_tracking_service.dart';
import '../../services/location_service.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DriverRideScreen extends StatefulWidget {
  final RideModel ride;

  const DriverRideScreen({Key? key, required this.ride}) : super(key: key);

  @override
  State<DriverRideScreen> createState() => _DriverRideScreenState();
}

class _DriverRideScreenState extends State<DriverRideScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  RideModel? _currentRide;
  UserModel? _riderInfo;
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  bool _isTracking = false;
  Position? _currentPosition;
  Timer? _locationTimer;
  final RideTrackingService _trackingService = RideTrackingService();
  final LocationService _locationService = LocationService();
  StreamSubscription<RideModel?>? _rideSubscription;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _initializeRide();
    _startLocationTracking();
  }

  void _initializeRide() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      setState(() {
        _currentRide = widget.ride;
      });
      await _updateMapMarkers();
      await _loadRiderInfo();
      await _getRoutePolyline();

      // Listen to ride updates
      _rideSubscription = _trackingService
          .streamCurrentRide(widget.ride.riderId)
          .listen((ride) {
            if (ride != null && mounted) {
              setState(() {
                _currentRide = ride;
              });
              _updateMapMarkers();

              // Show feedback prompt when ride is completed
              if (ride.status == RideStatus.completed) {
                _showRideCompletedDialog();
              }
            }
          });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing ride: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading ride: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRiderInfo() async {
    try {
      final riderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.ride.riderId)
          .get();

      if (riderDoc.exists && mounted) {
        setState(() {
          _riderInfo = UserModel.fromMap(riderDoc.data()!);
        });
      }
    } catch (e) {
      print('Error loading rider info: $e');
    }
  }

  Future<void> _updateMapMarkers() async {
    if (_currentRide == null) return;

    final Set<Marker> markers = {};

    // Pickup marker
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          _currentRide!.pickupLatitude,
          _currentRide!.pickupLongitude,
        ),
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: _currentRide!.pickupAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // Dropoff marker
    markers.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(
          _currentRide!.dropoffLatitude,
          _currentRide!.dropoffLongitude,
        ),
        infoWindow: InfoWindow(
          title: 'Dropoff Location',
          snippet: _currentRide!.dropoffAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Driver's current position marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Driver',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(markers);
      });
      _fitBounds();
    }
  }

  Future<void> _getRoutePolyline() async {
    try {
      final String apiKey = 'AIzaSyCQ2xpJ042ReuzwhDtFXgwUBwjynHacdCw';
      final String origin =
          '${_currentRide!.pickupLatitude},${_currentRide!.pickupLongitude}';
      final String destination =
          '${_currentRide!.dropoffLatitude},${_currentRide!.dropoffLongitude}';

      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          final List<LatLng> polylineCoordinates = _decodePolyline(points);

          if (mounted) {
            setState(() {
              _polylines.clear();
              _polylines.add(
                Polyline(
                  polylineId: const PolylineId('route'),
                  color: Colors.blue,
                  points: polylineCoordinates,
                  width: 5,
                ),
              );
            });
          }
        }
      }
    } catch (e) {
      print('Error getting route: $e');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      final p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return poly;
  }

  void _startLocationTracking() async {
    try {
      // Get initial position
      _currentPosition = await _locationService.getCurrentLocation();
      if (_currentPosition != null) {
        _updateMapMarkers();
      }

      // Start continuous tracking
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10, // Update every 10 meters
            ),
          ).listen((Position position) {
            if (mounted) {
              setState(() {
                _currentPosition = position;
              });
              _updateMapMarkers();
              _updateDriverLocationInFirestore(position);
            }
          });
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }

  Future<void> _updateDriverLocationInFirestore(Position position) async {
    try {
      final user = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).firebaseUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      print('Error updating driver location: $e');
    }
  }

  void _fitBounds() {
    if (_mapController == null || _markers.isEmpty) return;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (Marker marker in _markers) {
      minLat = math.min(minLat, marker.position.latitude);
      maxLat = math.max(maxLat, marker.position.latitude);
      minLng = math.min(minLng, marker.position.longitude);
      maxLng = math.max(maxLng, marker.position.longitude);
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0, // padding
      ),
    );
  }

  Future<void> _updateRideStatus(RideStatus status) async {
    if (_isUpdatingStatus) return;
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await _trackingService.updateRideStatus(widget.ride.id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ride status updated to ${_getStatusText(status)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating ride status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
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

  String _getStatusText(RideStatus status) {
    switch (status) {
      case RideStatus.pending:
        return 'Pending';
      case RideStatus.accepted:
        return 'Accepted';
      case RideStatus.inProgress:
        return 'Started';
      case RideStatus.arrived:
        return 'Arrived';
      case RideStatus.pickupComplete:
        return 'Pickup Complete';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }

  void _showRideCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Ride Completed!',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'The ride has been completed successfully. Fare: \$${_currentRide?.estimatedFare.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to driver home
            },
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  double _calculateDistance() {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double lat1 = widget.ride.pickupLatitude * (math.pi / 180);
    final double lon1 = widget.ride.pickupLongitude * (math.pi / 180);
    final double lat2 = widget.ride.dropoffLatitude * (math.pi / 180);
    final double lon2 = widget.ride.dropoffLongitude * (math.pi / 180);

    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _positionSubscription?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading Ride...', style: GoogleFonts.poppins()),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Ride Details', style: GoogleFonts.poppins()),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _updateMapMarkers();
              _getRoutePolyline();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Section
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                  _fitBounds();
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    widget.ride.pickupLatitude != 0
                        ? widget.ride.pickupLatitude
                        : 37.7749,
                    widget.ride.pickupLongitude != 0
                        ? widget.ride.pickupLongitude
                        : -122.4194,
                  ),
                  zoom: 15,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
                trafficEnabled: true,
              ),
            ),
          ),

          // Ride Information Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                // Rider Info
                if (_riderInfo != null) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          _riderInfo!.name.isNotEmpty
                              ? _riderInfo!.name[0].toUpperCase()
                              : 'R',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Rider',
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Call feature coming soon!'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Ride Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildRideDetail(
                        'Pickup',
                        widget.ride.pickupAddress,
                        Icons.location_on,
                        Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildRideDetail(
                        'Dropoff',
                        widget.ride.dropoffAddress,
                        Icons.location_on,
                        Colors.red,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRideDetail(
                              'Distance',
                              '${_calculateDistance().toStringAsFixed(1)} km',
                              Icons.straighten,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildRideDetail(
                              'Fare',
                              '\$${widget.ride.estimatedFare.toStringAsFixed(2)}',
                              Icons.attach_money,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Status and Actions
                if (_currentRide != null) ...[
                  Text(
                    'Status: ${_getStatusText(_currentRide!.status)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(_currentRide!.status),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionButtons(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideDetail(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.pending:
        return Colors.orange;
      case RideStatus.accepted:
        return Colors.blue;
      case RideStatus.inProgress:
        return Colors.purple;
      case RideStatus.arrived:
        return Colors.indigo;
      case RideStatus.pickupComplete:
        return Colors.teal;
      case RideStatus.completed:
        return Colors.green;
      case RideStatus.cancelled:
        return Colors.red;
    }
  }

  Widget _buildActionButtons() {
    if (_currentRide == null) return const SizedBox.shrink();

    switch (_currentRide!.status) {
      case RideStatus.accepted:
        return Column(
          children: [
            _buildActionButton(
              'Start Trip',
              Icons.play_arrow,
              Colors.green,
              () => _updateRideStatus(RideStatus.inProgress),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              'Arrived at Pickup',
              Icons.location_on,
              Colors.blue,
              () => _updateRideStatus(RideStatus.arrived),
            ),
          ],
        );

      case RideStatus.inProgress:
        return _buildActionButton(
          'Arrived at Pickup',
          Icons.location_on,
          Colors.blue,
          () => _updateRideStatus(RideStatus.arrived),
        );

      case RideStatus.arrived:
        return _buildActionButton(
          'Pickup Complete',
          Icons.check_circle,
          Colors.green,
          () => _updateRideStatus(RideStatus.pickupComplete),
        );

      case RideStatus.pickupComplete:
        return _buildActionButton(
          'Complete Ride',
          Icons.flag,
          Colors.green,
          () => _updateRideStatus(RideStatus.completed),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUpdatingStatus ? null : onPressed,
        icon: _isUpdatingStatus
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: Colors.white),
        label: Text(
          _isUpdatingStatus ? 'Updating...' : text,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
