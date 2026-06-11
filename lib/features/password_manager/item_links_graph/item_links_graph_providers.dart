import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/core/models/item_links_graph/item_links_graph_models.dart';
import 'package:hoplixi/vault_db/providers/service_providers.dart';

final itemLinksGraphModeProvider =
    NotifierProvider.autoDispose<GraphModeNotifier, ItemLinksGraphMode>(
      GraphModeNotifier.new,
    );

final class GraphModeNotifier extends Notifier<ItemLinksGraphMode> {
  @override
  ItemLinksGraphMode build() => const AllItemLinksGraphMode();

  void setMode(ItemLinksGraphMode mode) {
    state = mode;
  }
}

final itemLinksGraphProvider =
    FutureProvider.autoDispose<ItemLinksGraphLoadResult>((ref) async {
      final mode = ref.watch(itemLinksGraphModeProvider);
      final service = await ref.watch(loadItemLinksGraphServiceProvider.future);
      final result = await service(mode);
      return result.getOrThrow();
    });
