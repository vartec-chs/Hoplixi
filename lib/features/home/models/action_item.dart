import 'package:flutter/material.dart';

/// Модель данных для кнопки действия на главном экране.
class ActionItem {
  const ActionItem({
    required this.icon,
    required this.label,
    this.description,
    this.isPrimary = false,
    this.disabled = false,
    this.onTap,
    this.showcaseKey,
    this.showcaseTitle,
    this.showcaseDescription,
    this.useCustomShowcaseTooltip = false,
  });

  final IconData icon;
  final String label;
  final String? description;
  final bool isPrimary;
  final bool disabled;
  final VoidCallback? onTap;
  final GlobalKey? showcaseKey;
  final String? showcaseTitle;
  final String? showcaseDescription;
  final bool useCustomShowcaseTooltip;
}
