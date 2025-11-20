import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/ride_request_provider.dart';
import '../../models/ride_request_model.dart';
import '../../widgets/custom_button.dart';

class NewDriverRideScreen extends StatefulWidget {
  final RideRequestModel rideRequest;

  const NewDriverRideScreen({super.key, required this.rideRequest});

  @override
  State<NewDriverRideScreen> createState() => _NewDriverRideScreenState();
}

class _NewDriverRideScreenState extends State<NewDriverRideScreen> {
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
          'Ride Management',
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

                // Rider Information
                _buildRiderCard(currentRide),
                const SizedBox(height: 24),

                // Route Information
                _buildRouteCard(currentRide),
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
    String statusDescription;

    switch (ride.status) {
      case RideRequestStatus.accepted:
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        statusText = 'Ride Accepted';
        statusDescription = 'Navigate to pickup location to start the ride.';
        break;
      case RideRequestStatus.inProgress:
        statusColor = Colors.green;
        statusIcon = Icons.directions_car;
        statusText = 'Ride in Progress';
        statusDescription = 'Drive safely to the destination.';
        break;
      case RideRequestStatus.completed:
        statusColor = Colors.grey;
        statusIcon = Icons.done_all;
        statusText = 'Ride Completed';
        statusDescription = 'Ride has been completed successfully.';
        break;
      case RideRequestStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Ride Cancelled';
        statusDescription = 'This ride has been cancelled.';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Unknown Status';
        statusDescription = 'Status not recognized.';
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
            statusDescription,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRiderCard(RideRequestModel ride) {
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
            'Rider Information',
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
                  ride.riderName.isNotEmpty
                      ? ride.riderName[0].toUpperCase()
                      : 'R',
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
                      ride.riderName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ride.riderPhone,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
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

  Widget _buildActionButtons(
    RideRequestModel ride,
    RideRequestProvider provider,
  ) {
    if (ride.isCompleted || ride.isCancelled) {
      return const SizedBox.shrink();
    }

    List<Widget> buttons = [];

    switch (ride.status) {
      case RideRequestStatus.accepted:
        buttons.addAll([
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Start Ride',
              onPressed: () => _startRide(ride, provider),
              backgroundColor: Colors.green,
              textColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Cancel Ride',
              onPressed: () => _cancelRide(ride, provider),
              backgroundColor: Colors.red,
              textColor: Colors.white,
            ),
          ),
        ]);
        break;
      case RideRequestStatus.inProgress:
        buttons.addAll([
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Complete Ride',
              onPressed: () => _completeRide(ride, provider),
              backgroundColor: Colors.blue,
              textColor: Colors.white,
            ),
          ),
        ]);
        break;
      default:
        break;
    }

    return Column(children: buttons);
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
          _buildDetailRow('Fare', '₹${ride.estimatedFare.toStringAsFixed(2)}'),
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

  void _startRide(RideRequestModel ride, RideRequestProvider provider) async {
    final success = await provider.updateRideStatus(
      rideId: ride.id,
      status: RideRequestStatus.inProgress,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride started successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _completeRide(
    RideRequestModel ride,
    RideRequestProvider provider,
  ) async {
    final success = await provider.updateRideStatus(
      rideId: ride.id,
      status: RideRequestStatus.completed,
    );

    if (success && mounted) {
      // Navigate back to new driver home screen
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/new-driver-home', (route) => false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _cancelRide(RideRequestModel ride, RideRequestProvider provider) {
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
                cancellationReason: 'Cancelled by driver',
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

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Exit Ride?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to exit this ride? The ride will remain active.',
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
