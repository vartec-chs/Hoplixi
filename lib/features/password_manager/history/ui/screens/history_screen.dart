import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/history/models/history_v2_models.dart';
import 'package:hoplixi/features/password_manager/history/providers/history_controller_provider.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/shared/ui/modal_sheet_close_button.dart';
import 'package:hoplixi/shared/ui/slider_button.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../widgets/history_overview_detail.dart';
import '../widgets/history_overview_shell.dart';
import '../widgets/history_view_helpers.dart';

enum _HistoryAppBarAction { clearAllHistory }

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
                return HistoryDetailPanel(
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

  Future<void> _showFiltersSheet(HistoryScreenState screenState) async {
    final l10n = context.t.history;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.action_filter_label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HistoryActionFilter.values
                    .map(
                      (filter) => ChoiceChip(
                        label: Text(historyActionFilterLabel(context, filter)),
                        selected: screenState.query.actionFilter == filter,
                        onSelected: (_) async {
                          await ref
                              .read(historyControllerProvider(_scope).notifier)
                              .setActionFilter(filter);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.date_filter_label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HistoryDatePreset.values
                    .map(
                      (preset) => ChoiceChip(
                        label: Text(historyDatePresetLabel(context, preset)),
                        selected: screenState.query.datePreset == preset,
                        onSelected: (_) async {
                          await ref
                              .read(historyControllerProvider(_scope).notifier)
                              .setDatePreset(preset);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final controller = ref.read(
                        historyControllerProvider(_scope).notifier,
                      );
                      _searchController.clear();
                      await controller.setSearch('');
                      await controller.setActionFilter(HistoryActionFilter.all);
                      await controller.setDatePreset(HistoryDatePreset.all);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: Text(context.t.common.clear),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteRevision(HistoryTimelineItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.t.history.delete_revision),
        content: Text(
          context.t.history.delete_revision_description(Name: item.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.t.history.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.t.common.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(historyControllerProvider(_scope).notifier)
        .deleteRevision(item.revisionId);
    if (!mounted) return;
    if (success) {
      Toaster.success(title: context.t.history.revision_deleted);
    } else {
      Toaster.error(title: context.t.history.revision_delete_error);
    }
  }

  Future<void> _confirmClearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.t.history.clear_history),
        content: Text(context.t.history.clear_history_description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.t.history.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.t.common.clear),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(historyControllerProvider(_scope).notifier)
        .clearAllHistory();
    if (!mounted) return;
    if (success) {
      Toaster.success(title: context.t.history.history_cleared);
    } else {
      Toaster.error(title: context.t.history.history_clear_error);
    }
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
          PopupMenuButton<_HistoryAppBarAction>(
            onSelected: (action) {
              switch (action) {
                case _HistoryAppBarAction.clearAllHistory:
                  _confirmClearAllHistory();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<_HistoryAppBarAction>(
                value: _HistoryAppBarAction.clearAllHistory,
                child: Text(l10n.clear_history),
              ),
            ],
          ),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => HistoryCenteredShell(
          child: HistoryErrorView(
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

          return HistoryCenteredShell(
            child: HistoryNarrowLayout(
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
              onOpenFilters: () => _showFiltersSheet(screenState),
              onSelect: _showDetailSheet,
              onDeleteRevision: _confirmDeleteRevision,
            ),
          );
        },
      ),
    );
  }
}
