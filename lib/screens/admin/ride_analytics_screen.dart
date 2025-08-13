import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_service.dart';

class RideAnalyticsScreen extends StatefulWidget {
  const RideAnalyticsScreen({super.key});

  @override
  State<RideAnalyticsScreen> createState() => _RideAnalyticsScreenState();
}

class _RideAnalyticsScreenState extends State<RideAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await _adminService.getRideAnalytics();
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Icon(Icons.trending_up, color: Colors.green, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideList() {
    return StreamBuilder(
      stream: _adminService.getRidesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading rides: ${snapshot.error}',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          );
        }

        final rides = snapshot.data?.docs ?? [];

        if (rides.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_taxi_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No rides found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rides will appear here once they are created',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final rideData = rides[index].data() as Map<String, dynamic>?;
            final rideId = rides[index].id;

            if (rideData == null) {
              return const SizedBox.shrink();
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(
                    rideData['status'] ?? 'unknown',
                  ).withOpacity(0.1),
                  child: Icon(
                    Icons.local_taxi,
                    color: _getStatusColor(rideData['status'] ?? 'unknown'),
                  ),
                ),
                title: Text(
                  'Ride #${rideId.substring(0, 8)}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rideData['pickupAddress'] ?? 'Unknown'} → ${rideData['dropoffAddress'] ?? 'Unknown'}',
                    ),
                    Text(
                      'Status: ${(rideData['status'] ?? 'unknown').toString().toUpperCase()}',
                      style: TextStyle(
                        color: _getStatusColor(rideData['status'] ?? 'unknown'),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (rideData['actualFare'] != null)
                      Text(
                        'Fare: \$${(rideData['actualFare'] as num).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                trailing: Text(
                  _formatDate(rideData['createdAt']),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'inProgress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    DateTime date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else {
      date = timestamp.toDate();
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ride Overview',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 24),

          // Analytics Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildAnalyticsCard(
                'Total Rides',
                '${_analytics['totalRides'] ?? 0}',
                Icons.local_taxi,
                Colors.blue,
              ),
              _buildAnalyticsCard(
                'Completed',
                '${_analytics['completedRides'] ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
              _buildAnalyticsCard(
                'Cancelled',
                '${_analytics['cancelledRides'] ?? 0}',
                Icons.cancel,
                Colors.red,
              ),
              _buildAnalyticsCard(
                'Pending',
                '${_analytics['pendingRides'] ?? 0}',
                Icons.schedule,
                Colors.orange,
              ),
              _buildAnalyticsCard(
                'Total Revenue',
                '\$${(_analytics['totalRevenue'] ?? 0).toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
              _buildAnalyticsCard(
                'Completion Rate',
                '${(_analytics['completionRate'] ?? 0).toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Activity
          Text(
            'Recent Activity',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(height: 300, child: _buildRideList()),
        ],
      ),
    );
  }

  Widget _buildDetailedTab() {
    return const Center(
      child: Text(
        'Detailed analytics and charts will be implemented here',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildReportsTab() {
    return const Center(
      child: Text(
        'Reports and exports will be implemented here',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Ride Analytics',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _loadAnalytics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tab Bar
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.blue[600],
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Colors.blue[600],
                    labelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Detailed'),
                      Tab(text: 'Reports'),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildDetailedTab(),
                      _buildReportsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
