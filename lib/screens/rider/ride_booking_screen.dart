import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../services/location_service.dart';
import '../../services/auth_provider.dart';
import '../../services/ride_service.dart';
import '../../models/ride_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/ride_type_selector.dart';
import '../../widgets/location_search_dialog.dart';
import '../../widgets/carpool_toggle.dart';
import '../../services/carpool_service.dart';
import '../../models/carpool_ride_model.dart';
import 'ride_confirmation_screen.dart';

class RideBookingScreen extends StatefulWidget {
  const RideBookingScreen({super.key});

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  final LocationService _locationService = LocationService();
  final RideService _rideService = RideService();
  final CarpoolService _carpoolService = CarpoolService();

  String? _pickupAddress;
  String? _dropoffAddress;
  double? _pickupLatitude;
  double? _pickupLongitude;
  double? _dropoffLatitude;
  double? _dropoffLongitude;
  RideType _selectedRideType = RideType.solo;
  double? _estimatedFare;
  final bool _isLoading = false;
  bool _isCarpoolEnabled = false;
  List<CarpoolRideModel> _availableCarpoolRides = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();

      if (position != null) {
        setState(() {
          _pickupLatitude = position.latitude;
          _pickupLongitude = position.longitude;
        });

        // Get address for current location
        final address = await locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (address != null) {
          setState(() {
            _pickupAddress = address;
          });
        }
      } else {
        // Use default location if current location is not available
        final defaultLocation = locationService.getDefaultLocation();
        setState(() {
          _pickupLatitude = defaultLocation['latitude']!;
          _pickupLongitude = defaultLocation['longitude']!;
          _pickupAddress = 'San Francisco, CA';
        });

        // Show a helpful message to the user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Using default location. Please enable location services for better experience.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading current location: $e');

      // Use default location as fallback
      final locationService = LocationService();
      final defaultLocation = locationService.getDefaultLocation();
      setState(() {
        _pickupLatitude = defaultLocation['latitude']!;
        _pickupLongitude = defaultLocation['longitude']!;
        _pickupAddress = 'San Francisco, CA';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location service unavailable. Using default location.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _selectPickupLocation() async {
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => const LocationSearchDialog(
          title: 'Select Pickup Location',
          hint: 'Search for pickup location',
        ),
      );

      if (result != null) {
        setState(() => _pickupAddress = result);
        await _getCoordinatesForPickup();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting pickup location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDropoffLocation() async {
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => const LocationSearchDialog(
          title: 'Select Dropoff Location',
          hint: 'Search for destination',
        ),
      );

      if (result != null) {
        setState(() => _dropoffAddress = result);
        await _getCoordinatesForDropoff();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting dropoff location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getCoordinatesForPickup() async {
    if (_pickupAddress != null) {
      try {
        final coordinates = await _locationService.getCoordinatesFromAddress(
          _pickupAddress!,
        );
        if (coordinates != null) {
          setState(() {
            _pickupLatitude = coordinates['latitude'];
            _pickupLongitude = coordinates['longitude'];
          });
          _calculateFare();
        } else {
          // Use default coordinates if geocoding fails
          setState(() {
            _pickupLatitude = 37.7749;
            _pickupLongitude = -122.4194;
          });
          _calculateFare();
        }
      } catch (e) {
        // Use default coordinates
        setState(() {
          _pickupLatitude = 37.7749;
          _pickupLongitude = -122.4194;
        });
        _calculateFare();
      }
    }
  }

  Future<void> _getCoordinatesForDropoff() async {
    if (_dropoffAddress != null) {
      try {
        final coordinates = await _locationService.getCoordinatesFromAddress(
          _dropoffAddress!,
        );
        if (coordinates != null) {
          setState(() {
            _dropoffLatitude = coordinates['latitude'];
            _dropoffLongitude = coordinates['longitude'];
          });
          _calculateFare();
        } else {
          // Use default coordinates if geocoding fails
          setState(() {
            _dropoffLatitude = 37.7849;
            _dropoffLongitude = -122.4094;
          });
          _calculateFare();
        }
      } catch (e) {
        // Use default coordinates
        setState(() {
          _dropoffLatitude = 37.7849;
          _dropoffLongitude = -122.4094;
        });
        _calculateFare();
      }
    }
  }

  void _calculateFare() {
    if (_pickupLatitude != null &&
        _pickupLongitude != null &&
        _dropoffLatitude != null &&
        _dropoffLongitude != null) {
      try {
        // Calculate distance
        final distance = _calculateDistance(
          _pickupLatitude!,
          _pickupLongitude!,
          _dropoffLatitude!,
          _dropoffLongitude!,
        );

        final fare = _rideService.calculateEstimatedFare(
          distance,
          _selectedRideType,
        );
        setState(() => _estimatedFare = fare);
      } catch (e) {
        // Set a default fare
        setState(() => _estimatedFare = 15.0);
      }
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final R = 6371.0; // Radius of Earth in km
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = R * c; // Distance in km
    return distance;
  }

  void _onRideTypeChanged(RideType type) {
    setState(() {
      _selectedRideType = type;
    });
    _calculateFare();
  }

  // void _onCarpoolToggled(bool value) {
  //   setState(() {
  //     _isCarpoolEnabled = value;
  //     if (value) {
  //       _selectedRideType = RideType.carpool;
  //     } else {
  //       _selectedRideType = RideType.solo;
  //     }
  //   });
  //   _calculateFare();
  // }

  Future<void> _findAvailableCarpoolRides() async {
    if (_pickupLatitude == null ||
        _pickupLongitude == null ||
        _dropoffLatitude == null ||
        _dropoffLongitude == null) {
      return;
    }

    try {
      final availableRides = await _carpoolService.findAvailableCarpoolRides(
        pickupLatitude: _pickupLatitude!,
        pickupLongitude: _pickupLongitude!,
        dropoffLatitude: _dropoffLatitude!,
        dropoffLongitude: _dropoffLongitude!,
      );

      setState(() {
        _availableCarpoolRides = availableRides;
      });
    } catch (e) {
      print('Error finding available carpool rides: $e');
    }
  }

  bool get _canProceed {
    return _pickupAddress != null &&
        _dropoffAddress != null &&
        _estimatedFare != null;
  }

  void _proceedToConfirmation() {
    if (!_canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideConfirmationScreen(
          pickupAddress: _pickupAddress!,
          dropoffAddress: _dropoffAddress!,
          pickupLatitude: _pickupLatitude!,
          pickupLongitude: _pickupLongitude!,
          dropoffLatitude: _dropoffLatitude!,
          dropoffLongitude: _dropoffLongitude!,
          rideType: _selectedRideType,
          estimatedFare: _estimatedFare!,
        ),
      ),
    ).then((value) {}).catchError((error) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Book a Ride',
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pickup Location
                  LocationPicker(
                    label: 'Pickup Location',
                    hint: 'Where should we pick you up?',
                    value: _pickupAddress,
                    onTap: _selectPickupLocation,
                    icon: Icons.my_location,
                  ),

                  const SizedBox(height: 20),

                  // Dropoff Location
                  LocationPicker(
                    label: 'Dropoff Location',
                    hint: 'Where are you going?',
                    value: _dropoffAddress,
                    onTap: _selectDropoffLocation,
                    icon: Icons.location_on,
                  ),

                  const SizedBox(height: 24),

                  // Carpool Toggle
                  CarpoolToggle(
                    isEnabled: _isCarpoolEnabled,
                    onChanged: (enabled) {
                      setState(() {
                        _isCarpoolEnabled = enabled;
                        if (enabled) {
                          _selectedRideType = RideType.carpool;
                        } else {
                          _selectedRideType = RideType.solo;
                        }
                      });
                      _calculateFare();
                      if (enabled) {
                        _findAvailableCarpoolRides();
                      }
                    },
                    availableSeats: 3,
                    discountPercentage: 20.0,
                  ),

                  const SizedBox(height: 24),

                  // Ride Type Selection
                  RideTypeSelector(
                    selectedType: _selectedRideType,
                    onTypeChanged: _onRideTypeChanged,
                  ),

                  const SizedBox(height: 24),

                  // Available Carpool Rides
                  if (_isCarpoolEnabled &&
                      _availableCarpoolRides.isNotEmpty) ...[
                    Text(
                      'Available Carpool Rides',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._availableCarpoolRides.map(
                      (carpoolRide) => _buildCarpoolRideCard(carpoolRide),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Estimated Fare
                  if (_estimatedFare != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated Fare',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '\$${_estimatedFare!.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedRideType == RideType.carpool
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _selectedRideType == RideType.carpool
                                      ? '20% OFF'
                                      : 'Standard',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedRideType == RideType.carpool
                                        ? Colors.green
                                        : Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fare may vary based on traffic and route',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],

                  // Proceed Button
                  CustomButton(
                    text: 'Continue to Book',
                    onPressed: _canProceed ? _proceedToConfirmation : () {},
                    isLoading: false,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCarpoolRideCard(CarpoolRideModel carpoolRide) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${carpoolRide.riders.length} passengers',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${carpoolRide.availableSeats} seats left',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Total Fare: \$${carpoolRide.totalFare.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${carpoolRide.stops.length} stops',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _joinCarpoolRide(carpoolRide),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Join This Carpool',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinCarpoolRide(CarpoolRideModel carpoolRide) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.userModel;

      if (user == null) {
        throw Exception('User not found');
      }

      final newRider = CarpoolRider(
        riderId: user.uid,
        riderName: user.name,
        pickupAddress: _pickupAddress!,
        dropoffAddress: _dropoffAddress!,
        pickupLatitude: _pickupLatitude!,
        pickupLongitude: _pickupLongitude!,
        dropoffLatitude: _dropoffLatitude!,
        dropoffLongitude: _dropoffLongitude!,
        fare: 0.0, // Will be calculated by the service
        status: CarpoolRiderStatus.waiting,
        joinedAt: DateTime.now(),
      );

      await _carpoolService.joinCarpoolRide(
        carpoolRideId: carpoolRide.id,
        newRider: newRider,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined carpool ride!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join carpool: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
