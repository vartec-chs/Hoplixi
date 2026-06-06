import 'package:flutter/material.dart';

/// Типы уведомлений
enum NotificationType { error, success, info, warning }

/// Базовый компонент для отображения уведомления
class NotificationCard extends StatelessWidget {
  final NotificationType type;
  final String text;
  final IconData? icon;
  final EdgeInsets padding;
  final double borderRadius;
  final void Function()? onDismiss;

  const NotificationCard({
    super.key,
    required this.type,
    required this.text,
    this.icon,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 12,
    this.onDismiss,
  });

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (type) {
      case NotificationType.error:
        return colorScheme.error.withValues(alpha: 0.12);
      case NotificationType.success:
        return const Color(0xFF4CAF50).withValues(alpha: 0.12);
      case NotificationType.info:
        return colorScheme.primary.withValues(alpha: 0.12);
      case NotificationType.warning:
        return Colors.orange.withValues(alpha: 0.12);
    }
  }

  Color _getTextColor(ColorScheme colorScheme) {
    switch (type) {
      case NotificationType.error:
        return colorScheme.error;
      case NotificationType.success:
        return const Color(0xFF4CAF50);
      case NotificationType.info:
        return colorScheme.primary;
      case NotificationType.warning:
        return Colors.orange;
    }
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.warning:
        return Icons.warning_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = _getBackgroundColor(colorScheme);
    final textColor = _getTextColor(colorScheme);
    final displayIcon = icon ?? _getDefaultIcon();

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: textColor.withValues(alpha: 0.2), width: 1),
      ),
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(displayIcon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: textColor),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                color: textColor.withValues(alpha: 0.6),
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}

/// Компонент для отображения ошибки
class ErrorNotificationCard extends StatelessWidget {
  final String text;
  final IconData? icon;
  final EdgeInsets padding;
  final double borderRadius;
  final void Function()? onDismiss;

  const ErrorNotificationCard({
    super.key,
    required this.text,
    this.icon,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 12,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationCard(
      type: NotificationType.error,
      text: text,
      icon: icon,
      padding: padding,
      borderRadius: borderRadius,
      onDismiss: onDismiss,
    );
  }
}

/// Компонент для отображения успеха
class SuccessNotificationCard extends StatelessWidget {
  final String text;
  final IconData? icon;
  final EdgeInsets padding;
  final double borderRadius;
  final void Function()? onDismiss;

  const SuccessNotificationCard({
    super.key,
    required this.text,
    this.icon,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 12,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationCard(
      type: NotificationType.success,
      text: text,
      icon: icon,
      padding: padding,
      borderRadius: borderRadius,
      onDismiss: onDismiss,
    );
  }
}

/// Компонент для отображения информации
class InfoNotificationCard extends StatelessWidget {
  final String text;
  final IconData? icon;
  final EdgeInsets padding;
  final double borderRadius;
  final void Function()? onDismiss;

  const InfoNotificationCard({
    super.key,
    required this.text,
    this.icon,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 12,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationCard(
      type: NotificationType.info,
      text: text,
      icon: icon,
      padding: padding,
      borderRadius: borderRadius,
      onDismiss: onDismiss,
    );
  }
}

/// Компонент для отображения предупреждения
class WarningNotificationCard extends StatelessWidget {
  final String text;
  final IconData? icon;
  final EdgeInsets padding;
  final double borderRadius;
  final void Function()? onDismiss;

  const WarningNotificationCard({
    super.key,
    required this.text,
    this.icon,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 12,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationCard(
      type: NotificationType.warning,
      text: text,
      icon: icon,
      padding: padding,
      borderRadius: borderRadius,
      onDismiss: onDismiss,
    );
  }
}
