import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/main_db/core/config/store_settings_keys.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/services/history/store_history_policy_service.dart';

import '../../test_utils/test_main_store.dart';
import '../../test_utils/test_service_factory.dart';

void main() {
  late MainStore db;
  late StoreHistoryPolicyService service;

  setUp(() {
    db = createTestStore();
    final factory = TestServiceFactory(db);
    service = factory.createStoreHistoryPolicyService();
  });

  tearDown(() async {
    await db.close();
  });

  group('StoreHistoryPolicyService', () {
    test('isHistoryEnabled returns true when setting is missing', () async {
      final result = await service.isHistoryEnabled();
      expect(result, isTrue);
    });

    test('isHistoryEnabled returns false when setting is false', () async {
      await db.storeSettingsDao.setBool(StoreSettingsKey.historyEnabled, false);
      final result = await service.isHistoryEnabled();
      expect(result, isFalse);
    });

    test('isHistoryEnabled returns true when setting is true', () async {
      await db.storeSettingsDao.setBool(StoreSettingsKey.historyEnabled, true);
      final result = await service.isHistoryEnabled();
      expect(result, isTrue);
    });
  });
}
