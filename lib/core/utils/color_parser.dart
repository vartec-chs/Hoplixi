import 'package:flutter/material.dart';

Color parseColor(String? colorString, BuildContext context) {
  final colorValue = int.tryParse(colorString ?? 'FFFFFF', radix: 16);
  return colorValue != null
      ? Color(0xFF000000 | colorValue)
      : Theme.of(context).colorScheme.primary;
}
