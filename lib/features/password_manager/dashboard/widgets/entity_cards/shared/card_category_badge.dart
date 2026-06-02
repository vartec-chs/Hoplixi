import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/entity_cards/shared/shared.dart';

/// Универсальный компонент для отображения категории карточки
class CardCategoryBadge extends StatelessWidget {
  /// Название категории
  final String name;

  /// Цвет категории в формате ARGB int (0xAARRGGBB) или HEX-строка
  final Object? color;

  /// Размер шрифта
  final double fontSize;

  /// Показывать иконку
  final bool showIcon;

  const CardCategoryBadge({
    super.key,
    required this.name,
    this.color,
    this.fontSize = 10,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _resolveColor(color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: categoryColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(Icons.folder, size: 14, color: categoryColor),
            const SizedBox(width: 4),
          ],
          Text(
            name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: categoryColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _resolveColor(Object? raw) {
    if (raw == null) return Colors.grey;
    if (raw is int) {
      if (raw == 0) return Colors.grey;
      return Color(raw);
    }
    if (raw is String) {
      return CardUtils.parseColor(raw);
    }
    return Colors.grey;
  }
}
