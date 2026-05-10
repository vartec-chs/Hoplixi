import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/button.dart';

/// Модель для кнопки действия в карточке
class CardActionItem {
  /// Текстовая метка кнопки
  final String label;

  /// Колбэк при нажатии
  final VoidCallback? onPressed;

  /// Иконка по умолчанию
  final IconData icon;

  /// Иконка при успешном выполнении (например, после копирования)
  final IconData? successIcon;

  /// Флаг успешного выполнения (для смены иконки)
  final bool isSuccess;

  /// Минимальная ширина кнопки
  final double? minWidth;

  const CardActionItem({
    required this.label,
    required this.onPressed,
    required this.icon,
    this.successIcon,
    this.isSuccess = false,
    this.minWidth,
  });
}

/// Горизонтально скроллируемый контейнер для кнопок действий карточки
class HorizontalScrollableActions extends StatelessWidget {
  /// Список элементов действий
  final List<CardActionItem> actions;

  /// Высота контейнера
  final double height;

  /// Отступ между кнопками
  final double spacing;

  const HorizontalScrollableActions({
    super.key,
    required this.actions,
    this.height = 36,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, _) => SizedBox(width: spacing),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _buildActionButton(action);
        },
      ),
    );
  }

  Widget _buildActionButton(CardActionItem action) {
    final displayIcon = action.isSuccess && action.successIcon != null
        ? action.successIcon!
        : action.icon;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: action.minWidth ?? 100),
      child: SmoothButton(
        label: action.label,
        onPressed: action.onPressed,
        type: SmoothButtonType.outlined,
        size: SmoothButtonSize.small,
        variant: SmoothButtonVariant.normal,
        icon: Icon(displayIcon, size: 16),
        iconPosition: SmoothButtonIconPosition.start,
      ),
    );
  }
}
