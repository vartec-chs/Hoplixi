import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/services/history/vault_history_service.dart';
import 'package:hoplixi/main_db/core/services/relations/vault_item_relations_service.dart';
import 'package:hoplixi/main_db/core/services/vault_typed_view_resolver.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';

class VaultItemMutationService {
  VaultItemMutationService({
    required this.db,
    required this.viewResolver,
    required this.relationsService,
    required this.historyService,
  });

  final MainStore db;
  final VaultTypedViewResolver viewResolver;
  final VaultItemRelationsService relationsService;
  final VaultHistoryService historyService;

  Future<void> replaceItemTags({
    required String itemId,
    required VaultItemType type,
    required List<String> tagIds,
  }) async {
    await db.transaction(() async {
      // 1. Получаем старое состояние для snapshot
      final oldView = await viewResolver.getView(itemId: itemId, type: type);
      if (oldView == null) {
        throw Exception('Vault item not found: $itemId');
      }

      // 2. Пишем snapshot before update
      final snapshotId = await historyService.snapshotBeforeUpdate(
        type: type,
        oldView: oldView,
        action: VaultEventHistoryAction.updated,
      );

      // 3. Заменяем теги
      await relationsService.replaceTags(itemId: itemId, tagIds: tagIds);

      // 4. Пишем event updated
      await historyService.writeEvent(
        itemId: itemId,
        type: type,
        action: VaultEventHistoryAction.updated,
        snapshotHistoryId: snapshotId,
      );
    });
  }

  Future<void> changeItemCategory({
    required String itemId,
    required VaultItemType type,
    required String? categoryId,
  }) async {
    await db.transaction(() async {
      // 1. Получаем старое состояние для snapshot
      final oldView = await viewResolver.getView(itemId: itemId, type: type);
      if (oldView == null) {
        throw Exception('Vault item not found: $itemId');
      }

      // 2. Пишем snapshot before update
      final snapshotId = await historyService.snapshotBeforeUpdate(
        type: type,
        oldView: oldView,
        action: VaultEventHistoryAction.updated,
      );

      // 3. Меняем категорию
      await relationsService.changeCategory(
        itemId: itemId,
        categoryId: categoryId,
      );

      // 4. Пишем event updated
      await historyService.writeEvent(
        itemId: itemId,
        type: type,
        action: VaultEventHistoryAction.updated,
        categoryId: categoryId,
        snapshotHistoryId: snapshotId,
      );
    });
  }
}
