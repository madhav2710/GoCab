import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/ride_tracking_service.dart';
import '../../services/location_service.dart';
import '../../models/carpool_ride_model.dart';
import '../../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CarpoolTrackingScreen extends StatefulWidget {
  final CarpoolRideModel carpoolRide;

  const CarpoolTrackingScreen({Key? key, required this.carpoolRide}) : super(key: key);

  @override
  State<CarpoolTrackingScreen> createState() => _CarpoolTrackingScreenState();
}

class _CarpoolTrackingScreenState extends State<CarpoolTrackingScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  CarpoolRideModel? _currentCarpoolRide;
  List<UserModel> _riders = [];
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  Position? _currentPosition;
  final RideTrackingService _trackingService = RideTrackingService();
  final LocationService _locationService = LocationService();
  StreamSubscription<Position>? _positionSubscription;
  int _currentStopIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCarpoolRide();
    _startLocationTracking();
  }

  void _initializeCarpoolRide() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    
    try {
      setState(() { _currentCarpoolRide = widget.carpoolRide; });
      await _loadRiders();
      await _updateMapMarkers();
      await _getRoutePolyline();
      
      if (mounted) { setState(() { _isLoading = false; }); }
    } catch (e) {
      print('Error initializing carpool ride: $e');
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading carpool ride: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadRiders() async {
    try {
      final riders = <UserModel>[];
      for (CarpoolRider rider in widget.carpoolRide.riders) {
        final riderDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(rider.riderId)
            .get();
        
        if (riderDoc.exists) {
          riders.add(UserModel.fromMap(riderDoc.data()!));
        }
      }
      
      if (mounted) {
        setState(() { _riders = riders; });
      }
    } catch (e) {
      print('Error loading riders: $e');
    }
  }

  Future<void> _updateMapMarkers() async {
    if (_currentCarpoolRide == null) return;
    
    final Set<Marker> markers = {};
    
    // Driver's current position marker
    if (_currentPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Driver',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }
    
    // Add markers for each stop
    for (int i = 0; i < _currentCarpoolRide!.stops.length; i++) {
      final stop = _currentCarpoolRide!.stops[i];
      markers.add(Marker(
        markerId: MarkerId('stop_$i'),
        position: LatLng(stop.latitude, stop.longitude),
        infoWindow: InfoWindow(
          title: 'Stop ${i + 1}',
          snippet: stop.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          i == _currentStopIndex ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
        ),
      ));
    }
    
    if (mounted) {
      setState(() { _markers.clear(); _markers.addAll(markers); });
      _fitBounds();
    }
  }

  Future<void> _getRoutePolyline() async {
    try {
      if (_currentCarpoolRide!.stops.isEmpty) return;
      
      final String apiKey = 'AIzaSyCQ2xpJ042ReuzwhDtFXgwUBwjynHacdCw';
      final List<LatLng> allPoints = [];
      
      // Create route through all stops
      for (int i = 0; i < _currentCarpoolRide!.stops.length - 1; i++) {
        final origin = '${_currentCarpoolRide!.stops[i].latitude},${_currentCarpoolRide!.stops[i].longitude}';
        final destination = '${_currentCarpoolRide!.stops[i + 1].latitude},${_currentCarpoolRide!.stops[i + 1].longitude}';
        
        final response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey'
        ));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['routes'] != null && data['routes'].isNotEmpty) {
            final points = data['routes'][0]['overview_polyline']['points'];
            final List<LatLng> polylineCoordinates = _decodePolyline(points);
            allPoints.addAll(polylineCoordinates);
          }
        }
      }
      
      if (mounted && allPoints.isNotEmpty) {
        setState(() {
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: const PolylineId('carpool_route'),
            color: Colors.purple,
            points: allPoints,
            width: 5,
          ));
        });
      }
    } catch (e) {
      print('Error getting carpool route: $e');
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
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() { _currentPosition = position; });
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
      final user = Provider.of<AuthProvider>(context, listen: false).firebaseUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
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
    
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      50.0, // padding
    ));
  }

  Future<void> _updateCarpoolStatus(CarpoolStatus status) async {
    if (_isUpdatingStatus) return;
    setState(() { _isUpdatingStatus = true; });
    
    try {
      await FirebaseFirestore.instance
          .collection('carpool_rides')
          .doc(widget.carpoolRide.id)
          .update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Carpool status updated to ${_getStatusText(status)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating carpool status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) { setState(() { _isUpdatingStatus = false; }); }
    }
  }

  String _getStatusText(CarpoolStatus status) {
    switch (status) {
      case CarpoolStatus.pending: return 'Pending';
      case CarpoolStatus.active: return 'Active';
      case CarpoolStatus.inProgress: return 'In Progress';
      case CarpoolStatus.completed: return 'Completed';
      case CarpoolStatus.cancelled: return 'Cancelled';
    }
  }

  void _nextStop() {
    if (_currentStopIndex < _currentCarpoolRide!.stops.length - 1) {
      setState(() { _currentStopIndex++; });
      _updateMapMarkers();
    }
  }

  void _previousStop() {
    if (_currentStopIndex > 0) {
      setState(() { _currentStopIndex--; });
      _updateMapMarkers();
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading Carpool...', style: GoogleFonts.poppins()),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Carpool Ride', style: GoogleFonts.poppins()),
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
                  target: _currentCarpoolRide!.stops.isNotEmpty
                    ? LatLng(_currentCarpoolRide!.stops[0].latitude, _currentCarpoolRide!.stops[0].longitude)
                    : const LatLng(37.7749, -122.4194),
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
          
          // Carpool Information Section
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
                // Current Stop Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.purple[700], size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Stop: ${_currentStopIndex + 1}/${_currentCarpoolRide!.stops.length}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple[700],
                              ),
                            ),
                            if (_currentCarpoolRide!.stops.isNotEmpty)
                              Text(
                                _currentCarpoolRide!.stops[_currentStopIndex].address,
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
                ),
                
                const SizedBox(height: 16),
                
                // Riders List
                Text(
                  'Passengers (${_riders.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _riders.length,
                    itemBuilder: (context, index) {
                      final rider = _riders[index];
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                rider.name.isNotEmpty ? rider.name[0].toUpperCase() : 'R',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rider.name,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Navigation Controls
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _currentStopIndex > 0 ? _previousStop : null,
                        icon: const Icon(Icons.arrow_back),
                        label: Text('Previous Stop', style: GoogleFonts.poppins()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _currentStopIndex < _currentCarpoolRide!.stops.length - 1 ? _nextStop : null,
                        icon: const Icon(Icons.arrow_forward),
                        label: Text('Next Stop', style: GoogleFonts.poppins()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Status Actions
                if (_currentCarpoolRide != null) ...[
                  Text(
                    'Status: ${_getStatusText(_currentCarpoolRide!.status)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(_currentCarpoolRide!.status),
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

  Color _getStatusColor(CarpoolStatus status) {
    switch (status) {
      case CarpoolStatus.pending: return Colors.orange;
      case CarpoolStatus.active: return Colors.blue;
      case CarpoolStatus.inProgress: return Colors.green;
      case CarpoolStatus.completed: return Colors.green;
      case CarpoolStatus.cancelled: return Colors.red;
    }
  }

  Widget _buildActionButtons() {
    if (_currentCarpoolRide == null) return const SizedBox.shrink();
    
    switch (_currentCarpoolRide!.status) {
      case CarpoolStatus.active:
        return _buildActionButton(
          'Start Carpool',
          Icons.play_arrow,
          Colors.green,
          () => _updateCarpoolStatus(CarpoolStatus.inProgress),
        );
        
      case CarpoolStatus.inProgress:
        return _buildActionButton(
          'Complete Carpool',
          Icons.flag,
          Colors.green,
          () => _updateCarpoolStatus(CarpoolStatus.completed),
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
