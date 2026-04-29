import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/history/models/history_v2_models.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';

import 'history_overview_summary.dart';
import 'history_overview_timeline.dart';
import 'history_view_helpers.dart';

class HistoryCenteredShell extends StatelessWidget {
  const HistoryCenteredShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: child,
      ),
    );
  }
}

class HistoryNarrowLayout extends StatelessWidget {
  const HistoryNarrowLayout({
    super.key,
    required this.state,
    required this.scrollController,
    required this.searchController,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onSearchChanged,
    required this.onOpenFilters,
    required this.onSelect,
    required this.onDeleteRevision,
  });

  final HistoryScreenState state;
  final ScrollController scrollController;
  final TextEditingController searchController;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilters;
  final Future<void> Function(HistoryTimelineItem item) onSelect;
  final Future<void> Function(HistoryTimelineItem item) onDeleteRevision;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.t.history;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            sliver: SliverList.list(
              children: [
                HistoryHeroSummaryCard(state: state),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.search_placeholder,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                onChanged: onSearchChanged,
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.search),
                                  hintText: l10n.search_placeholder,
                                  suffixIcon: state.query.search.isEmpty
                                      ? null
                                      : IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            searchController.clear();
                                            onSearchChanged('');
                                          },
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton.filledTonal(
                              onPressed: onOpenFilters,
                              icon: const Icon(Icons.tune),
                              tooltip: context.t.common.filters,
                            ),
                          ],
                        ),
                        if (state.query.hasActiveFilters) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (state.query.actionFilter !=
                                  HistoryActionFilter.all)
                                HistorySummaryPill(
                                  icon: Icons.tune,
                                  label: historyActionFilterLabel(
                                    context,
                                    state.query.actionFilter,
                                  ),
                                ),
                              if (state.query.datePreset !=
                                  HistoryDatePreset.all)
                                HistorySummaryPill(
                                  icon: Icons.schedule,
                                  label: historyDatePresetLabel(
                                    context,
                                    state.query.datePreset,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.revision_title,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (state.isRefreshing)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (state.timelineItems.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.empty_state, textAlign: TextAlign.center),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount:
                    state.timelineItems.length + (state.canLoadMore ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= state.timelineItems.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 12),
                      child: OutlinedButton(
                        onPressed: onLoadMore,
                        child: Text(l10n.loading_more),
                      ),
                    );
                  }

                  final item = state.timelineItems[index];
                  return HistoryTimelineRevisionCard(
                    item: item,
                    isSelected: item.revisionId == state.selectedRevisionId,
                    onTap: () => onSelect(item),
                    onDelete: () => onDeleteRevision(item),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
