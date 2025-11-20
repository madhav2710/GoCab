import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import '../models/carpool_ride_model.dart';
// import '../models/carpool_request_model.dart';
import '../services/carpool_request_flow_service.dart';
import '../services/auth_provider.dart' as auth;

class CarpoolRequestFlowDemo extends StatefulWidget {
  const CarpoolRequestFlowDemo({super.key});

  @override
  State<CarpoolRequestFlowDemo> createState() => _CarpoolRequestFlowDemoState();
}

class _CarpoolRequestFlowDemoState extends State<CarpoolRequestFlowDemo> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Carpool Request Flow Demo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Consumer<auth.AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.userModel;
          final isDriver = user?.role.name == 'driver';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(user),
                const SizedBox(height: 24),

                // Error Display
                if (_error != null) _buildErrorCard(),
                if (_error != null) const SizedBox(height: 16),

                // Loading Indicator
                if (_isLoading) _buildLoadingCard(),
                if (_isLoading) const SizedBox(height: 16),

                // Driver Section
                if (isDriver) ...[
                  _buildDriverSection(),
                  const SizedBox(height: 24),
                ],

                // Rider Section
                _buildRiderSection(),
                const SizedBox(height: 24),

                // Instructions
                _buildInstructions(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Carpool Request Flow',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Test the complete carpool request and acceptance flow',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'User: ${user?.name ?? 'Unknown'} (${user?.role.name ?? 'Unknown'})',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.poppins(color: Colors.red, fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => setState(() => _error = null),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Processing request...',
            style: GoogleFonts.poppins(color: Colors.blue[700], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Driver Actions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          'Create Carpool Ride',
          'Create a new carpool ride for others to join',
          Icons.add_circle,
          Colors.green,
          _createCarpoolRide,
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          'View My Carpools',
          'See all your created carpool rides',
          Icons.directions_car,
          Colors.blue,
          _viewMyCarpools,
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          'View Requests',
          'See pending requests for your carpools',
          Icons.person_add,
          Colors.orange,
          _viewCarpoolRequests,
        ),
      ],
    );
  }

  Widget _buildRiderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rider Actions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          'Browse Available Carpools',
          'Find carpool rides to join',
          Icons.search,
          Colors.purple,
          _browseCarpools,
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          'My Requests',
          'View your carpool join requests',
          Icons.history,
          Colors.indigo,
          _viewMyRequests,
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
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
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to Test the Flow',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '1',
            'Create Carpool (Driver)',
            'As a driver, create a carpool ride with pickup/dropoff locations',
          ),
          _buildInstructionStep(
            '2',
            'Browse Carpools (Rider)',
            'As a rider, browse available carpool rides',
          ),
          _buildInstructionStep(
            '3',
            'Request to Join (Rider)',
            'Tap "Request to Join" on a carpool ride',
          ),
          _buildInstructionStep(
            '4',
            'View Requests (Driver)',
            'As the driver, see the pending request in real-time',
          ),
          _buildInstructionStep(
            '5',
            'Approve/Reject (Driver)',
            'Accept or decline the rider\'s request',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(
    String number,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Driver Actions
  void _createCarpoolRide() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final carpoolId = await CarpoolRequestFlowService.createCarpoolRide(
        pickupAddress: 'Central Mall, MG Road, Bangalore',
        dropoffAddress: 'Bangalore Airport, Devanahalli',
        pickupLatitude: 12.9716,
        pickupLongitude: 77.5946,
        dropoffLatitude: 13.1986,
        dropoffLongitude: 77.7066,
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        maxSeats: 3,
        farePerPerson: 150.0,
      );

      if (carpoolId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Carpool ride created successfully! ID: ${carpoolId.substring(0, 8)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Failed to create carpool ride: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _viewMyCarpools() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to "View My Carpools" screen'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _viewCarpoolRequests() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to "Carpool Requests" screen'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Rider Actions
  void _browseCarpools() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to "Carpool Discovery" screen'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _viewMyRequests() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to "My Carpool Requests" screen'),
        backgroundColor: Colors.indigo,
      ),
    );
  }
}
