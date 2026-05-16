import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/services/history/vault_event_history_service.dart';
import 'package:hoplixi/main_db/core/tables/tables.dart';

import '../../test_utils/test_data_factory.dart';
import '../../test_utils/test_main_store.dart';
import '../../test_utils/test_service_factory.dart';

void main() {
  late MainStore db;
  late VaultEventHistoryService service;
  late TestDataFactory dataFactory;

  setUp(() {
    db = createTestStore();
    final serviceFactory = TestServiceFactory(db);
    service = serviceFactory.createVaultEventHistoryService();
    dataFactory = TestDataFactory(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('VaultEventHistoryService', () {
    test('writeEvent inserts vault event history row (action with snapshot)', () async {
      final itemId = await dataFactory.insertApiKeyRaw();
      final snapshotId = await dataFactory.insertSnapshot(
        itemId: itemId,
        type: VaultItemType.apiKey,
      );

      final result = await service.writeEvent(
        itemId: itemId,
        type: VaultItemType.apiKey,
        action: VaultEventHistoryAction.created,
        name: 'GitHub API',
        snapshotHistoryId: snapshotId,
      );

      expect(result.isSuccess(), true);

      final count = await dataFactory.countTable(db.vaultEventsHistory);
      expect(count, 1);

      final events = await db.vaultEventsHistoryDao.getEventsByItemId(itemId);
      expect(events.length, 1);
      final event = events.first;

      expect(event.itemId, itemId);
      expect(event.type, VaultItemType.apiKey);
      expect(event.action, VaultEventHistoryAction.created);
      expect(event.name, 'GitHub API');
      expect(event.snapshotHistoryId, snapshotId);
      expect(event.eventCreatedAt != null, true);
    });

    test('writeEvent inserts vault event history row (action without snapshot)', () async {
      final itemId = await dataFactory.insertApiKeyRaw();

      final result = await service.writeEvent(
        itemId: itemId,
        type: VaultItemType.apiKey,
        action: VaultEventHistoryAction.used, // "used" does not require snapshot
        name: 'GitHub API',
      );

      expect(result.isSuccess(), true);

      final events = await db.vaultEventsHistoryDao.getEventsByItemId(itemId);
      expect(events.length, 1);
      expect(events.first.action, VaultEventHistoryAction.used);
      expect(events.first.snapshotHistoryId == null, true);
    });
  });
}
