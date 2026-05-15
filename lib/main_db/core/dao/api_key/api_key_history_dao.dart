import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../tables/api_key/api_key_history.dart';

part 'api_key_history_dao.g.dart';

@DriftAccessor(tables: [ApiKeyHistory])
class ApiKeyHistoryDao extends DatabaseAccessor<MainStore>
    with _$ApiKeyHistoryDaoMixin {
  ApiKeyHistoryDao(super.db);

  Future<void> insertApiKeyHistory(ApiKeyHistoryCompanion companion) {
    return into(apiKeyHistory).insert(companion);
  }

  Future<ApiKeyHistoryData?> getApiKeyHistoryByHistoryId(String historyId) {
    return (select(apiKeyHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .getSingleOrNull();
  }

  Future<bool> existsApiKeyHistoryByHistoryId(String historyId) async {
    final row = await (selectOnly(apiKeyHistory)
          ..addColumns([apiKeyHistory.historyId])
          ..where(apiKeyHistory.historyId.equals(historyId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteApiKeyHistoryByHistoryId(String historyId) {
    return (delete(apiKeyHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .go();
  }
}
