import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

final class DashboardV2BulkBar extends StatelessWidget {
  const DashboardV2BulkBar({
    required this.selectedCount,
    required this.onClear,
    super.key,
  });

  final int selectedCount;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.secondaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(LucideIcons.check, color: colors.onSecondaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Выбрано: $selectedCount',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.onSecondaryContainer,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Сбросить',
              onPressed: onClear,
              icon: Icon(LucideIcons.x, color: colors.onSecondaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}
