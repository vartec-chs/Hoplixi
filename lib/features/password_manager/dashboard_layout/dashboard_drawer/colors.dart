import 'package:flutter/material.dart';

class ColorsHelper {
  static Color parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return value != null ? Color(0xFF000000 | value) : fallback;
  }

  static Color onColorFor(Color background) {
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}