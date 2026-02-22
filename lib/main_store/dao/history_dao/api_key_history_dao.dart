import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/api_key_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/api_key_history.dart';
import 'package:hoplixi/main_store/tables/vault_item_history.dart';

part 'api_key_history_dao.g.dart';

@DriftAccessor(tables: [VaultItemHistory, ApiKeyHistory])
class ApiKeyHistoryDao extends DatabaseAccessor<MainStore>
    with _$ApiKeyHistoryDaoMixin {
  ApiKeyHistoryDao(super.db);

  Future<List<ApiKeyHistoryCardDto>> getApiKeyHistoryCardsByOriginalId(
    String apiKeyId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    final query = select(vaultItemHistory).join([
      innerJoin(
        apiKeyHistory,
        apiKeyHistory.historyId.equalsExp(vaultItemHistory.id),
      ),
    ]);

    Expression<bool> where =
        vaultItemHistory.itemId.equals(apiKeyId) &
        vaultItemHistory.type.equalsValue(VaultItemType.apiKey);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      where =
          where &
          (vaultItemHistory.name.like(q) |
              apiKeyHistory.service.like(q) |
              apiKeyHistory.tokenType.like(q) |
              apiKeyHistory.environment.like(q));
    }

    query
      ..where(where)
      ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map(_mapToCard).toList();
  }

  Future<int> countApiKeyHistoryByOriginalId(
    String apiKeyId,
    String? searchQuery,
  ) async {
    final countExpr = vaultItemHistory.id.count();

    final query = selectOnly(vaultItemHistory)
      ..join([
        innerJoin(
          apiKeyHistory,
          apiKeyHistory.historyId.equalsExp(vaultItemHistory.id),
        ),
      ])
      ..addColumns([countExpr])
      ..where(
        vaultItemHistory.itemId.equals(apiKeyId) &
            vaultItemHistory.type.equalsValue(VaultItemType.apiKey),
      );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      query.where(
        vaultItemHistory.name.like(q) |
            apiKeyHistory.service.like(q) |
            apiKeyHistory.tokenType.like(q) |
            apiKeyHistory.environment.like(q),
      );
    }

    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  Future<int> deleteApiKeyHistoryById(String historyId) {
    return (delete(
      vaultItemHistory,
    )..where((h) => h.id.equals(historyId))).go();
  }

  Future<int> deleteApiKeyHistoryByApiKeyId(String apiKeyId) {
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.itemId.equals(apiKeyId) &
              h.type.equalsValue(VaultItemType.apiKey),
        ))
        .go();
  }

  ApiKeyHistoryCardDto _mapToCard(TypedResult row) {
    final h = row.readTable(vaultItemHistory);
    final api = row.readTable(apiKeyHistory);

    return ApiKeyHistoryCardDto(
      id: h.id,
      originalApiKeyId: h.itemId,
      action: h.action.value,
      name: h.name,
      service: api.service,
      tokenType: api.tokenType,
      environment: api.environment,
      revoked: api.revoked,
      actionAt: h.actionAt,
    );
  }
}
