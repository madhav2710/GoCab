import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/ride_tracking_service.dart';
import '../../services/location_service.dart';
import '../../services/indian_location_service.dart';
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

  Position? _currentPosition;
  Timer? _locationTimer;
  Timer? _navigationTimer;
  final RideTrackingService _trackingService = RideTrackingService();
  final LocationService _locationService = LocationService();
  final IndianLocationService _indianLocationService = IndianLocationService();
  StreamSubscription<RideModel?>? _rideSubscription;
  StreamSubscription<Position>? _positionSubscription;

  // Navigation variables
  Duration? _etaToPickup;
  Duration? _etaToDropoff;
  double _distanceToPickup = 0.0;
  double _distanceToDropoff = 0.0;
  bool _isNearPickup = false;
  bool _isNearDropoff = false;
  String _currentNavigationStep = 'Navigate to pickup';

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
      await _loadRiderInfo();
      await _updateMapMarkers();
      await _getNavigationRoute();

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

      // Start navigation timer for automatic updates
      _startNavigationTimer();

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

  void _startNavigationTimer() {
    _navigationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _currentPosition != null) {
        _updateNavigationInfo();
        _checkProximityAndUpdateStatus();
      }
    });
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
      debugPrint('Error loading rider info: $e');
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

  Future<void> _getNavigationRoute() async {
    try {
      if (_currentPosition == null) return;

      final String apiKey = 'AIzaSyCQ2xpJ042ReuzwhDtFXgwUBwjynHacdCw';
      String origin, destination;

      // Determine route based on current ride status
      if (_currentRide!.status == RideStatus.accepted ||
          _currentRide!.status == RideStatus.inProgress) {
        // Navigate to pickup
        origin = '${_currentPosition!.latitude},${_currentPosition!.longitude}';
        destination =
            '${_currentRide!.pickupLatitude},${_currentRide!.pickupLongitude}';
        _currentNavigationStep = 'Navigate to pickup';
      } else if (_currentRide!.status == RideStatus.pickupComplete) {
        // Navigate to dropoff
        origin =
            '${_currentRide!.pickupLatitude},${_currentRide!.pickupLongitude}';
        destination =
            '${_currentRide!.dropoffLatitude},${_currentRide!.dropoffLongitude}';
        _currentNavigationStep = 'Navigate to dropoff';
      } else {
        return;
      }

      // Add India-specific parameters for better routing
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=$origin&destination=$destination'
          '&key=$apiKey'
          '&region=in' // India region
          '&language=en' // English language
          '&avoid=tolls' // Avoid toll roads if possible
          '&units=metric'; // Use metric units

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check for API errors
        if (data['status'] == 'OK' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final points = route['overview_polyline']['points'];
          final List<LatLng> polylineCoordinates = _decodePolyline(points);

          // Get ETA and distance
          if (route['legs'] != null && route['legs'].isNotEmpty) {
            final leg = route['legs'][0];
            final duration = leg['duration']['value'];
            final distance = leg['distance']['value'];

            if (_currentRide!.status == RideStatus.accepted ||
                _currentRide!.status == RideStatus.inProgress) {
              _etaToPickup = Duration(seconds: duration);
              _distanceToPickup = distance / 1000; // Convert to km
            } else if (_currentRide!.status == RideStatus.pickupComplete) {
              _etaToDropoff = Duration(seconds: duration);
              _distanceToDropoff = distance / 1000; // Convert to km
            }
          }

          if (mounted) {
            setState(() {
              _polylines.clear();
              // Add main route polyline
              _polylines.add(
                Polyline(
                  polylineId: const PolylineId('navigation_route'),
                  color: Colors.blue,
                  points: polylineCoordinates,
                  width: 6,
                  patterns: [], // Solid line
                ),
              );

              // Add animated route for better visibility
              _polylines.add(
                Polyline(
                  polylineId: const PolylineId('animated_route'),
                  color: Colors.lightBlue,
                  points: polylineCoordinates,
                  width: 3,
                  patterns: [PatternItem.dash(20), PatternItem.gap(10)],
                ),
              );
            });

            // Auto-center map on route
            _fitBounds();
          }
        } else {
          // Handle API errors
          String errorMessage = 'Unable to get route';
          if (data['status'] == 'ZERO_RESULTS') {
            errorMessage = 'No route found between locations';
          } else if (data['status'] == 'OVER_QUERY_LIMIT') {
            errorMessage = 'API quota exceeded';
          } else if (data['status'] == 'REQUEST_DENIED') {
            errorMessage = 'API request denied';
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ $errorMessage'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting navigation route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Navigation error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateNavigationInfo() async {
    if (_currentPosition == null || _currentRide == null) return;

    // Calculate distances
    final distanceToPickup = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _currentRide!.pickupLatitude,
      _currentRide!.pickupLongitude,
    );

    final distanceToDropoff = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _currentRide!.dropoffLatitude,
      _currentRide!.dropoffLongitude,
    );

    setState(() {
      _distanceToPickup = distanceToPickup / 1000; // Convert to km
      _distanceToDropoff = distanceToDropoff / 1000; // Convert to km
    });

    // Check proximity (within 100 meters)
    _isNearPickup = distanceToPickup <= 100;
    _isNearDropoff = distanceToDropoff <= 100;

    // Update route if needed
    if (_currentRide!.status == RideStatus.accepted ||
        _currentRide!.status == RideStatus.inProgress) {
      if (!_isNearPickup) {
        await _getNavigationRoute();
      }
    } else if (_currentRide!.status == RideStatus.pickupComplete) {
      if (!_isNearDropoff) {
        await _getNavigationRoute();
      }
    }
  }

  void _checkProximityAndUpdateStatus() {
    if (_currentRide == null) return;

    // Auto-update status based on proximity
    if (_currentRide!.status == RideStatus.accepted && _isNearPickup) {
      _updateRideStatus(RideStatus.arrived);
    } else if (_currentRide!.status == RideStatus.arrived && _isNearPickup) {
      // Keep arrived status when near pickup
    } else if (_currentRide!.status == RideStatus.pickupComplete &&
        _isNearDropoff) {
      // Auto-complete when near dropoff
      _updateRideStatus(RideStatus.completed);
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
        _updateNavigationInfo();
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
              _updateNavigationInfo();
            }
          });
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
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
      debugPrint('Error updating driver location: $e');
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

  Future<void> _startTrip() async {
    if (_isUpdatingStatus) return;

    try {
      setState(() {
        _isUpdatingStatus = true;
      });

      // Validate current location is in India
      if (_currentPosition != null) {
        bool isInIndia = _indianLocationService.isLocationInIndia(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );

        if (!isInIndia) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Please ensure you are in India to start the trip',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      // Show trip started dialog with navigation instructions
      await _showTripStartedDialog();

      // Update ride status to in-progress
      await _trackingService.updateRideStatus(
        widget.ride.id,
        RideStatus.inProgress,
      );

      // Update local ride status
      if (_currentRide != null) {
        setState(() {
          _currentRide = _currentRide!.copyWith(status: RideStatus.inProgress);
        });
      }

      // Force navigation route update with enhanced directions
      await _getNavigationRoute();
      await _updateMapMarkers();

      // Show enhanced navigation with Indian context
      await _showNavigationDirections();

      // Show nearby landmarks for better context
      await _showNearbyLandmarks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚗 Trip started! Navigate to pickup location'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting trip: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting trip: $e'),
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

  Future<void> _updateRideStatus(RideStatus status) async {
    if (_isUpdatingStatus) return;
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await _trackingService.updateRideStatus(widget.ride.id, status);

      // Update local ride status
      if (_currentRide != null) {
        setState(() {
          _currentRide = _currentRide!.copyWith(status: status);
        });
      }

      // Update navigation route based on new status
      await _getNavigationRoute();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ride status updated to ${_getStatusText(status)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating ride status: $e');
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

  Future<void> _showTripStartedDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.play_arrow, color: Colors.green),
            const SizedBox(width: 8),
            Text('🚗 Trip Started!', style: GoogleFonts.poppins()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Navigation to pickup location has started.',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 Pickup Location:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentRide!.pickupAddress,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '🏢 Dropoff Location:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.red[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentRide!.dropoffAddress,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🗺️ Navigation Instructions:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Follow the blue route on the map\n• ETA and distance will update in real-time\n• You\'ll be notified when you arrive\n• Use Indian traffic rules and signals',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('🚀 Start Navigation', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<void> _showNavigationDirections() async {
    if (_currentPosition == null || _currentRide == null) return;

    try {
      final String apiKey = 'AIzaSyCQ2xpJ042ReuzwhDtFXgwUBwjynHacdCw';
      final String origin =
          '${_currentPosition!.latitude},${_currentPosition!.longitude}';
      final String destination =
          '${_currentRide!.pickupLatitude},${_currentRide!.pickupLongitude}';

      // Add India-specific parameters for better routing
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=$origin&destination=$destination'
          '&key=$apiKey'
          '&region=in' // India region
          '&language=en' // English language
          '&avoid=tolls' // Avoid toll roads if possible
          '&units=metric'; // Use metric units

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check for API errors
        if (data['status'] == 'OK' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final route = data['routes'][0];

          // Get detailed step-by-step directions
          if (route['legs'] != null && route['legs'].isNotEmpty) {
            final leg = route['legs'][0];
            final steps = leg['steps'] as List;

            // Show first few navigation steps
            final firstSteps = steps
                .take(3)
                .map((step) {
                  return step['html_instructions'].toString().replaceAll(
                    RegExp(r'<[^>]*>'),
                    '',
                  ); // Remove HTML tags
                })
                .join('\n• ');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🗺️ Navigation Directions:',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• $firstSteps',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 8),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } else {
          // Handle API errors silently for directions
          debugPrint('Navigation directions API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting navigation directions: $e');
    }
  }

  Future<void> _showNearbyLandmarks() async {
    if (_currentPosition == null) return;

    try {
      // Get nearby landmarks within 5km radius
      final nearbyLandmarks = _indianLocationService.getNearbyLandmarks(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        5.0, // 5km radius
      );

      if (nearbyLandmarks.isNotEmpty && mounted) {
        final nearestLandmark = nearbyLandmarks.first;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏢 Nearby Landmark:',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${nearestLandmark['name']} (${nearestLandmark['distance'].toStringAsFixed(1)} km away)',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error showing nearby landmarks: $e');
    }
  }

  void _showRideCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Ride Completed!', style: GoogleFonts.poppins()),
        content: Text(
          'The ride has been completed successfully.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to driver home
            },
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  double _calculateDistance() {
    if (_currentRide == null) return 0.0;

    return Geolocator.distanceBetween(
          _currentRide!.pickupLatitude,
          _currentRide!.pickupLongitude,
          _currentRide!.dropoffLatitude,
          _currentRide!.dropoffLongitude,
        ) /
        1000; // Convert to km
  }

  IconData _getCurrentNavigationIcon() {
    if (_currentRide == null) return Icons.navigation;

    switch (_currentRide!.status) {
      case RideStatus.accepted:
      case RideStatus.inProgress:
        return Icons.directions_car;
      case RideStatus.arrived:
        return Icons.location_on;
      case RideStatus.pickupComplete:
        return Icons.flag;
      default:
        return Icons.navigation;
    }
  }

  String _getCurrentNavigationSubtitle() {
    if (_currentRide == null) return '';

    switch (_currentRide!.status) {
      case RideStatus.accepted:
        return 'Follow the blue route to pickup location';
      case RideStatus.inProgress:
        return 'Driving to pickup location';
      case RideStatus.arrived:
        return 'You have arrived at pickup location';
      case RideStatus.pickupComplete:
        return 'Follow the blue route to dropoff location';
      default:
        return '';
    }
  }

  String _getSpeedText() {
    if (_currentRide == null) return 'Ready';

    switch (_currentRide!.status) {
      case RideStatus.accepted:
        return 'Ready';
      case RideStatus.inProgress:
        return 'En Route';
      case RideStatus.arrived:
        return 'Arrived';
      case RideStatus.pickupComplete:
        return 'To Dropoff';
      default:
        return 'Ready';
    }
  }

  Widget _buildNavigationStat(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _positionSubscription?.cancel();
    _locationTimer?.cancel();
    _navigationTimer?.cancel();
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
        title: Text('Navigation', style: GoogleFonts.poppins()),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _updateMapMarkers();
              _getNavigationRoute();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Navigation Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCurrentNavigationIcon(),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentNavigationStep,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (_getCurrentNavigationSubtitle().isNotEmpty)
                            Text(
                              _getCurrentNavigationSubtitle(),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (_etaToPickup != null &&
                          (_currentRide!.status == RideStatus.accepted ||
                              _currentRide!.status ==
                                  RideStatus.inProgress)) ...[
                        _buildNavigationStat(
                          Icons.access_time,
                          '${_etaToPickup!.inMinutes} min',
                          'ETA',
                        ),
                        _buildNavigationStat(
                          Icons.straighten,
                          '${_distanceToPickup.toStringAsFixed(1)} km',
                          'Distance',
                        ),
                      ],
                      if (_etaToDropoff != null &&
                          _currentRide!.status ==
                              RideStatus.pickupComplete) ...[
                        _buildNavigationStat(
                          Icons.access_time,
                          '${_etaToDropoff!.inMinutes} min',
                          'ETA',
                        ),
                        _buildNavigationStat(
                          Icons.straighten,
                          '${_distanceToDropoff.toStringAsFixed(1)} km',
                          'Distance',
                        ),
                      ],
                      _buildNavigationStat(
                        Icons.speed,
                        _getSpeedText(),
                        'Status',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

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
                        : 19.0760, // Mumbai, India
                    widget.ride.pickupLongitude != 0
                        ? widget.ride.pickupLongitude
                        : 72.8777, // Mumbai, India
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
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          color: Theme.of(context).primaryColor,
                          size: 30,
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
              () => _startTrip(),
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
