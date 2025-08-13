import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RatingWidget extends StatefulWidget {
  final int initialRating;
  final Function(int) onRatingChanged;
  final double size;
  final Color? color;
  final bool allowHalfRating;

  const RatingWidget({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 40.0,
    this.color,
    this.allowHalfRating = false,
  });

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget>
    with SingleTickerProviderStateMixin {
  late int _rating;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Rating Stars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _rating = index + 1;
                });
                widget.onRatingChanged(_rating);
                _animationController.forward().then((_) {
                  _animationController.reverse();
                });
              },
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        size: widget.size,
                        color: index < _rating
                            ? (widget.color ?? Colors.amber)
                            : Colors.grey[400],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // Rating Text
        Text(
          _getRatingText(_rating),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),

        // Rating Description
        Text(
          _getRatingDescription(_rating),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Very disappointing experience';
      case 2:
        return 'Below average service';
      case 3:
        return 'Satisfactory but could be better';
      case 4:
        return 'Great experience overall';
      case 5:
        return 'Outstanding service and experience';
      default:
        return 'Select a rating to provide feedback';
    }
  }
}

class RatingDisplayWidget extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final double size;
  final bool showText;
  final bool showCount;

  const RatingDisplayWidget({
    super.key,
    required this.rating,
    this.totalRatings = 0,
    this.size = 20.0,
    this.showText = true,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stars
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1;
            final isFilled = starValue <= rating;
            final isHalfFilled = !isFilled && (rating - index) > 0;

            return Icon(
              isFilled
                  ? Icons.star
                  : isHalfFilled
                      ? Icons.star_half
                      : Icons.star_border,
              size: size,
              color: isFilled || isHalfFilled ? Colors.amber : Colors.grey[400],
            );
          }),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.poppins(
              fontSize: size * 0.6,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
        if (showCount && totalRatings > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($totalRatings)',
            style: GoogleFonts.poppins(
              fontSize: size * 0.5,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}
