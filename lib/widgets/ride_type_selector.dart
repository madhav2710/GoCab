import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ride_model.dart';

class RideTypeSelector extends StatelessWidget {
  final RideType selectedType;
  final Function(RideType) onTypeChanged;

  const RideTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ride Type',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRideTypeCard(
                context,
                RideType.solo,
                'Solo',
                'Private ride',
                Icons.person,
                selectedType == RideType.solo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRideTypeCard(
                context,
                RideType.carpool,
                'Carpool',
                'Share & save 20%',
                Icons.people,
                selectedType == RideType.carpool,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRideTypeCard(
    BuildContext context,
    RideType type,
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => onTypeChanged(type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.2)
                    : Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected ? Colors.white70 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
