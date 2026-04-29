import 'package:flutter/material.dart';

class LengthSlider extends StatelessWidget {
  const LengthSlider({
    required this.length,
    required this.minLength,
    required this.maxLength,
    required this.onChanged,
    super.key,
  });

  final double length;
  final int minLength;
  final int maxLength;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalDivisions = maxLength - minLength;

    return Row(
      children: [
        Text('Длина: ${length.round()}', style: theme.textTheme.bodyMedium),
        Expanded(
          child: Slider(
            value: length,
            min: minLength.toDouble(),
            max: maxLength.toDouble(),
            divisions: totalDivisions > 0 ? totalDivisions : null,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
