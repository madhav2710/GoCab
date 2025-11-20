import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/ride_request_provider.dart';
import '../models/ride_request_model.dart';
import '../services/auth_provider.dart' as auth;
import 'rider/new_ride_booking_screen.dart';
import 'rider/new_ride_tracking_screen.dart';
import 'driver/new_driver_home_screen.dart';
import 'driver/new_driver_ride_screen.dart';

class TestRideFlowScreen extends StatelessWidget {
  const TestRideFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Test Ride Flow',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Consumer2<RideRequestProvider, auth.AuthProvider>(
        builder: (context, rideProvider, authProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
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
                        'GoCab Ride Flow Test',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Test the complete ride request and acceptance flow',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Current Status
                _buildStatusSection(rideProvider, authProvider),
                const SizedBox(height: 24),

                // Test Actions
                _buildTestActions(context),
                const SizedBox(height: 24),

                // Real-time Data
                _buildRealTimeData(rideProvider),
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

  Widget _buildStatusSection(
    RideRequestProvider rideProvider,
    auth.AuthProvider authProvider,
  ) {
    return Container(
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
          Text(
            'Current Status',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            'User',
            authProvider.userModel?.name ?? 'Not logged in',
          ),
          _buildStatusRow(
            'User Type',
            authProvider.userModel?.role.name ?? 'Unknown',
          ),
          _buildStatusRow(
            'Current Ride',
            rideProvider.currentRide?.id.substring(0, 8) ?? 'None',
          ),
          _buildStatusRow(
            'Ride Status',
            rideProvider.currentRide?.statusDisplayName ?? 'No active ride',
          ),
          _buildStatusRow(
            'Pending Requests',
            '${rideProvider.pendingRequestsCount}',
          ),
          _buildStatusRow('Is Loading', rideProvider.isLoading.toString()),
          if (rideProvider.error != null)
            _buildStatusRow('Error', rideProvider.error!, isError: true),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isError ? Colors.red : Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestActions(BuildContext context) {
    return Container(
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
          Text(
            'Test Actions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            context,
            'Book a Ride (Rider)',
            Icons.person_add,
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NewRideBookingScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            'Driver Dashboard',
            Icons.directions_car,
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NewDriverHomeScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            'Refresh Current Ride',
            Icons.refresh,
            Colors.orange,
            () {
              final rideProvider = Provider.of<RideRequestProvider>(
                context,
                listen: false,
              );
              rideProvider.refreshCurrentRide();
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            'Clear Current Ride',
            Icons.clear,
            Colors.red,
            () {
              final rideProvider = Provider.of<RideRequestProvider>(
                context,
                listen: false,
              );
              rideProvider.clearCurrentRide();
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            'Test Carpool Flow',
            Icons.people,
            Colors.purple,
            () {
              Navigator.pushNamed(context, '/carpool-demo');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
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

  Widget _buildRealTimeData(RideRequestProvider rideProvider) {
    return Container(
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
          Text(
            'Real-time Data',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (rideProvider.currentRide != null)
            _buildRideDetails(rideProvider.currentRide!)
          else
            Text(
              'No active ride',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          const SizedBox(height: 16),
          if (rideProvider.pendingRideRequests.isNotEmpty) ...[
            Text(
              'Pending Requests:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...rideProvider.pendingRideRequests.map(
              (request) => _buildPendingRequestItem(request),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRideDetails(RideRequestModel ride) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ride ID: ${ride.id.substring(0, 8)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: ${ride.statusDisplayName}',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue[700]),
          ),
          const SizedBox(height: 4),
          Text(
            'Rider: ${ride.riderName}',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue[700]),
          ),
          const SizedBox(height: 4),
          Text(
            'Fare: ₹${ride.estimatedFare.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestItem(RideRequestModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.person, size: 16, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${request.riderName} - ₹${request.estimatedFare.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.orange[700],
              ),
            ),
          ),
        ],
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
            'How to Test',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '1',
            'Book a Ride as Rider',
            'Tap "Book a Ride (Rider)" to create a new ride request',
          ),
          _buildInstructionStep(
            '2',
            'Switch to Driver View',
            'Tap "Driver Dashboard" to see pending requests',
          ),
          _buildInstructionStep(
            '3',
            'Accept the Ride',
            'Accept the ride request from the driver dashboard',
          ),
          _buildInstructionStep(
            '4',
            'Track the Ride',
            'Switch back to rider view to see real-time updates',
          ),
          _buildInstructionStep(
            '5',
            'Complete the Ride',
            'Use the driver ride screen to complete the ride',
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
}
