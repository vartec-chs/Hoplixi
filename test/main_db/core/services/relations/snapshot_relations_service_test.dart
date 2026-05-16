import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/services/relations/snapshot_relations_service.dart';
import 'package:hoplixi/main_db/core/tables/tables.dart';
import 'package:uuid/uuid.dart';

import '../../test_utils/test_data_factory.dart';
import '../../test_utils/test_main_store.dart';
import '../../test_utils/test_service_factory.dart';

void main() {
  late MainStore db;
  late SnapshotRelationsService service;
  late TestDataFactory dataFactory;

  setUp(() {
    db = createTestStore();
    final serviceFactory = TestServiceFactory(db);
    service = serviceFactory.createSnapshotRelationsService();
    dataFactory = TestDataFactory(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SnapshotRelationsService', () {
    test('snapshotCategoryForItem creates category history snapshot', () async {
      final categoryId = await dataFactory.insertCategory(name: 'Work');
      final itemId = await dataFactory.insertApiKeyRaw(categoryId: categoryId);
      final snapshotId = const Uuid().v4();

      final categoryHistoryId = await service.snapshotCategoryForItem(
        categoryId: categoryId,
        itemId: itemId,
        snapshotId: snapshotId,
      );

      expect(categoryHistoryId != null, true);

      final count = await dataFactory.countTable(db.itemCategoryHistory);
      expect(count, 1);

      final history = await db.itemCategoryHistoryDao.getCategoryHistoryById(categoryHistoryId!);
      expect(history != null, true);
      expect(history!.categoryId, categoryId);
      expect(history.name, 'Work');
      expect(history.snapshotId, snapshotId);
      expect(history.itemId, itemId);
    });

    test('snapshotCategoryForItem returns null when categoryId is null', () async {
      final snapshotId = const Uuid().v4();
      final result = await service.snapshotCategoryForItem(
        categoryId: null,
        itemId: 'item1',
        snapshotId: snapshotId,
      );

      expect(result == null, true);
      final count = await dataFactory.countTable(db.itemCategoryHistory);
      expect(count, 0);
    });

    test('snapshotTagsForItem creates tag history rows', () async {
      final tag1Id = await dataFactory.insertTag(name: 'Tag1');
      final tag2Id = await dataFactory.insertTag(name: 'Tag2');
      final itemId = await dataFactory.insertApiKeyRaw();
      
      await db.itemTagsDao.assignTagToItem(itemId: itemId, tagId: tag1Id);
      await db.itemTagsDao.assignTagToItem(itemId: itemId, tagId: tag2Id);

      // IMPORTANT: historyId must reference vault_snapshots_history
      final historyId = await dataFactory.insertSnapshot(
        itemId: itemId,
        type: VaultItemType.apiKey,
      );

      await service.snapshotTagsForItem(
        historyId: historyId,
        itemId: itemId,
      );

      final count = await dataFactory.countTable(db.vaultItemTagHistory);
      expect(count, 2);

      final historyTags = await db.vaultItemTagHistoryDao.getTagsBySnapshotHistoryId(historyId);
      expect(historyTags.length, 2);
      
      final names = historyTags.map((t) => t.name).toSet();
      expect(names.contains('Tag1'), true);
      expect(names.contains('Tag2'), true);
      
      for (final t in historyTags) {
        expect(t.historyId, historyId);
        expect(t.itemId, itemId);
      }
    });

    test('snapshotLinksForItem creates item link history rows', () async {
      final item1Id = await dataFactory.insertApiKeyRaw(name: 'Item1');
      final item2Id = await dataFactory.insertApiKeyRaw(name: 'Item2');
      
      await db.itemLinksDao.insertItemLink(ItemLinksCompanion.insert(
        id: Value(const Uuid().v4()),
        sourceItemId: item1Id,
        targetItemId: item2Id,
        relationType: ItemLinkType.related,
        createdAt: Value(DateTime.now()),
        modifiedAt: Value(DateTime.now()),
      ));

      // IMPORTANT: historyId must reference vault_snapshots_history
      final historyId = await dataFactory.insertSnapshot(
        itemId: item1Id,
        type: VaultItemType.apiKey,
      );

      await service.snapshotLinksForItem(
        historyId: historyId,
        itemId: item1Id,
      );

      final count = await dataFactory.countTable(db.itemLinkHistory);
      expect(count, 1);

      final historyLinks = await db.itemLinkHistoryDao.getLinksBySnapshotHistoryId(historyId);
      expect(historyLinks.length, 1);
      expect(historyLinks.first.sourceItemId, item1Id);
      expect(historyLinks.first.targetItemId, item2Id);
      expect(historyLinks.first.historyId, historyId);
    });

    group('DbNotFoundError handling', () {
      test('snapshotCategoryForItem returns null if category not in DB', () async {
        final result = await service.snapshotCategoryForItem(
          categoryId: 'missing-category',
          itemId: 'item1',
          snapshotId: 'snap1',
        );
        expect(result == null, true);
      });
    });
   group('History Policies', () {
      test('isHistoryEnabled returns true by default', () async {
         final policyService = TestServiceFactory(db).createStoreHistoryPolicyService();
         expect(await policyService.isHistoryEnabled(), true);
      });
    });
  });
}
