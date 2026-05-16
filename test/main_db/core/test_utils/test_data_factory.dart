import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/tables/tables.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:uuid/uuid.dart';

import 'test_service_factory.dart';

class TestDataFactory {
  TestDataFactory(this.db);

  final MainStore db;

  Future<String> insertCategory({
    String name = 'Work',
    String color = 'FFFF0000', // 8 chars AARRGGBB
  }) async {
    final id = const Uuid().v4();
    await db.categoriesDao.insertCategory(
      CategoriesCompanion.insert(
        id: Value(id),
        name: name,
        color: Value(color),
        type: CategoryType.mixed,
        createdAt: Value(DateTime.now()),
        modifiedAt: Value(DateTime.now()),
      ),
    );
    return id;
  }

  Future<String> insertTag({
    String name = 'Important',
    String color = 'FF00FF00', // 8 chars AARRGGBB
  }) async {
    final id = const Uuid().v4();
    await db.tagsDao.insertTag(
      TagsCompanion.insert(
        id: Value(id),
        name: name,
        color: Value(color),
        type: TagType.mixed,
        createdAt: Value(DateTime.now()),
        modifiedAt: Value(DateTime.now()),
      ),
    );
    return id;
  }

  Future<String> insertApiKeyRaw({
    String name = 'GitHub API',
    String service = 'GitHub',
    String key = 'secret-key',
    String? categoryId,
  }) async {
    final itemId = const Uuid().v4();
    await db.transaction(() async {
      await db.vaultItemsDao.insertVaultItem(
        VaultItemsCompanion.insert(
          id: Value(itemId),
          type: VaultItemType.apiKey,
          name: name,
          categoryId: Value(categoryId),
          createdAt: Value(DateTime.now()),
          modifiedAt: Value(DateTime.now()),
        ),
      );
      await db.apiKeyItemsDao.insertApiKey(
        ApiKeyItemsCompanion.insert(
          itemId: itemId,
          service: service,
          key: key,
        ),
      );
    });
    return itemId;
  }

  Future<String> insertSnapshot({
    required String itemId,
    required VaultItemType type,
    String name = 'Snapshot',
    VaultEventHistoryAction action = VaultEventHistoryAction.created,
  }) async {
    final id = const Uuid().v4();
    await db.vaultSnapshotsHistoryDao.insertVaultSnapshot(
      VaultSnapshotsHistoryCompanion.insert(
        id: Value(id),
        itemId: itemId,
        type: type,
        name: name,
        action: action,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        historyCreatedAt: Value(DateTime.now()),
      ),
    );
    return id;
  }

  Future<String> createApiKeyViaService({
    String name = 'GitHub API',
    String service = 'GitHub',
    String key = 'secret-key',
    String? categoryId,
    List<String> tagIds = const [],
  }) async {
    final serviceFactory = TestServiceFactory(db);
    final apiKeyService = serviceFactory.createApiKeyService();

    final dto = CreateApiKeyDto(
      item: VaultItemCreateDto(
        name: name,
        categoryId: categoryId,
      ),
      apiKey: ApiKeyDataDto(
        service: service,
        key: key,
      ),
      tagIds: tagIds,
    );

    final result = await apiKeyService.create(dto);
    return result.getOrThrow();
  }

  Future<int> countTable<T extends TableInfo<Table, Object?>>(
    ResultSetImplementation<T, Object?> table,
  ) async {
    final countExp = countAll();
    final row = await (db.selectOnly(table)..addColumns([countExp])).getSingle();
    return row.read(countExp) ?? 0;
  }
}
