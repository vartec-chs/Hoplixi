import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/history/models/history_v2_models.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';

import 'history_view_helpers.dart';

class HistoryTimelineRevisionCard extends StatelessWidget {
  const HistoryTimelineRevisionCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  final HistoryTimelineItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final warningStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.error,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.secondaryContainer.withValues(alpha: 0.75)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? colorScheme.secondary
                : colorScheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HistoryTimelineIcon(action: item.action),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: theme.textTheme.titleMedium),
                        if (item.subtitle?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      HistoryActionBadge(action: item.action),
                      PopupMenuButton<_TimelineItemMenuAction>(
                        onSelected: (action) {
                          switch (action) {
                            case _TimelineItemMenuAction.deleteRevision:
                              onDelete();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<_TimelineItemMenuAction>(
                            value: _TimelineItemMenuAction.deleteRevision,
                            child: Text(context.t.history.delete_revision),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  HistoryInfoChip(
                    icon: Icons.schedule,
                    label: historyFormatDateTime(item.actionAt),
                  ),
                  HistoryInfoChip(
                    icon: Icons.compare_arrows,
                    label: context.t.history.changed_fields(
                      Count: item.changedFieldsCount,
                    ),
                  ),
                  HistoryInfoChip(
                    icon: item.isRestorable
                        ? Icons.restore
                        : Icons.block_outlined,
                    label: item.isRestorable
                        ? context.t.history.restore_action
                        : context.t.history.restore_error,
                  ),
                ],
              ),
              if (item.changedFieldLabels.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.changedFieldLabels
                      .take(6)
                      .map((label) => Chip(label: Text(label)))
                      .toList(),
                ),
              ],
              if (!item.isRestorable && item.restoreWarnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(item.restoreWarnings.first, style: warningStyle),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryTimelineIcon extends StatelessWidget {
  const HistoryTimelineIcon({super.key, required this.action});

  final String action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (action) {
      'deleted' => (Icons.delete_outline, colorScheme.error),
      'modified' => (Icons.edit_outlined, colorScheme.secondary),
      'created' => (Icons.add_circle_outline, colorScheme.primary),
      _ => (Icons.history, colorScheme.tertiary),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class HistoryInfoChip extends StatelessWidget {
  const HistoryInfoChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15),
            const SizedBox(width: 6),
            Flexible(child: Text(label)),
          ],
        ),
      ),
    );
  }
}

class HistoryActionBadge extends StatelessWidget {
  const HistoryActionBadge({super.key, required this.action});

  final String action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color color;
    switch (action) {
      case 'deleted':
        color = colorScheme.errorContainer;
        break;
      case 'modified':
        color = colorScheme.secondaryContainer;
        break;
      default:
        color = colorScheme.tertiaryContainer;
    }
    return Chip(
      label: Text(historyActionLabel(context, action)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }
}

enum _TimelineItemMenuAction { deleteRevision }
