import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/main_db/core/errors/db_error.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/services/vault_items_state_service.dart';
import 'package:hoplixi/main_db/core/tables/tables.dart';
import 'package:uuid/uuid.dart';

import '../test_utils/test_data_factory.dart';
import '../test_utils/test_main_store.dart';
import '../test_utils/test_service_factory.dart';

void main() {
  late MainStore db;
  late VaultItemsStateService service;
  late TestDataFactory dataFactory;

  setUp(() {
    db = createTestStore();
    final serviceFactory = TestServiceFactory(db);
    service = serviceFactory.createVaultItemsStateService();
    dataFactory = TestDataFactory(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('VaultItemsStateService', () {
    test('softDelete marks item as deleted and writes event and snapshot', () async {
      final itemId = await dataFactory.createApiKeyViaService(name: 'Test Key');

      final result = await service.softDelete(
        itemId: itemId,
        type: VaultItemType.apiKey,
      );

      expect(result.isSuccess(), true);

      final item = await db.vaultItemsDao.getVaultItemById(itemId);
      expect(item!.isDeleted, true);
      expect(item.deletedAt != null, true);

      final events = await db.vaultEventsHistoryDao.getEventsByItemId(itemId);
      final deleteEvent = events.firstWhere((e) => e.action == VaultEventHistoryAction.deleted);
      expect(deleteEvent.snapshotHistoryId != null, true);

      final snapshot = await db.vaultSnapshotsHistoryDao.getSnapshotById(deleteEvent.snapshotHistoryId!);
      expect(snapshot!.isDeleted, false); // Snapshot before delete
    });

    test('recover restores deleted item and writes event and snapshot', () async {
      final itemId = await dataFactory.createApiKeyViaService(name: 'Test Key');
      await service.softDelete(itemId: itemId, type: VaultItemType.apiKey);

      final result = await service.recover(
        itemId: itemId,
        type: VaultItemType.apiKey,
      );

      expect(result.isSuccess(), true);

      final item = await db.vaultItemsDao.getVaultItemById(itemId);
      expect(item!.isDeleted, false);
      expect(item.deletedAt == null, true);

      final events = await db.vaultEventsHistoryDao.getEventsByItemId(itemId);
      final recoverEvent = events.firstWhere((e) => e.action == VaultEventHistoryAction.recovered);
      expect(recoverEvent.snapshotHistoryId != null, true);

      final snapshot = await db.vaultSnapshotsHistoryDao.getSnapshotById(recoverEvent.snapshotHistoryId!);
      expect(snapshot!.isDeleted, true); // Snapshot before recover
    });

    test('archive marks item as archived and writes event and snapshot', () async {
      final itemId = await dataFactory.createApiKeyViaService(name: 'Test Key');

      final result = await service.archive(
        itemId: itemId,
        type: VaultItemType.apiKey,
      );

      expect(result.isSuccess(), true);

      final item = await db.vaultItemsDao.getVaultItemById(itemId);
      expect(item!.isArchived, true);
      expect(item.archivedAt != null, true);

      final events = await db.vaultEventsHistoryDao.getEventsByItemId(itemId);
      final archiveEvent = events.firstWhere((e) => e.action == VaultEventHistoryAction.archived);
      expect(archiveEvent.snapshotHistoryId != null, true);

      final snapshot = await db.vaultSnapshotsHistoryDao.getSnapshotById(archiveEvent.snapshotHistoryId!);
      expect(snapshot!.isArchived, false); // Snapshot before archive
    });

    test('restoreArchived restores archived item and writes event and snapshot', () async {
      final itemId = await dataFactory.createApiKeyViaService(name: 'Test Key');
      await service.archive(itemId: itemId, type: VaultItemType.apiKey);

      final result = await service.restoreArchived(
        itemId: itemId,
        type: VaultItemType.apiKey,
      );

      expect(result.isSuccess(), true);

      final item = await db.vaultItemsDao.getVaultItemById(itemId);
      expect(item!.isArchived, false);
      expect(item.archivedAt == null, true);

      final events = await db.vaultEventsHistoryDao.getEventsByItemId(itemId);
      final restoreEvent = events.firstWhere((e) => e.action == VaultEventHistoryAction.restored);
      expect(restoreEvent.snapshotHistoryId != null, true);

      final snapshot = await db.vaultSnapshotsHistoryDao.getSnapshotById(restoreEvent.snapshotHistoryId!);
      expect(snapshot!.isArchived, true); // Snapshot before restore
    });

    test('setFavorite true marks item favorite and writes event', () async {
      final itemId = await dataFactory.createApiKeyViaService(name: 'Test Key');

      final result = await service.setFavorite(
        itemId: itemId,
        type: VaultItemType.apiKey,
        value: true,
      );

      expect(result.isSuccess(), true);

      final item = await db.vaultItemsDao.getVaultItemById(itemId);
      expect(item!.isFavorite, true);

      final events = await db.vaultEventsHistoryDao.getEventsByItemId(itemId);
      final favoriteEvent = events.firstWhere((e) => e.action == VaultEventHistoryAction.favorited);
      expect(favoriteEvent.snapshotHistoryId != null, true);

      final snapshot = await db.vaultSnapshotsHistoryDao.getSnapshotById(favoriteEvent.snapshotHistoryId!);
      expect(snapshot!.isFavorite, false);
    });

    test('setFavorite false marks item unfavorite and writes event', () async {
      final itemId = await dataFactory.createApiKeyViaService(name: 'Test Key');
      await service.setFavorite(itemId: itemId, type: VaultItemType.apiKey, value: true);

      final result = await service.setFavorite(
        itemId: itemId,
        type: VaultItemType.apiKey,
        value: false,
      );

      expect(result.isSuccess(), true);

      final item = await db.vaultItemsDao.getVaultItemById(itemId);
      expect(item!.isFavorite, false);

      final events = await db.vaultEventsHistoryDao.getEventsByItemId(itemId);
      final unfavoriteEvent = events.firstWhere((e) => e.action == VaultEventHistoryAction.unfavorited);
      expect(unfavoriteEvent.snapshotHistoryId != null, true);

      final snapshot = await db.vaultSnapshotsHistoryDao.getSnapshotById(unfavoriteEvent.snapshotHistoryId!);
      expect(snapshot!.isFavorite, true);
    });

    test('setPinned true marks item pinned and writes event', () async {
      final itemId = await dataFactory.createApiKeyViaService(name: 'Test Key');

      final result = await service.setPinned(
        itemId: itemId,
        type: VaultItemType.apiKey,
        value: true,
      );

      expect(result.isSuccess(), true);

      final item = await db.vaultItemsDao.getVaultItemById(itemId);
      expect(item!.isPinned, true);

      final events = await db.vaultEventsHistoryDao.getEventsByItemId(itemId);
      final pinnedEvent = events.firstWhere((e) => e.action == VaultEventHistoryAction.pinned);
      expect(pinnedEvent.snapshotHistoryId != null, true);
    });

    test('setPinned false marks item unpinned and writes event', () async {
      final itemId = await dataFactory.createApiKeyViaService(name: 'Test Key');
      await service.setPinned(itemId: itemId, type: VaultItemType.apiKey, value: true);

      final result = await service.setPinned(
        itemId: itemId,
        type: VaultItemType.apiKey,
        value: false,
      );

      expect(result.isSuccess(), true);

      final item = await db.vaultItemsDao.getVaultItemById(itemId);
      expect(item!.isPinned, false);

      final events = await db.vaultEventsHistoryDao.getEventsByItemId(itemId);
      final unpinnedEvent = events.firstWhere((e) => e.action == VaultEventHistoryAction.unpinned);
      expect(unpinnedEvent.snapshotHistoryId != null, true);
    });

    test('notFound error is returned for unknown item', () async {
      final result = await service.softDelete(
        itemId: const Uuid().v4(),
        type: VaultItemType.apiKey,
      );

      expect(result.isError(), true);
      expect(result.exceptionOrNull(), isA<DbNotFoundError>());
    });
  });
}
