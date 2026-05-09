import 'package:flutter/material.dart';
import 'package:hoplixi/core/errors/app_error.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

final class DashboardV2ErrorBanner extends StatelessWidget {
  const DashboardV2ErrorBanner({
    required this.error,
    required this.onRetry,
    super.key,
  });

  final AppError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.errorContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(LucideIcons.shieldAlert, color: colors.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onErrorContainer,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Повторить',
              onPressed: onRetry,
              icon: Icon(LucideIcons.refreshCw, color: colors.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}
