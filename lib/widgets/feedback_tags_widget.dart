import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FeedbackTagsWidget extends StatefulWidget {
  final List<String> selectedTags;
  final Function(List<String>) onTagsChanged;
  final bool isForDriver; // true if rating a driver, false if rating a rider

  const FeedbackTagsWidget({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
    required this.isForDriver,
  });

  @override
  State<FeedbackTagsWidget> createState() => _FeedbackTagsWidgetState();
}

class _FeedbackTagsWidgetState extends State<FeedbackTagsWidget> {
  late List<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.selectedTags);
  }

  @override
  Widget build(BuildContext context) {
    final availableTags = widget.isForDriver ? _getDriverTags() : _getRiderTags();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What went well? (Optional)',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTags.remove(tag);
                  } else {
                    if (_selectedTags.length < 5) { // Limit to 5 tags
                      _selectedTags.add(tag);
                    }
                  }
                });
                widget.onTagsChanged(_selectedTags);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    if (isSelected) const SizedBox(width: 4),
                    Text(
                      tag,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedTags.length >= 5) ...[
          const SizedBox(height: 8),
          Text(
            'Maximum 5 tags selected',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.orange[600],
            ),
          ),
        ],
      ],
    );
  }

  List<String> _getDriverTags() {
    return [
      'Safe Driving',
      'Clean Vehicle',
      'Punctual',
      'Friendly',
      'Professional',
      'Good Communication',
      'Smooth Ride',
      'Helpful',
      'Courteous',
      'Knowledgeable',
      'Good Route',
      'Comfortable',
      'On Time',
      'Well Maintained',
      'Good Music',
      'Conversational',
      'Quiet Ride',
      'Efficient',
    ];
  }

  List<String> _getRiderTags() {
    return [
      'Punctual',
      'Friendly',
      'Respectful',
      'Clean',
      'Good Communication',
      'Patient',
      'Courteous',
      'Helpful',
      'Polite',
      'Understanding',
      'Cooperative',
      'Good Behavior',
      'No Issues',
      'Easy to Locate',
      'Ready on Time',
      'Good Directions',
      'Appreciative',
      'Professional',
    ];
  }
}

class FeedbackTagsDisplayWidget extends StatelessWidget {
  final List<String> tags;
  final double size;

  const FeedbackTagsDisplayWidget({
    super.key,
    required this.tags,
    this.size = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: tags.map((tag) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: size * 0.8,
            vertical: size * 0.4,
          ),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(size * 0.8),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            tag,
            style: GoogleFonts.poppins(
              fontSize: size,
              fontWeight: FontWeight.w500,
              color: Colors.blue[700],
            ),
          ),
        );
      }).toList(),
    );
  }
}
