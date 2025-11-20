import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/ride_request_provider.dart';
import '../../models/ride_request_model.dart';
import '../../services/auth_provider.dart' as auth;
import '../../widgets/custom_button.dart';
import 'new_driver_ride_screen.dart';

class NewDriverHomeScreen extends StatefulWidget {
  const NewDriverHomeScreen({super.key});

  @override
  State<NewDriverHomeScreen> createState() => _NewDriverHomeScreenState();
}

class _NewDriverHomeScreenState extends State<NewDriverHomeScreen>
    with WidgetsBindingObserver {
  RideRequestProvider? _rideProvider;

  // Driver statistics
  int _todayRides = 0;
  double _todayEarnings = 0.0;
  int _totalRides = 0;
  double _totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start listening to pending ride requests only if user is authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<auth.AuthProvider>(
        context,
        listen: false,
      );
      if (authProvider.userModel != null) {
        _rideProvider = Provider.of<RideRequestProvider>(
          context,
          listen: false,
        );
        // Initialize the provider to load current ride and ride history
        _rideProvider?.initialize();
        _rideProvider?.startListeningToPendingRequests();
        _loadDriverStats();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh stats and pending requests when returning to this screen (e.g., after completing a ride)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<auth.AuthProvider>(
        context,
        listen: false,
      );
      if (authProvider.userModel != null) {
        _rideProvider?.initialize();
        _loadDriverStats();
        _rideProvider?.refreshPendingRequests();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop listening to pending requests when leaving the screen
    _rideProvider?.stopListeningToPendingRequests();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh stats and pending requests when app resumes from background
    if (state == AppLifecycleState.resumed) {
      final authProvider = Provider.of<auth.AuthProvider>(
        context,
        listen: false,
      );
      if (authProvider.userModel != null) {
        _rideProvider?.initialize();
        _loadDriverStats();
        _rideProvider?.refreshPendingRequests();
      }
    }
  }

  Future<void> _loadDriverStats() async {
    try {
      debugPrint('🔄 Loading driver stats...');
      final authProvider = Provider.of<auth.AuthProvider>(
        context,
        listen: false,
      );
      final user = authProvider.userModel;

      if (user != null) {
        debugPrint('👤 Loading stats for driver: ${user.uid}');
        // Load today's stats from ride_requests collection
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);

        // Get all completed ride requests for this driver (simplified query)
        final allCompletedRides = await FirebaseFirestore.instance
            .collection('ride_requests')
            .where('driverId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completed')
            .get();

        debugPrint('📊 Found ${allCompletedRides.docs.length} completed rides');

        double todayEarnings = 0.0;
        int todayRidesCount = 0;
        double totalEarnings = 0.0;

        for (final doc in allCompletedRides.docs) {
          final data = doc.data();
          final fare = (data['estimatedFare'] as num?)?.toDouble() ?? 0.0;
          totalEarnings += fare;

          // Check if this ride was completed today
          final updatedAt = data['updatedAt'];
          if (updatedAt != null) {
            DateTime rideDate;
            if (updatedAt is Timestamp) {
              rideDate = updatedAt.toDate();
            } else if (updatedAt is DateTime) {
              rideDate = updatedAt;
            } else {
              continue;
            }

            if (rideDate.isAfter(startOfDay)) {
              todayEarnings += fare;
              todayRidesCount++;
            }
          }
        }

        debugPrint('📊 Today: $todayRidesCount rides, ₹$todayEarnings');
        debugPrint(
          '📊 Total: ${allCompletedRides.docs.length} rides, ₹$totalEarnings',
        );

        if (mounted) {
          setState(() {
            _todayRides = todayRidesCount;
            _todayEarnings = todayEarnings;
            _totalRides = allCompletedRides.docs.length;
            _totalEarnings = totalEarnings;
          });
          debugPrint('✅ Stats updated in UI');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading driver stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Driver Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadDriverStats();
              _rideProvider?.refreshPendingRequests();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Statistics and pending requests refreshed!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile settings coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Consumer2<RideRequestProvider, auth.AuthProvider>(
        builder: (context, rideProvider, authProvider, child) {
          final user = authProvider.userModel;
          final currentRide = rideProvider.currentRide;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                _buildWelcomeCard(user),
                const SizedBox(height: 24),

                // Current Ride Card (if any)
                if (currentRide != null && currentRide.driverId == user?.uid)
                  _buildCurrentRideCard(currentRide),

                if (currentRide != null && currentRide.driverId == user?.uid)
                  const SizedBox(height: 24),

                // Pending Ride Requests
                _buildPendingRequestsSection(rideProvider),
                const SizedBox(height: 24),

                // Quick Stats
                _buildQuickStats(rideProvider),
                const SizedBox(height: 24),

                // Sign Out Button
                Center(
                  child: CustomButton(
                    text: 'Sign Out',
                    onPressed: () => _showSignOutDialog(authProvider),
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(Icons.person, size: 30, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.name ?? 'Driver',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ONLINE',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'You\'re ready to accept ride requests. New requests will appear below.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentRideCard(RideRequestModel ride) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'Active Ride',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Pickup: ${ride.pickupAddress}',
            style: GoogleFonts.poppins(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Dropoff: ${ride.dropoffAddress}',
            style: GoogleFonts.poppins(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Continue Ride',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NewDriverRideScreen(rideRequest: ride),
                  ),
                );
              },
              backgroundColor: Colors.green,
              textColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsSection(RideRequestProvider rideProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pending Ride Requests',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            if (rideProvider.pendingRequestsCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${rideProvider.pendingRequestsCount}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (rideProvider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (rideProvider.pendingRideRequests.isEmpty)
          _buildEmptyState()
        else
          ...rideProvider.pendingRideRequests.map(
            (request) => _buildRideRequestCard(request),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No pending requests',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New ride requests will appear here when customers book rides.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRideRequestCard(RideRequestModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: Colors.orange[700], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.riderName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      request.riderPhone,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'NEW',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Route Information
          _buildLocationRow(
            icon: Icons.my_location,
            color: Colors.green,
            address: request.pickupAddress,
            label: 'Pickup',
          ),
          const SizedBox(height: 12),
          _buildLocationRow(
            icon: Icons.location_on,
            color: Colors.red,
            address: request.dropoffAddress,
            label: 'Dropoff',
          ),
          const SizedBox(height: 16),

          // Ride Details
          Row(
            children: [
              _buildDetailChip(
                icon: Icons.currency_rupee,
                label: '₹${request.estimatedFare.toStringAsFixed(0)}',
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              _buildDetailChip(
                icon: Icons.directions_car,
                label: request.rideType.name.toUpperCase(),
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildDetailChip(
                icon: Icons.access_time,
                label: _formatTime(request.createdAt),
                color: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Accept',
                  onPressed: () => _acceptRideRequest(request),
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Decline',
                  onPressed: () => _declineRideRequest(request),
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                ),
              ),
            ],
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
          padding: const EdgeInsets.all(6),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(RideRequestProvider rideProvider) {
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
            'Driver Stats',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.directions_car,
                  label: 'Today\'s Rides',
                  value: _todayRides.toString(),
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.history,
                  label: 'Total Rides',
                  value: _totalRides.toString(),
                  color: Colors.purple,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.star,
                  label: 'Rating',
                  value: '4.8',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.currency_rupee,
                  label: 'Today\'s Earnings',
                  value: '₹${_todayEarnings.toStringAsFixed(2)}',
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.account_balance_wallet,
                  label: 'Total Earnings',
                  value: '₹${_totalEarnings.toStringAsFixed(2)}',
                  color: Colors.teal,
                ),
              ),
              const Expanded(child: SizedBox()), // Empty space for alignment
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _acceptRideRequest(RideRequestModel request) async {
    final rideProvider = Provider.of<RideRequestProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<auth.AuthProvider>(context, listen: false);
    final user = authProvider.userModel;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint('🚕 Attempting to accept ride: ${request.id}');
    debugPrint('👤 Driver: ${user.name} (${user.uid})');
    debugPrint('📞 Phone: ${user.phone}');
    debugPrint('🚗 Vehicle: ${user.vehicleNumber}');

    final success = await rideProvider.acceptRideRequest(
      rideId: request.id,
      driverName: user.name,
      driverPhone: user.phone, // phone is required and non-nullable
      vehicleNumber:
          user.vehicleNumber ?? 'DL01AB1234', // Better default vehicle
    );

    if (success && mounted) {
      // Navigate to ride management screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewDriverRideScreen(rideRequest: request),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride accepted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rideProvider.error ?? 'Failed to accept ride request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _declineRideRequest(RideRequestModel request) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Decline Ride Request?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to decline this ride request from ${request.riderName}?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDeclineRideRequest(request);
            },
            child: Text(
              'Decline',
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

  Future<void> _performDeclineRideRequest(RideRequestModel request) async {
    final rideProvider = Provider.of<RideRequestProvider>(
      context,
      listen: false,
    );

    debugPrint('🚫 Attempting to decline ride: ${request.id}');

    final success = await rideProvider.declineRideRequest(
      rideId: request.id,
      declineReason: 'Driver declined the request',
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride request declined successfully'),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rideProvider.error ?? 'Failed to decline ride request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSignOutDialog(auth.AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sign Out',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Force cleanup of ride request provider data before signing out
              final rideProvider = Provider.of<RideRequestProvider>(
                context,
                listen: false,
              );
              debugPrint('🛑 Starting sign-out process...');
              rideProvider.forceCleanup();
              await authProvider.signOut();
              debugPrint('✅ Sign-out process completed');
            },
            child: Text(
              'Sign Out',
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
