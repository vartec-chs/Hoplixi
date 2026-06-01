import 'package:flutter/material.dart';

class ColorsHelper {
  static Color parseColor(Object? color, Color fallback) {
    if (color == null) return fallback;
    final value = color is int
        ? color
        : int.tryParse(color.toString().replaceFirst('#', ''), radix: 16);
    return value != null ? Color(0xFF000000 | value) : fallback;
  }

  static Color onColorFor(Color background) {
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
