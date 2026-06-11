import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/item_links_graph/item_links_graph_providers.dart';
import 'package:hoplixi/features/password_manager/item_links_graph/widgets/graph_message.dart';
import 'package:hoplixi/features/password_manager/item_links_graph/widgets/item_links_graph_body.dart';
import 'package:hoplixi/features/password_manager/item_links_graph/widgets/item_links_graph_filters.dart';
import 'package:hoplixi/vault_db/core/models/item_links_graph/item_links_graph_models.dart';

const _logTag = 'ItemLinksGraphScreen';

/// Screen for the graph of directed item_links between VaultItems.
class ItemLinksGraphScreen extends ConsumerWidget {
  const ItemLinksGraphScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final graphAsync = ref.watch(itemLinksGraphProvider);
    final mode = ref.watch(itemLinksGraphModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Граф связей'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => ref.invalidate(itemLinksGraphProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          ItemLinksGraphFilters(
            mode: mode,
            onModeChanged: (nextMode) {
              ref.read(itemLinksGraphModeProvider.notifier).setMode(nextMode);
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: graphAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) {
                logError(
                  'Failed to load item links graph',
                  error: error,
                  stackTrace: stackTrace,
                  tag: _logTag,
                );
                return GraphMessage(
                  icon: Icons.error_outline,
                  title: 'Не удалось загрузить граф',
                  subtitle: 'Попробуйте обновить данные.',
                  action: FilledButton.icon(
                    onPressed: () => ref.invalidate(itemLinksGraphProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                );
              },
              data: (result) {
                return switch (result) {
                  ItemLinksGraphFilterRequired() => const GraphMessage(
                    icon: Icons.filter_alt_outlined,
                    title: 'Выберите тип связи',
                    subtitle:
                        'Для режима по типам нужен хотя бы один выбранный тип.',
                  ),
                  ItemLinksGraphLoaded(:final graph) => ItemLinksGraphBody(
                    graph: graph,
                    theme: theme,
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}
