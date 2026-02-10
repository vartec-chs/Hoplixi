import 'package:flutter/material.dart';

/// Компактная кнопка действия с вертикальной композицией (иконка, заголовок, описание)
class ActionButtonCompact extends StatelessWidget {
  /// Иконка кнопки
  final IconData icon;

  /// Заголовок кнопки
  final String label;

  /// Описание кнопки (опционально)
  final String? description;

  /// Является ли кнопка основной (primary)
  final bool isPrimary;

  /// Обработчик нажатия
  final VoidCallback? onTap;

  /// Включена ли кнопка
  final bool enabled;

  /// Отключена ли кнопка (приоритет над enabled)
  final bool disabled;

  const ActionButtonCompact({
    super.key,
    required this.icon,
    required this.label,
    this.description,
    this.isPrimary = false,
    this.onTap,
    this.enabled = true,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Проверяем: если disabled=true, то кнопка отключена, иначе используем enabled
    final isDisabled = disabled || !enabled;

    // Определяем цвета в зависимости от типа кнопки
    final backgroundColor = isPrimary
        ? colorScheme.primary
        : colorScheme.surfaceContainerLow;
    final foregroundColor = isPrimary
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final disabledBackgroundColor = isPrimary
        ? colorScheme.primary.withOpacity(0.38)
        : colorScheme.surfaceContainerLow.withOpacity(0.38);
    final disabledForegroundColor = foregroundColor.withOpacity(0.38);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPrimary && !isDisabled
            ? [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        elevation: 0,
        color: isDisabled ? disabledBackgroundColor : backgroundColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Иконка с фоном
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDisabled
                        ? disabledForegroundColor.withOpacity(0.1)
                        : foregroundColor.withOpacity(0.1),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isDisabled
                        ? disabledForegroundColor
                        : foregroundColor,
                  ),
                ),
                const SizedBox(height: 12),
                // Заголовок
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isDisabled
                        ? disabledForegroundColor
                        : foregroundColor,
                    fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                    letterSpacing: isPrimary ? 0.5 : 0,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Описание (если есть)
                if (description != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDisabled
                          ? disabledForegroundColor
                          : foregroundColor.withOpacity(0.65),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
