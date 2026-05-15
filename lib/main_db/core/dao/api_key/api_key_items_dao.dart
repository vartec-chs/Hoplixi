import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../tables/api_key/api_key_items.dart';

part 'api_key_items_dao.g.dart';

@DriftAccessor(tables: [ApiKeyItems])
class ApiKeyItemsDao extends DatabaseAccessor<MainStore>
    with _$ApiKeyItemsDaoMixin {
  ApiKeyItemsDao(super.db);

  Future<void> insertApiKey(ApiKeyItemsCompanion companion) {
    return into(apiKeyItems).insert(companion);
  }

  Future<int> updateApiKeyByItemId(
    String itemId,
    ApiKeyItemsCompanion companion,
  ) {
    return (update(apiKeyItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .write(companion);
  }

  Future<ApiKeyItemsData?> getApiKeyByItemId(String itemId) {
    return (select(apiKeyItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .getSingleOrNull();
  }

  Future<bool> existsApiKeyByItemId(String itemId) async {
    final row = await (selectOnly(apiKeyItems)
          ..addColumns([apiKeyItems.itemId])
          ..where(apiKeyItems.itemId.equals(itemId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteApiKeyByItemId(String itemId) {
    return (delete(apiKeyItems)..where((tbl) => tbl.itemId.equals(itemId))).go();
  }
}
