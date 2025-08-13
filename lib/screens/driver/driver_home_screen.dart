import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_provider.dart';
import '../../services/ride_service.dart';
import '../../services/driver_matching_service.dart';
import '../../models/ride_model.dart';
import 'driver_ride_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isOnline = false;
  final RideService _rideService = RideService();
  final DriverMatchingService _driverMatchingService = DriverMatchingService();
  List<RideModel> _pendingRides = [];
  bool _isLoading = false;
  
  // Driver statistics
  int _todayRides = 0;
  double _todayEarnings = 0.0;
  int _totalRides = 0;
  double _totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPendingRides();
    _loadDriverStats();
  }

  Future<void> _loadPendingRides() async {
    try {
      final ridesStream = _rideService.getPendingRides();
      ridesStream.listen((rides) {
        setState(() {
          _pendingRides = rides;
        });
      });
    } catch (e) {
      print('Error loading pending rides: $e');
    }
  }

  Future<void> _loadDriverStats() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.userModel;

      if (user != null) {
        // Load today's stats
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        
        final todayRidesQuery = await FirebaseFirestore.instance
            .collection('rides')
            .where('driverId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completed')
            .where('updatedAt', isGreaterThanOrEqualTo: startOfDay)
            .get();

        double todayEarnings = 0.0;
        for (final doc in todayRidesQuery.docs) {
          final data = doc.data();
          todayEarnings += (data['estimatedFare'] as num?)?.toDouble() ?? 0.0;
        }

        // Load total stats
        final totalRidesQuery = await FirebaseFirestore.instance
            .collection('rides')
            .where('driverId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completed')
            .get();

        double totalEarnings = 0.0;
        for (final doc in totalRidesQuery.docs) {
          final data = doc.data();
          totalEarnings += (data['estimatedFare'] as num?)?.toDouble() ?? 0.0;
        }

        if (mounted) {
          setState(() {
            _todayRides = todayRidesQuery.docs.length;
            _todayEarnings = todayEarnings;
            _totalRides = totalRidesQuery.docs.length;
            _totalEarnings = totalEarnings;
          });
        }
      }
    } catch (e) {
      print('Error loading driver stats: $e');
    }
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    setState(() {
      _isOnline = value;
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.userModel;

      if (user != null) {
        await _driverMatchingService.updateDriverAvailability(
          driverId: user.uid,
          isAvailable: value,
        );
      }
    } catch (e) {
      print('Error updating driver availability: $e');
      // Revert the toggle if there's an error
      setState(() {
        _isOnline = !value;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRide(RideModel ride) async {
    if (_isLoading) return; // Prevent multiple clicks
    
    try {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.userModel;

      if (user == null) {
        throw Exception('Driver not authenticated');
      }

      // Validate ride data
      if (ride.id.isEmpty) {
        throw Exception('Invalid ride ID');
      }

      // Assign driver to ride
      await _rideService.assignDriverToRide(ride.id, user.uid);
      
      // Update driver availability to false
      await _driverMatchingService.updateDriverAvailability(
        driverId: user.uid,
        isAvailable: false,
      );

      // Reload pending rides
      await _loadPendingRides();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to ride management screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DriverRideScreen(ride: ride),
          ),
        );
      }
    } catch (e) {
      print('Error accepting ride: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept ride: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'GoCab Driver',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadPendingRides();
              _loadDriverStats();
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications coming soon!'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile settings coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.userModel;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _loadPendingRides();
              await _loadDriverStats();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Online/Offline Toggle
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isOnline
                            ? [Colors.green, Colors.green.withOpacity(0.8)]
                            : [Colors.grey, Colors.grey.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isOnline ? 'Online' : 'Offline',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isOnline,
                              onChanged: _isLoading ? null : _toggleOnlineStatus,
                              activeColor: Colors.white,
                              activeTrackColor: Colors.white.withOpacity(0.3),
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: Colors.white.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats
                  Text(
                    "Today's Stats",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Today\'s Rides',
                          _todayRides.toString(),
                          Icons.local_taxi,
                          Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Today\'s Earnings',
                          '\$${_todayEarnings.toStringAsFixed(2)}',
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Rides',
                          _totalRides.toString(),
                          Icons.history,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Total Earnings',
                          '\$${_totalEarnings.toStringAsFixed(2)}',
                          Icons.account_balance_wallet,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Pending Ride Requests
                  if (_isOnline) ...[
                    Text(
                      'Pending Ride Requests',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_pendingRides.isEmpty)
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
                          children: [
                            Icon(
                              Icons.local_taxi_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No pending ride requests',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ride requests will appear here when available',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ..._pendingRides.map((ride) => _buildRideRequestCard(ride)),

                    const SizedBox(height: 24),
                  ],

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await authProvider.signOut();
                      },
                      icon: const Icon(Icons.logout),
                      label: Text(
                        'Sign Out',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
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
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
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
            title,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRideRequestCard(RideModel ride) {
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
                ride.rideType == RideType.carpool ? Icons.people : Icons.person,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                ride.rideType == RideType.carpool ? 'Carpool' : 'Solo',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              Text(
                '\$${ride.estimatedFare.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pickup Location
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ride.pickupAddress,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dropoff Location
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ride.dropoffAddress,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Accept Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _acceptRide(ride),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Accept Ride',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
