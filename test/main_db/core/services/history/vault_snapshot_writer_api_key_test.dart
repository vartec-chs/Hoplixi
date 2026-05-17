import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/services/history/vault_snapshot_writer.dart';
import 'package:hoplixi/main_db/core/tables/tables.dart';

import '../../test_utils/test_data_factory.dart';
import '../../test_utils/test_main_store.dart';
import '../../test_utils/test_service_factory.dart';

void main() {
  late MainStore db;
  late VaultSnapshotWriter service;
  late TestDataFactory dataFactory;
  late TestServiceFactory serviceFactory;

  setUp(() {
    db = createTestStore();
    serviceFactory = TestServiceFactory(db);
    service = serviceFactory.createVaultSnapshotWriter();
    dataFactory = TestDataFactory(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('VaultSnapshotWriter ApiKey', () {
    test(
      'writeSnapshot for ApiKey writes key when includeSecrets is true',
      () async {
        final categoryId = await dataFactory.insertCategory();
        final tag1Id = await dataFactory.insertTag(name: 'T1');
        final itemId = await dataFactory.insertApiKeyRaw(
          categoryId: categoryId,
          key: 'secret-key',
        );
        await db.itemTagsDao.assignTagToItem(itemId: itemId, tagId: tag1Id);

        final view = await serviceFactory.createApiKeyRepository().getViewById(
          itemId,
        );
        expect(view, isNotNull);

        final historyId = await service.writeSnapshot(
          view: view!,
          action: VaultEventHistoryAction.created,
          includeSecrets: true,
          includeRelations: true,
        );

        if (historyId.isError()) {
          fail('writeSnapshot failed: ${historyId.exceptionOrNull()}');
        }

        expect(historyId, isNotEmpty);

        // Verify vault_snapshots_history
        final snapshot = await db.vaultSnapshotsHistoryDao.getSnapshotById(
          historyId.getOrThrow(),
        );
        expect(snapshot, isNotNull);
        expect(snapshot!.itemId, itemId);
        expect(snapshot.categoryHistoryId, isNotNull);

        // Verify api_key_history
        final apiKeyHistoryRows = await db.apiKeyHistoryDao
            .getApiKeyHistoryByHistoryId(historyId.getOrThrow());
        expect(apiKeyHistoryRows, isNotNull);
        expect(apiKeyHistoryRows!.key, 'secret-key');
        expect(apiKeyHistoryRows.service, 'GitHub');

        // Verify relations
        final categoryHistory = await db.itemCategoryHistoryDao
            .getCategoryHistoryById(snapshot.categoryHistoryId!);
        expect(categoryHistory, isNotNull);

        final tagHistoryRows = await db.vaultItemTagHistoryDao
            .getTagsBySnapshotHistoryId(historyId.getOrThrow());
        expect(tagHistoryRows.length, 1);
        expect(tagHistoryRows.first.name, 'T1');
      },
    );

    test(
      'writeSnapshot for ApiKey clears key when includeSecrets is false',
      () async {
        final itemId = await dataFactory.insertApiKeyRaw(key: 'secret-key');
        final view = await serviceFactory.createApiKeyRepository().getViewById(
          itemId,
        );

        final historyId = await service.writeSnapshot(
          view: view!,
          action: VaultEventHistoryAction.created,
          includeSecrets: false,
          includeRelations: true,
        );

        if (historyId.isError()) {
          fail('writeSnapshot failed: ${historyId.exceptionOrNull()}');
        }

        final apiKeyHistoryRows = await db.apiKeyHistoryDao
            .getApiKeyHistoryByHistoryId(historyId.getOrThrow());
        expect(apiKeyHistoryRows!.key, isNull);
        expect(apiKeyHistoryRows.service, 'GitHub');
      },
    );

    test(
      'writeSnapshot with includeRelations false does not write tag history',
      () async {
        final tag1Id = await dataFactory.insertTag();
        final itemId = await dataFactory.insertApiKeyRaw();
        await db.itemTagsDao.assignTagToItem(itemId: itemId, tagId: tag1Id);

        final view = await serviceFactory.createApiKeyRepository().getViewById(
          itemId,
        );

        final _ = await service.writeSnapshot(
          view: view!,
          action: VaultEventHistoryAction.created,
          includeSecrets: true,
          includeRelations: false,
        );

        final tagHistoryCount = await dataFactory.countTable(
          db.vaultItemTagHistory,
        );
        expect(tagHistoryCount, 0);
      },
    );
  });
}
