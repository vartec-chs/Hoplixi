import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/history/models/history_v2_models.dart';
import 'package:hoplixi/features/password_manager/history/providers/history_controller_provider.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/modal_sheet_close_button.dart';
import 'package:hoplixi/shared/ui/slider_button.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({
    super.key,
    required this.entityType,
    required this.entityId,
  });

  final EntityType entityType;
  final String entityId;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;

  HistoryScope get _scope =>
      HistoryScope(entityType: widget.entityType, entityId: widget.entityId);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final controller = ref.read(historyControllerProvider(_scope).notifier);
    final state = ref.read(historyControllerProvider(_scope)).value;
    if (state == null || !state.canLoadMore) return;
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 220) {
      controller.loadMore();
    }
  }

  Future<void> _confirmRestore(HistoryTimelineItem item) async {
    final detail = ref
        .read(historyControllerProvider(_scope))
        .value
        ?.selectedDetail;
    final l10n = context.t.history;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.restore_title),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.restore_description(Name: item.title)),
              if (detail != null && detail.restoreWarnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...detail.restoreWarnings
                    .take(3)
                    .map(
                      (warning) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('• $warning'),
                      ),
                    ),
              ],
              const SizedBox(height: 20),
              SliderButton(
                type: SliderButtonType.confirm,
                text: l10n.restore_action,
                onSlideCompleteAsync: () async {
                  Navigator.of(dialogContext).pop(true);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(historyControllerProvider(_scope).notifier)
        .restoreRevision(item.revisionId);
    if (!mounted) return;
    if (success) {
      Toaster.success(title: l10n.restore_success);
    } else {
      Toaster.error(title: l10n.restore_error);
    }
  }

  Future<void> _showDetailSheet(HistoryTimelineItem item) async {
    await ref
        .read(historyControllerProvider(_scope).notifier)
        .selectRevision(item.revisionId);
    if (!mounted) return;

    await WoltModalSheet.show<void>(
      context: context,
      useRootNavigator: true,
      pageListBuilder: (_) => [
        WoltModalSheetPage(
          hasTopBarLayer: true,
          forceMaxHeight: true,
          topBarTitle: Text(context.t.history.revision_title),
          leadingNavBarWidget: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: ModalSheetCloseButton(),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Consumer(
              builder: (context, ref, _) {
                final screenState = ref
                    .watch(historyControllerProvider(_scope))
                    .value;
                final detail = screenState?.selectedDetail;
                if (detail == null) {
                  return const SizedBox.shrink();
                }
                return _DetailPanel(
                  detail: detail,
                  onRestore: detail.isRestorable
                      ? () => _confirmRestore(item)
                      : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(historyControllerProvider(_scope));
    final l10n = context.t.history;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screen_title(Entity: widget.entityType.label)),
        leading: const ModalSheetCloseButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: () =>
                ref.read(historyControllerProvider(_scope).notifier).refresh(),
          ),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _CenteredShell(
          child: _ErrorView(
            message: '$error',
            onRetry: () =>
                ref.read(historyControllerProvider(_scope).notifier).refresh(),
          ),
        ),
        data: (screenState) {
          if (_searchController.text != screenState.query.search) {
            _searchController.text = screenState.query.search;
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: _searchController.text.length),
            );
          }

          return _CenteredShell(
            child: _HistoryNarrowLayout(
              state: screenState,
              scrollController: _scrollController,
              searchController: _searchController,
              onRefresh: () => ref
                  .read(historyControllerProvider(_scope).notifier)
                  .refresh(),
              onLoadMore: () => ref
                  .read(historyControllerProvider(_scope).notifier)
                  .loadMore(),
              onSearchChanged: (value) => ref
                  .read(historyControllerProvider(_scope).notifier)
                  .setSearch(value),
              onActionFilterChanged: (filter) => ref
                  .read(historyControllerProvider(_scope).notifier)
                  .setActionFilter(filter),
              onDatePresetChanged: (preset) => ref
                  .read(historyControllerProvider(_scope).notifier)
                  .setDatePreset(preset),
              onClearFilters: () async {
                final controller = ref.read(
                  historyControllerProvider(_scope).notifier,
                );
                _searchController.clear();
                await controller.setSearch('');
                await controller.setActionFilter(HistoryActionFilter.all);
                await controller.setDatePreset(HistoryDatePreset.all);
              },
              onSelect: _showDetailSheet,
            ),
          );
        },
      ),
    );
  }
}

class _CenteredShell extends StatelessWidget {
  const _CenteredShell({required this.child});

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

class _HistoryNarrowLayout extends StatelessWidget {
  const _HistoryNarrowLayout({
    required this.state,
    required this.scrollController,
    required this.searchController,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onSearchChanged,
    required this.onActionFilterChanged,
    required this.onDatePresetChanged,
    required this.onClearFilters,
    required this.onSelect,
  });

  final HistoryScreenState state;
  final ScrollController scrollController;
  final TextEditingController searchController;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<HistoryActionFilter> onActionFilterChanged;
  final ValueChanged<HistoryDatePreset> onDatePresetChanged;
  final Future<void> Function() onClearFilters;
  final Future<void> Function(HistoryTimelineItem item) onSelect;

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
                _HeroSummaryCard(state: state),
                const SizedBox(height: 12),
                Card(
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
                        TextField(
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
                        const SizedBox(height: 14),
                        Text(
                          l10n.action_filter_label,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: HistoryActionFilter.values
                              .map(
                                (filter) => ChoiceChip(
                                  label: Text(
                                    _actionFilterLabel(context, filter),
                                  ),
                                  selected: state.query.actionFilter == filter,
                                  onSelected: (_) =>
                                      onActionFilterChanged(filter),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.date_filter_label,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: HistoryDatePreset.values
                              .map(
                                (preset) => ChoiceChip(
                                  label: Text(
                                    _datePresetLabel(context, preset),
                                  ),
                                  selected: state.query.datePreset == preset,
                                  onSelected: (_) =>
                                      onDatePresetChanged(preset),
                                ),
                              )
                              .toList(),
                        ),
                        if (state.query.hasActiveFilters) ...[
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: onClearFilters,
                              icon: const Icon(Icons.filter_alt_off_outlined),
                              label: Text(l10n.filter_all_actions),
                            ),
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                  return _TimelineRevisionCard(
                    item: item,
                    isSelected: item.revisionId == state.selectedRevisionId,
                    onTap: () => onSelect(item),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({required this.state});

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
                _SummaryPill(
                  icon: Icons.sync_alt,
                  label: state.hasLiveEntity
                      ? context.t.history.compare_to_current
                      : context.t.history.compare_to_deleted,
                ),
                if (state.query.actionFilter != HistoryActionFilter.all)
                  _SummaryPill(
                    icon: Icons.tune,
                    label: _actionFilterLabel(
                      context,
                      state.query.actionFilter,
                    ),
                  ),
                if (state.query.datePreset != HistoryDatePreset.all)
                  _SummaryPill(
                    icon: Icons.schedule,
                    label: _datePresetLabel(context, state.query.datePreset),
                  ),
                if (state.query.search.isNotEmpty)
                  _SummaryPill(icon: Icons.search, label: state.query.search),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.icon, required this.label});

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

class _TimelineRevisionCard extends StatelessWidget {
  const _TimelineRevisionCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final HistoryTimelineItem item;
  final bool isSelected;
  final VoidCallback onTap;

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
                  _TimelineIcon(action: item.action),
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
                  _ActionBadge(action: item.action),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.schedule,
                    label: _formatDateTime(item.actionAt),
                  ),
                  _InfoChip(
                    icon: Icons.compare_arrows,
                    label: context.t.history.changed_fields(
                      Count: item.changedFieldsCount,
                    ),
                  ),
                  _InfoChip(
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

class _TimelineIcon extends StatelessWidget {
  const _TimelineIcon({required this.action});

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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

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

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.detail, this.onRestore});

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
              _InfoChip(
                icon: Icons.schedule,
                label: _formatDateTime(detail.actionAt),
              ),
              _InfoChip(
                icon: Icons.sync_alt,
                label: _compareLabel(context, detail.compareTargetKind),
              ),
              _ActionBadge(action: detail.action),
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
                    (entry) =>
                        _MetadataRow(label: entry.key, value: entry.value!),
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
                  .map((diff) => _DiffCard(diff: diff))
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

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

class _DiffCard extends StatelessWidget {
  const _DiffCard({required this.diff});

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
              Chip(label: Text(_changeLabel(context, diff.changeType))),
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

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.action});

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
      label: Text(_actionLabel(context, action)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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

String _actionLabel(BuildContext context, String action) {
  final l10n = context.t.history;
  switch (action) {
    case 'modified':
      return l10n.action_modified;
    case 'deleted':
      return l10n.action_deleted;
    case 'created':
      return l10n.action_created;
    default:
      return action;
  }
}

String _actionFilterLabel(BuildContext context, HistoryActionFilter filter) {
  final l10n = context.t.history;
  switch (filter) {
    case HistoryActionFilter.all:
      return l10n.filter_all_actions;
    case HistoryActionFilter.modified:
      return l10n.action_modified;
    case HistoryActionFilter.deleted:
      return l10n.action_deleted;
  }
}

String _datePresetLabel(BuildContext context, HistoryDatePreset preset) {
  final l10n = context.t.history;
  switch (preset) {
    case HistoryDatePreset.all:
      return l10n.filter_all_time;
    case HistoryDatePreset.last7Days:
      return l10n.filter_last7_days;
    case HistoryDatePreset.last30Days:
      return l10n.filter_last30_days;
  }
}

String _compareLabel(BuildContext context, HistoryCompareTargetKind kind) {
  final l10n = context.t.history;
  switch (kind) {
    case HistoryCompareTargetKind.newerRevision:
      return l10n.compare_to_newer_revision;
    case HistoryCompareTargetKind.currentLive:
      return l10n.compare_to_current;
    case HistoryCompareTargetKind.deletedState:
      return l10n.compare_to_deleted;
  }
}

String _changeLabel(BuildContext context, HistoryFieldChangeType type) {
  final l10n = context.t.history;
  switch (type) {
    case HistoryFieldChangeType.added:
      return l10n.change_added;
    case HistoryFieldChangeType.removed:
      return l10n.change_removed;
    case HistoryFieldChangeType.changed:
      return l10n.change_changed;
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.$year $hour:$minute';
}
