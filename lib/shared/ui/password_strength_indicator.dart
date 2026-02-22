import 'package:flutter/material.dart';
import 'package:hoplixi/core/utils/password_strength_estimator.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.minHeight = 6,
    this.labelStyle,
    this.progressBorderRadius = 4,
    this.spacing = 12,
    this.showNumericScore = true,
  });

  static const PasswordStrengthEstimator _estimator =
      PasswordStrengthEstimator();

  final String password;
  final double minHeight;
  final TextStyle? labelStyle;
  final double progressBorderRadius;
  final double spacing;
  final bool showNumericScore;

  @override
  Widget build(BuildContext context) {
    final strengthResult = _estimator.evaluate(password);
    final strengthPercent = (strengthResult.score * 100).round();
    final color = _getStrengthColor(context, strengthResult.level);
    final label = _getStrengthLabel(strengthResult.level);
    final fullLabel = showNumericScore
        ? '$label • $strengthPercent/100'
        : label;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(progressBorderRadius),
            child: LinearProgressIndicator(
              value: strengthResult.score,
              minHeight: minHeight,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ),
        SizedBox(width: spacing),
        Text(
          fullLabel,
          style:
              labelStyle ??
              Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Color _getStrengthColor(BuildContext context, PasswordStrengthLevel level) {
    switch (level) {
      case PasswordStrengthLevel.weak:
        return Theme.of(context).colorScheme.error;
      case PasswordStrengthLevel.medium:
        return Colors.orange;
      case PasswordStrengthLevel.strong:
        return Colors.lightGreen;
      case PasswordStrengthLevel.excellent:
        return Colors.green;
    }
  }

  String _getStrengthLabel(PasswordStrengthLevel level) {
    switch (level) {
      case PasswordStrengthLevel.weak:
        return 'Слабый';
      case PasswordStrengthLevel.medium:
        return 'Средний';
      case PasswordStrengthLevel.strong:
        return 'Надёжный';
      case PasswordStrengthLevel.excellent:
        return 'Отличный';
    }
  }
}
