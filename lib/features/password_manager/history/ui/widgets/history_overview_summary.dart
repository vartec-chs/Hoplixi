import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/history/models/history_v2_models.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';

import 'history_view_helpers.dart';

class HistoryHeroSummaryCard extends StatelessWidget {
  const HistoryHeroSummaryCard({super.key, required this.state});

  final HistoryScreenState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.t.history;
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.summary_title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              l10n.summary_count(Count: state.totalCount),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                HistorySummaryPill(
                  icon: Icons.sync_alt,
                  label: state.hasLiveEntity
                      ? context.t.history.compare_to_current
                      : context.t.history.compare_to_deleted,
                ),
                if (state.query.actionFilter != HistoryActionFilter.all)
                  HistorySummaryPill(
                    icon: Icons.tune,
                    label: historyActionFilterLabel(
                      context,
                      state.query.actionFilter,
                    ),
                  ),
                if (state.query.datePreset != HistoryDatePreset.all)
                  HistorySummaryPill(
                    icon: Icons.schedule,
                    label: historyDatePresetLabel(
                      context,
                      state.query.datePreset,
                    ),
                  ),
                if (state.query.search.isNotEmpty)
                  HistorySummaryPill(
                    icon: Icons.search,
                    label: state.query.search,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HistorySummaryPill extends StatelessWidget {
  const HistorySummaryPill({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Flexible(child: Text(label)),
          ],
        ),
      ),
    );
  }
}
