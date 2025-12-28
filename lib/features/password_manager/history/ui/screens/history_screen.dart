import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/history/models/history_list_state.dart';
import 'package:hoplixi/features/password_manager/history/providers/history_list_provider.dart';
import 'package:hoplixi/features/password_manager/history/ui/widgets/history_empty_state.dart';
import 'package:hoplixi/features/password_manager/history/ui/widgets/history_item_card.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/slider_button.dart';

/// Экран истории для любого типа сущности
///
/// Отображает историю изменений для конкретной записи с поддержкой:
/// - Пагинации при скролле
/// - Поиска по истории
/// - Удаления отдельных записей
/// - Удаления всей истории
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
  late final HistoryParams _params;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _params = HistoryParams(
      entityType: widget.entityType,
      entityId: widget.entityId,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Обработчик скролла для пагинации
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(historyListProvider(_params).notifier).loadMore();
    }
  }

  /// Удалить отдельную запись истории
  Future<void> _deleteHistoryItem(String historyItemId) async {
    final success = await ref
        .read(historyListProvider(_params).notifier)
        .deleteHistoryItem(historyItemId);

    if (mounted) {
      if (success) {
        Toaster.success(
          title: 'Запись удалена',
          description: 'Запись истории успешно удалена',
        );
      } else {
        Toaster.error(
          title: 'Ошибка',
          description: 'Не удалось удалить запись истории',
        );
      }
    }
  }

  /// Показать диалог подтверждения удаления всей истории
  Future<void> _showDeleteAllDialog() async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: 'Удалить всю историю?',
      content:
          'Все записи истории для "${widget.entityType.label}" будут безвозвратно удалены.',
    );

    if (confirmed && mounted) {
      final success = await ref
          .read(historyListProvider(_params).notifier)
          .deleteAllHistory();

      if (mounted) {
        if (success) {
          Toaster.success(
            title: 'История очищена',
            description: 'Вся история успешно удалена',
          );
        } else {
          Toaster.error(
            title: 'Ошибка',
            description: 'Не удалось удалить историю',
          );
        }
      }
    }
  }

  /// Диалог подтверждения с SliderButton
  Future<bool> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(content),
            const SizedBox(height: 24),
            SliderButton(
              type: SliderButtonType.delete,
              text: 'Удалить',
              onSlideCompleteAsync: () async {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // final historyAsync = ref.watch(historyListProvider(_params));
    // final searchState = ref.watch(historySearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('История: ${widget.entityType.label}'),
        actions: [
          // Кнопка обновления
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(historyListProvider(_params).notifier).refresh(),
            tooltip: 'Обновить',
          ),
          // Кнопка удаления всей истории
          // historyAsync.maybeWhen(
          //   data: (state) => state.items.isNotEmpty
          //       ? IconButton(
          //           icon: const Icon(Icons.delete_sweep),
          //           onPressed: _showDeleteAllDialog,
          //           tooltip: 'Удалить всю историю',
          //         )
          //       : const SizedBox.shrink(),
          //   orElse: () => const SizedBox.shrink(),
          // ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          // HistorySearchBar(
          //   initialQuery: searchState.query,
          //   onSearchChanged: (query) {
          //     ref.read(historySearchProvider.notifier).updateQuery(query);
          //   },
          //   onClear: () {
          //     ref.read(historySearchProvider.notifier).clearSearch();
          //   },
          // ),

          // Контент
          // Expanded(
          //   child: historyAsync.when(
          //     loading: () => const Center(child: CircularProgressIndicator()),
          //     error: (error, stack) => _ErrorState(
          //       error: error.toString(),
          //       onRetry: () =>
          //           ref.read(historyListProvider(_params).notifier).refresh(),
          //     ),
          //     data: (state) => _HistoryContent(
          //       state: state,
          //       scrollController: _scrollController,
          //       isSearchActive: searchState.hasActiveSearch,
          //       onDeleteItem: _deleteHistoryItem,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

/// Контент списка истории
class _HistoryContent extends StatelessWidget {
  const _HistoryContent({
    required this.state,
    required this.scrollController,
    required this.isSearchActive,
    required this.onDeleteItem,
  });

  final HistoryListState state;
  final ScrollController scrollController;
  final bool isSearchActive;
  final Future<void> Function(String) onDeleteItem;

  @override
  Widget build(BuildContext context) {
    // Пустое состояние
    if (state.isEmpty) {
      return HistoryEmptyState(isSearchActive: isSearchActive);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Обновление через провайдер будет реализовано в родительском виджете
      },
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Информация о количестве записей
          SliverToBoxAdapter(
            child: _HistoryHeader(
              count: state.items.length,
              totalCount: state.totalCount,
            ),
          ),

          // Список истории
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = state.items[index];
              return HistoryItemCard(
                key: ValueKey('history_item_${item.id}'),
                item: item,
                onDelete: () => onDeleteItem(item.id),
              );
            }, childCount: state.items.length),
          ),

          // Индикатор загрузки следующей страницы
          if (state.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          // Отступ снизу
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }
}

/// Заголовок с количеством записей
class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.count, required this.totalCount});

  final int count;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.history,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Показано $count из $totalCount записей',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Состояние ошибки
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SmoothButton(
              label: 'Повторить',
              onPressed: onRetry,
              type: SmoothButtonType.filled,
            ),
          ],
        ),
      ),
    );
  }
}
