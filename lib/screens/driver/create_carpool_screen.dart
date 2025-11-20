import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/carpool_ride_model.dart';
import '../../services/carpool_service.dart';
import '../../widgets/custom_button.dart';

class CreateCarpoolScreen extends StatefulWidget {
  const CreateCarpoolScreen({super.key});

  @override
  State<CreateCarpoolScreen> createState() => _CreateCarpoolScreenState();
}

class _CreateCarpoolScreenState extends State<CreateCarpoolScreen> {
  final CarpoolService _carpoolService = CarpoolService();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _maxSeatsController = TextEditingController(
    text: '4',
  );

  bool _isLoading = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _maxSeatsController.dispose();
    super.dispose();
  }

  Future<void> _createCarpoolRide() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('Please login to create carpool rides');
        return;
      }

      if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
        _showErrorSnackBar('Please fill in all fields');
        return;
      }

      final maxSeats = int.tryParse(_maxSeatsController.text) ?? 4;
      if (maxSeats < 2 || maxSeats > 6) {
        _showErrorSnackBar('Max seats should be between 2 and 6');
        return;
      }

      // Create a sample rider (the driver)
      final driverRider = CarpoolRider(
        riderId: currentUser.uid,
        riderName: 'Driver',
        pickupAddress: _pickupController.text,
        dropoffAddress: _dropoffController.text,
        pickupLatitude: 23.0225, // Default coordinates
        pickupLongitude: 72.5714,
        dropoffLatitude: 23.0225,
        dropoffLongitude: 72.5714,
        fare: 50.0,
        status: CarpoolRiderStatus.waiting,
        joinedAt: DateTime.now(),
      );

      // Create carpool ride
      await _carpoolService.createCarpoolRide(
        driverId: currentUser.uid,
        riders: [driverRider],
        maxSeats: maxSeats,
      );

      _showSuccessSnackBar('Carpool ride created successfully!');

      // Clear form
      _pickupController.clear();
      _dropoffController.clear();
      _maxSeatsController.text = '4';
    } catch (e) {
      _showErrorSnackBar('Error creating carpool ride: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Create Carpool Ride',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Create a new carpool ride for others to join',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

            // Form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _pickupController,
                    decoration: InputDecoration(
                      labelText: 'Pickup Location',
                      hintText: 'Where will you start?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _dropoffController,
                    decoration: InputDecoration(
                      labelText: 'Dropoff Location',
                      hintText: 'Where are you going?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _maxSeatsController,
                    decoration: InputDecoration(
                      labelText: 'Maximum Seats',
                      hintText: 'How many passengers can join?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.people, color: Colors.blue),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: _isLoading ? 'Creating...' : 'Create Carpool Ride',
                    onPressed: _isLoading ? () {} : () => _createCarpoolRide(),
                    backgroundColor: const Color(0xFF1E3A8A),
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Once created, other users can find and request to join your carpool ride. You can approve or reject requests.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
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
}
