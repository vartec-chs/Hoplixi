import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/models/field_update.dart';
import 'package:hoplixi/main_db/core/services/entities/api_key_service.dart';
import 'package:hoplixi/main_db/core/tables/tables.dart';

import '../../test_utils/test_data_factory.dart';
import '../../test_utils/test_main_store.dart';
import '../../test_utils/test_service_factory.dart';

void main() {
  late MainStore db;
  late ApiKeyService service;
  late TestDataFactory dataFactory;

  setUp(() {
    db = createTestStore();
    final serviceFactory = TestServiceFactory(db);
    service = serviceFactory.createApiKeyService();
    dataFactory = TestDataFactory(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ApiKeyService', () {
    test('create creates api key with category tags snapshot and event', () async {
      final categoryId = await dataFactory.insertCategory();
      final tag1Id = await dataFactory.insertTag(name: 'Tag1');
      final tag2Id = await dataFactory.insertTag(name: 'Tag2');

      final dto = CreateApiKeyDto(
        item: VaultItemCreateDto(
          name: 'My GitHub Key',
          categoryId: categoryId,
        ),
        apiKey: const ApiKeyDataDto(
          service: 'GitHub',
          key: 'secret-123',
        ),
        tagIds: [tag1Id, tag2Id],
      );

      final result = await service.create(dto);
      expect(result.isSuccess(), isTrue);
      final itemId = result.getOrThrow();

      // Verify live state
      final item = await db.vaultItemsDao.getVaultItemById(itemId);
      expect(item, isNotNull);
      expect(item!.type, VaultItemType.apiKey);
      expect(item.categoryId, categoryId);

      final apiKey = await db.apiKeyItemsDao.getApiKeyByItemId(itemId);
      expect(apiKey, isNotNull);
      expect(apiKey!.service, 'GitHub');
      expect(apiKey.key, 'secret-123');

      final itemTags = await db.itemTagsDao.getTagsForItem(itemId);
      expect(itemTags.length, 2);

      // Verify history
      final events = await db.vaultEventsHistoryDao.getEventsByItemId(itemId);
      expect(events.length, 1);
      expect(events.first.action, VaultEventHistoryAction.created);
      final snapshotId = events.first.snapshotHistoryId;
      expect(snapshotId, isNotNull);

      final apiKeyHistory = await db.apiKeyHistoryDao.getApiKeyHistoryByHistoryId(snapshotId!);
      expect(apiKeyHistory, isNotNull);
      expect(apiKeyHistory!.key, 'secret-123');

      final tagHistory = await db.vaultItemTagHistoryDao.getTagsBySnapshotHistoryId(snapshotId);
      expect(tagHistory.length, 2);
    });

    test('update replaces tags and stores old state snapshot', () async {
      final oldTagId = await dataFactory.insertTag(name: 'Old');
      final newTagId = await dataFactory.insertTag(name: 'New');
      
      final itemId = await dataFactory.createApiKeyViaService(
        name: 'Initial',
        service: 'OldService',
        key: 'old-secret',
        tagIds: [oldTagId],
      );

      final updateDto = PatchApiKeyDto(
        item: VaultItemPatchDto(
          itemId: itemId,
          name: const FieldUpdate.set('Updated Name'),
        ),
        apiKey: const PatchApiKeyDataDto(
          service: FieldUpdate.set('NewService'),
          key: FieldUpdate.set('new-secret'),
        ),
        tags: FieldUpdate.set([newTagId]),
      );

      final result = await service.update(updateDto);
      expect(result.isSuccess(), isTrue);

      // Verify live
      final apiKey = await db.apiKeyItemsDao.getApiKeyByItemId(itemId);
      expect(apiKey!.service, 'NewService');
      expect(apiKey.key, 'new-secret');

      final tags = await db.itemTagsDao.getTagsForItem(itemId);
      expect(tags.length, 1);
      expect(tags.first.tagId, newTagId);

      // Verify history (should have 2 events: created and updated)
      final events = await db.vaultEventsHistoryDao.getEventsByItemId(itemId);
      expect(events.length, 2);
      final updateEvent = events.firstWhere((e) => e.action == VaultEventHistoryAction.updated);
      
      final snapshotId = updateEvent.snapshotHistoryId;
      expect(snapshotId, isNotNull);

      // Snapshot should contain OLD values
      final historyRows = await db.apiKeyHistoryDao.getApiKeyHistoryByHistoryId(snapshotId!);
      expect(historyRows!.service, 'OldService');
      expect(historyRows.key, 'old-secret');
    });

    test('softDelete marks item deleted and writes snapshot event', () async {
      final itemId = await dataFactory.createApiKeyViaService(name: 'To Delete');

      final result = await service.softDelete(itemId);
      expect(result.isSuccess(), isTrue);

      final item = await db.vaultItemsDao.getVaultItemById(itemId);
      expect(item!.isDeleted, isTrue);
      expect(item.deletedAt, isNotNull);

      final events = await db.vaultEventsHistoryDao.getEventsByItemId(itemId);
      final deleteEvent = events.firstWhere((e) => e.action == VaultEventHistoryAction.deleted);
      expect(deleteEvent.snapshotHistoryId, isNotNull);

      final snapshot = await db.vaultSnapshotsHistoryDao.getSnapshotById(deleteEvent.snapshotHistoryId!);
      expect(snapshot!.isDeleted, isFalse); // Snapshot before delete
    });
  });
}
