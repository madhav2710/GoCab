import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/ride_request_provider.dart';
import '../../models/ride_request_model.dart';
import '../../widgets/custom_button.dart';
import 'ride_confirmation_screen.dart';

class NewRideBookingScreen extends StatefulWidget {
  const NewRideBookingScreen({super.key});

  @override
  State<NewRideBookingScreen> createState() => _NewRideBookingScreenState();
}

class _NewRideBookingScreenState extends State<NewRideBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  String _pickupAddress = '';
  String _dropoffAddress = '';
  double _pickupLatitude = 0.0;
  double _pickupLongitude = 0.0;
  double _dropoffLatitude = 0.0;
  double _dropoffLongitude = 0.0;
  RideType _selectedRideType = RideType.standard;
  double _estimatedFare = 0.0;

  final List<Map<String, dynamic>> _rideTypes = [
    {
      'type': RideType.standard,
      'name': 'Standard',
      'description': 'Regular ride',
      'multiplier': 1.0,
      'icon': Icons.directions_car,
      'color': Colors.blue,
    },
    {
      'type': RideType.premium,
      'name': 'Premium',
      'description': 'Luxury vehicle',
      'multiplier': 1.5,
      'icon': Icons.directions_car_filled,
      'color': Colors.purple,
    },
    {
      'type': RideType.carpool,
      'name': 'Carpool',
      'description': 'Shared ride',
      'multiplier': 0.7,
      'icon': Icons.people,
      'color': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Consumer<RideRequestProvider>(
        builder: (context, rideProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pickup Location
                  _buildLocationSection(
                    title: 'Pickup Location',
                    icon: Icons.my_location,
                    color: Colors.green,
                    address: _pickupAddress,
                    onTap: () => _selectLocation(true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select pickup location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Dropoff Location
                  _buildLocationSection(
                    title: 'Dropoff Location',
                    icon: Icons.location_on,
                    color: Colors.red,
                    address: _dropoffAddress,
                    onTap: () => _selectLocation(false),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select dropoff location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Ride Type Selection
                  Text(
                    'Select Ride Type',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._rideTypes.map((rideType) => _buildRideTypeCard(rideType)),
                  const SizedBox(height: 32),

                  // Fare Estimation
                  if (_estimatedFare > 0) _buildFareEstimation(),
                  const SizedBox(height: 32),

                  // Book Ride Button
                  CustomButton(
                    text: rideProvider.isLoading
                        ? 'Creating Ride Request...'
                        : 'Book Ride',
                    onPressed: rideProvider.isLoading ? () {} : _bookRide,
                    backgroundColor: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                  ),

                  // Error Display
                  if (rideProvider.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rideProvider.error!,
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                                fontSize: 14,
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
          );
        },
      ),
    );
  }

  Widget _buildLocationSection({
    required String title,
    required IconData icon,
    required Color color,
    required String address,
    required VoidCallback onTap,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    address.isEmpty ? 'Tap to select $title' : address,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: address.isEmpty
                          ? Colors.grey[600]
                          : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRideTypeCard(Map<String, dynamic> rideType) {
    final isSelected = _selectedRideType == rideType['type'];
    final color = rideType['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRideType = rideType['type'];
          });
          _calculateFare();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  rideType['icon'],
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rideType['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rideType['description'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFareEstimation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.currency_rupee, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Estimated Fare',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_estimatedFare.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Final fare may vary based on traffic and route',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _selectLocation(bool isPickup) async {
    // For now, using static locations. In a real app, you'd integrate with Google Places API
    final locations = [
      {
        'address': 'Central Mall, MG Road, Bangalore',
        'lat': 12.9716,
        'lng': 77.5946,
      },
      {
        'address': 'Bangalore Airport, Devanahalli',
        'lat': 13.1986,
        'lng': 77.7066,
      },
      {'address': 'Cubbon Park, Bangalore', 'lat': 12.9716, 'lng': 77.5946},
      {
        'address': 'Lalbagh Botanical Garden, Bangalore',
        'lat': 12.9507,
        'lng': 77.5848,
      },
      {'address': 'ISKCON Temple, Bangalore', 'lat': 13.0103, 'lng': 77.5510},
    ];

    final selectedLocation = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select ${isPickup ? 'Pickup' : 'Dropoff'} Location',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return ListTile(
                leading: Icon(
                  isPickup ? Icons.my_location : Icons.location_on,
                  color: isPickup ? Colors.green : Colors.red,
                ),
                title: Text(
                  location['address'] as String,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                onTap: () => Navigator.pop(context, location),
              );
            },
          ),
        ),
      ),
    );

    if (selectedLocation != null) {
      setState(() {
        if (isPickup) {
          _pickupAddress = selectedLocation['address'] as String;
          _pickupLatitude = selectedLocation['lat'] as double;
          _pickupLongitude = selectedLocation['lng'] as double;
        } else {
          _dropoffAddress = selectedLocation['address'] as String;
          _dropoffLatitude = selectedLocation['lat'] as double;
          _dropoffLongitude = selectedLocation['lng'] as double;
        }
      });
      _calculateFare();
    }
  }

  void _calculateFare() {
    if (_pickupAddress.isEmpty || _dropoffAddress.isEmpty) {
      setState(() {
        _estimatedFare = 0.0;
      });
      return;
    }

    // Simulate fare calculation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        // Base fare calculation (simplified)
        final baseFare = 50.0; // Base fare
        final distanceFare = 15.0; // Per km (simulated)
        final rideTypeMultiplier =
            _rideTypes.firstWhere(
                  (rt) => rt['type'] == _selectedRideType,
                )['multiplier']
                as double;

        final estimatedFare = (baseFare + distanceFare) * rideTypeMultiplier;

        setState(() {
          _estimatedFare = estimatedFare;
        });
      }
    });
  }

  void _bookRide() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      // Navigate to payment/confirmation screen first
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RideConfirmationScreen(
            pickupAddress: _pickupAddress,
            dropoffAddress: _dropoffAddress,
            pickupLatitude: _pickupLatitude,
            pickupLongitude: _pickupLongitude,
            dropoffLatitude: _dropoffLatitude,
            dropoffLongitude: _dropoffLongitude,
            rideType: _selectedRideType,
            estimatedFare: _estimatedFare,
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm your ride details and payment.'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
}
