import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/carpool_ride_model.dart';

class CarpoolRidersWidget extends StatelessWidget {
  final List<CarpoolRider> riders;
  final List<CarpoolStop> stops;
  final int maxSeats;
  final int availableSeats;
  final Map<String, double> riderFares;

  const CarpoolRidersWidget({
    super.key,
    required this.riders,
    required this.stops,
    required this.maxSeats,
    required this.availableSeats,
    required this.riderFares,
  });

  @override
  Widget build(BuildContext context) {
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
          // Header
          Row(
            children: [
              Icon(
                Icons.people,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Carpool Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: availableSeats > 0 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$availableSeats/$maxSeats seats',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: availableSeats > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Riders List
          if (riders.isNotEmpty) ...[
            Text(
              'Passengers',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...riders.map((rider) => _buildRiderCard(rider, context)),
            const SizedBox(height: 16),
          ],

          // Route Stops
          Text(
            'Route Stops',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...stops.map((stop) => _buildStopCard(stop, context)),

          const SizedBox(height: 16),

          // Fare Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fare Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ...riders.map((rider) => _buildFareRow(rider, context)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Fare',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '\$${_calculateTotalFare().toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderCard(CarpoolRider rider, BuildContext context) {
    final fare = riderFares[rider.riderId] ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Text(
              rider.riderName.isNotEmpty 
                  ? rider.riderName[0].toUpperCase()
                  : 'R',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider.riderName.isNotEmpty 
                      ? rider.riderName
                      : 'Rider',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${rider.pickupAddress} → ${rider.dropoffAddress}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${fare.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(rider.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(rider.status),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(rider.status),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStopCard(CarpoolStop stop, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: stop.type == StopType.pickup 
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: stop.type == StopType.pickup 
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: stop.type == StopType.pickup ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              stop.type == StopType.pickup ? Icons.location_on : Icons.location_off,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.type == StopType.pickup ? 'Pickup' : 'Dropoff',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: stop.type == StopType.pickup ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  stop.address,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Stop ${stop.order + 1}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareRow(CarpoolRider rider, BuildContext context) {
    final fare = riderFares[rider.riderId] ?? 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            rider.riderName.isNotEmpty ? rider.riderName : 'Rider',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            '\$${fare.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(CarpoolRiderStatus status) {
    switch (status) {
      case CarpoolRiderStatus.waiting:
        return Colors.orange;
      case CarpoolRiderStatus.pickedUp:
        return Colors.blue;
      case CarpoolRiderStatus.droppedOff:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(CarpoolRiderStatus status) {
    switch (status) {
      case CarpoolRiderStatus.waiting:
        return 'Waiting';
      case CarpoolRiderStatus.pickedUp:
        return 'Picked Up';
      case CarpoolRiderStatus.droppedOff:
        return 'Dropped Off';
      default:
        return 'Unknown';
    }
  }

  double _calculateTotalFare() {
    return riderFares.values.fold(0.0, (sum, fare) => sum + fare);
  }
}
