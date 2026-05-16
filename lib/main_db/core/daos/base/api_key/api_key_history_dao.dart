import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/tables/tables.dart';

import '../../../main_store.dart';

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


  // --- HISTORY CARD BATCH METHODS ---
  Future<List<ApiKeyHistoryData>> getApiKeyHistoryByHistoryIds(List<String> historyIds) {
    if (historyIds.isEmpty) return Future.value(const []);
    return (select(apiKeyHistory)..where((tbl) => tbl.historyId.isIn(historyIds))).get();
  }

  Future<Map<String, ApiKeyHistoryCardDataDto>> getApiKeyHistoryCardDataByHistoryIds(List<String> historyIds) async {
    if (historyIds.isEmpty) return const {};

    final hasKeyExpr = apiKeyHistory.key.isNotNull();
    final query = selectOnly(apiKeyHistory)
      ..addColumns([
        apiKeyHistory.historyId,
        apiKeyHistory.service,
        apiKeyHistory.tokenType,
        apiKeyHistory.environment,
        apiKeyHistory.expiresAt,
        apiKeyHistory.revokedAt,
        apiKeyHistory.rotationPeriodDays,
        apiKeyHistory.lastRotatedAt,
        apiKeyHistory.owner,
        apiKeyHistory.baseUrl,
        hasKeyExpr,
      ])
      ..where(apiKeyHistory.historyId.isIn(historyIds));

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read(apiKeyHistory.historyId)!: ApiKeyHistoryCardDataDto(
          service: row.read(apiKeyHistory.service),
          tokenType: row.readWithConverter<ApiKeyTokenType?, String>(apiKeyHistory.tokenType),
          environment: row.readWithConverter<ApiKeyEnvironment?, String>(apiKeyHistory.environment),
          expiresAt: row.read(apiKeyHistory.expiresAt),
          revokedAt: row.read(apiKeyHistory.revokedAt),
          rotationPeriodDays: row.read(apiKeyHistory.rotationPeriodDays),
          lastRotatedAt: row.read(apiKeyHistory.lastRotatedAt),
          owner: row.read(apiKeyHistory.owner),
          baseUrl: row.read(apiKeyHistory.baseUrl),
          hasKey: row.read(hasKeyExpr) ?? false,
        ),
    };
  }

  Future<String?> getKeyByHistoryId(String historyId) async {
    final row = await (selectOnly(apiKeyHistory)
          ..addColumns([apiKeyHistory.key])
          ..where(apiKeyHistory.historyId.equals(historyId)))
        .getSingleOrNull();
    return row?.read(apiKeyHistory.key);
  }

}
