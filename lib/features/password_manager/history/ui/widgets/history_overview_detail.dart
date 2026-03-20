import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/history/models/history_v2_models.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/shared/ui/button.dart';

import 'history_overview_timeline.dart';
import 'history_view_helpers.dart';

class HistoryDetailPanel extends StatelessWidget {
  const HistoryDetailPanel({super.key, required this.detail, this.onRestore});

  final HistoryRevisionDetail detail;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.history;
    final theme = Theme.of(context);
    final diffs = [...detail.fieldDiffs, ...detail.customFieldDiffs];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(detail.snapshotTitle, style: theme.textTheme.headlineSmall),
          if (detail.snapshotSubtitle?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(detail.snapshotSubtitle!),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              HistoryInfoChip(
                icon: Icons.schedule,
                label: historyFormatDateTime(detail.actionAt),
              ),
              HistoryInfoChip(
                icon: Icons.sync_alt,
                label: historyCompareLabel(context, detail.compareTargetKind),
              ),
              HistoryActionBadge(action: detail.action),
            ],
          ),
          const SizedBox(height: 16),
          if (detail.restoreWarnings.isNotEmpty) ...[
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: detail.restoreWarnings
                      .map(
                        (warning) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('• $warning'),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (onRestore != null) ...[
            SizedBox(
              width: double.infinity,
              child: SmoothButton(
                label: l10n.restore_action,
                onPressed: onRestore,
                type: SmoothButtonType.filled,
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(l10n.metadata_title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          if (detail.metadata.entries
              .where((entry) => entry.value != null && entry.value!.isNotEmpty)
              .isEmpty)
            Text(l10n.empty_value)
          else
            Column(
              children: detail.metadata.entries
                  .where(
                    (entry) => entry.value != null && entry.value!.isNotEmpty,
                  )
                  .map(
                    (entry) => HistoryMetadataRow(
                      label: entry.key,
                      value: entry.value!,
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 20),
          Text(l10n.diff_title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          if (diffs.isEmpty)
            Text(l10n.no_diffs)
          else
            Column(
              children: diffs
                  .map((diff) => HistoryDiffCard(diff: diff))
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class HistoryMetadataRow extends StatelessWidget {
  const HistoryMetadataRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}

class HistoryDiffCard extends StatelessWidget {
  const HistoryDiffCard({super.key, required this.diff});

  final HistoryFieldDiff diff;

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.history;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(diff.label, style: theme.textTheme.titleSmall),
              ),
              Chip(label: Text(historyChangeLabel(context, diff.changeType))),
            ],
          ),
          const SizedBox(height: 10),
          Text('${l10n.before}: ${diff.oldValue ?? l10n.empty_value}'),
          const SizedBox(height: 6),
          Text('${l10n.after}: ${diff.newValue ?? l10n.empty_value}'),
        ],
      ),
    );
  }
}

class HistoryErrorView extends StatelessWidget {
  const HistoryErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            SmoothButton(
              label: context.t.history.retry,
              onPressed: onRetry,
              type: SmoothButtonType.filled,
            ),
          ],
        ),
      ),
    );
  }
}
