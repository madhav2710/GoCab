import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/ride_request_provider.dart';
import '../../models/ride_request_model.dart';
import '../../widgets/custom_button.dart';

class NewRideTrackingScreen extends StatefulWidget {
  final RideRequestModel rideRequest;

  const NewRideTrackingScreen({super.key, required this.rideRequest});

  @override
  State<NewRideTrackingScreen> createState() => _NewRideTrackingScreenState();
}

class _NewRideTrackingScreenState extends State<NewRideTrackingScreen> {
  @override
  void initState() {
    super.initState();
    // Start listening to ride updates
    final rideProvider = Provider.of<RideRequestProvider>(
      context,
      listen: false,
    );
    rideProvider.listenToRideUpdates(widget.rideRequest.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Track Ride',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _showExitConfirmation();
          },
        ),
      ),
      body: Consumer<RideRequestProvider>(
        builder: (context, rideProvider, child) {
          final currentRide = rideProvider.currentRide ?? widget.rideRequest;

          if (rideProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                _buildStatusCard(currentRide),
                const SizedBox(height: 24),

                // Route Information
                _buildRouteCard(currentRide),
                const SizedBox(height: 24),

                // Driver Information (if accepted)
                if (currentRide.status == RideRequestStatus.accepted ||
                    currentRide.status == RideRequestStatus.inProgress)
                  _buildDriverCard(currentRide),
                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(currentRide, rideProvider),
                const SizedBox(height: 24),

                // Ride Details
                _buildRideDetailsCard(currentRide),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(RideRequestModel ride) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (ride.status) {
      case RideRequestStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Looking for Driver';
        break;
      case RideRequestStatus.accepted:
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        statusText = 'Driver Assigned';
        break;
      case RideRequestStatus.inProgress:
        statusColor = Colors.green;
        statusIcon = Icons.directions_car;
        statusText = 'Ride in Progress';
        break;
      case RideRequestStatus.completed:
        statusColor = Colors.grey;
        statusIcon = Icons.done_all;
        statusText = 'Completed';
        break;
      case RideRequestStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, size: 32, color: statusColor),
          ),
          const SizedBox(height: 16),
          Text(
            statusText,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ride.statusDescription,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (ride.status == RideRequestStatus.pending) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Searching for nearby drivers...',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteCard(RideRequestModel ride) {
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
            'Route Details',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildLocationRow(
            icon: Icons.my_location,
            color: Colors.green,
            address: ride.pickupAddress,
            label: 'Pickup',
          ),
          const SizedBox(height: 16),
          _buildLocationRow(
            icon: Icons.location_on,
            color: Colors.red,
            address: ride.dropoffAddress,
            label: 'Dropoff',
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color color,
    required String address,
    required String label,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDriverCard(RideRequestModel ride) {
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
            'Driver Information',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue,
                child: Text(
                  ride.driverName?.isNotEmpty == true
                      ? ride.driverName![0].toUpperCase()
                      : 'D',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.driverName ?? 'Driver',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (ride.driverPhone != null)
                      Text(
                        ride.driverPhone!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (ride.vehicleNumber != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Vehicle: ${ride.vehicleNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.phone),
                onPressed: () {
                  // TODO: Implement call functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Call feature coming soon!')),
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  foregroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    RideRequestModel ride,
    RideRequestProvider provider,
  ) {
    if (ride.isCompleted || ride.isCancelled) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (ride.status == RideRequestStatus.pending) ...[
          Expanded(
            child: CustomButton(
              text: 'Cancel Ride',
              onPressed: () => _showCancelDialog(ride, provider),
              backgroundColor: Colors.red,
              textColor: Colors.white,
            ),
          ),
        ] else if (ride.status == RideRequestStatus.accepted ||
            ride.status == RideRequestStatus.inProgress) ...[
          Expanded(
            child: CustomButton(
              text: 'Contact Driver',
              onPressed: () {
                // TODO: Implement contact driver
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact feature coming soon!')),
                );
              },
              backgroundColor: Colors.blue,
              textColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomButton(
              text: 'Cancel Ride',
              onPressed: () => _showCancelDialog(ride, provider),
              backgroundColor: Colors.red,
              textColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRideDetailsCard(RideRequestModel ride) {
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
            'Ride Details',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Ride ID', ride.id.substring(0, 8)),
          _buildDetailRow('Ride Type', ride.rideType.name.toUpperCase()),
          _buildDetailRow(
            'Estimated Fare',
            '₹${ride.estimatedFare.toStringAsFixed(2)}',
          ),
          _buildDetailRow('Request Time', _formatDateTime(ride.createdAt)),
          if (ride.acceptedAt != null)
            _buildDetailRow('Accepted At', _formatDateTime(ride.acceptedAt!)),
          if (ride.startedAt != null)
            _buildDetailRow('Started At', _formatDateTime(ride.startedAt!)),
          if (ride.completedAt != null)
            _buildDetailRow('Completed At', _formatDateTime(ride.completedAt!)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Exit Tracking?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to exit ride tracking? You can still track your ride from the home screen.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: Text(
              'Exit',
              style: GoogleFonts.poppins(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(RideRequestModel ride, RideRequestProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Ride?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to cancel this ride? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('No', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog

              final success = await provider.cancelRideRequest(
                rideId: ride.id,
                cancellationReason: 'Cancelled by rider',
              );

              if (success && mounted) {
                Navigator.of(context).pop(); // Go back to home
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ride cancelled successfully'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
