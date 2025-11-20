import 'package:flutter/material.dart';

class ColorUtils {
  /// Replaces deprecated withOpacity with withValues
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
}
