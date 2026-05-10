import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/button.dart';

/// Универсальный компонент для кнопок действий карточки (удаление, восстановление, архивация)
class CardActionButtons extends StatelessWidget {
  /// Флаг удаления записи
  final bool isDeleted;

  /// Флаг архивации записи
  final bool isArchived;

  /// Колбэк восстановления
  final VoidCallback? onRestore;

  /// Колбэк удаления
  final VoidCallback? onDelete;

  /// Колбэк переключения архивации
  final VoidCallback? onToggleArchive;

  /// Колбэк открытия истории изменений
  final VoidCallback? onOpenHistory;

  const CardActionButtons({
    super.key,
    required this.isDeleted,
    required this.isArchived,
    this.onRestore,
    this.onDelete,
    this.onToggleArchive,
    this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (isDeleted) {
      return Row(
        children: [
          Expanded(
            child: SmoothButton(
              label: 'Восстановить',
              onPressed: onRestore,
              type: SmoothButtonType.text,
              size: SmoothButtonSize.small,
              variant: SmoothButtonVariant.success,
              icon: const Icon(Icons.restore, size: 16),
              iconPosition: SmoothButtonIconPosition.start,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SmoothButton(
              label: 'Удалить навсегда',
              onPressed: onDelete,
              type: SmoothButtonType.text,
              size: SmoothButtonSize.small,
              variant: SmoothButtonVariant.error,
              icon: const Icon(Icons.delete_forever, size: 16),
              iconPosition: SmoothButtonIconPosition.start,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [
        Row(
          children: [
            Expanded(
              child: SmoothButton(
                label: isArchived ? 'Разархивировать' : 'Архивировать',
                onPressed: onToggleArchive,
                size: SmoothButtonSize.small,
                type: SmoothButtonType.text,
                variant: SmoothButtonVariant.info,
                icon: Icon(
                  isArchived ? Icons.unarchive : Icons.archive,
                  size: 16,
                ),
                iconPosition: SmoothButtonIconPosition.start,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SmoothButton(
                label: 'Удалить',
                onPressed: onDelete,
                size: SmoothButtonSize.small,
                type: SmoothButtonType.text,
                variant: SmoothButtonVariant.error,
                icon: const Icon(Icons.delete_outline, size: 16),
                iconPosition: SmoothButtonIconPosition.start,
              ),
            ),
          ],
        ),
        if (onOpenHistory != null) ...[
          const SizedBox(height: 8),
          SmoothButton.text(
            label: 'История изменений',
            onPressed: onOpenHistory,
            size: SmoothButtonSize.small,
            variant: SmoothButtonVariant.info,
            icon: const Icon(Icons.history, size: 16),
            iconPosition: SmoothButtonIconPosition.start,
          ),
        ],
      ],
    );
  }
}
