import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/card_utils.dart';

/// Универсальный компонент для отображения категории карточки
class CardCategoryBadge extends StatelessWidget {
  /// Название категории
  final String name;

  /// HEX цвет категории
  final String? color;

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
    final categoryColor = CardUtils.parseColor(color);

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
}
