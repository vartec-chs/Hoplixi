import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/recovery_codes_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/recovery_codes_history.dart';
import 'package:hoplixi/main_store/tables/vault_item_history.dart';

part 'recovery_codes_history_dao.g.dart';

@DriftAccessor(tables: [VaultItemHistory, RecoveryCodesHistory])
class RecoveryCodesHistoryDao extends DatabaseAccessor<MainStore>
    with _$RecoveryCodesHistoryDaoMixin {
  RecoveryCodesHistoryDao(super.db);

  Future<List<RecoveryCodesHistoryCardDto>>
  getRecoveryCodesHistoryCardsByOriginalId(
    String recoveryCodesId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    final query = select(vaultItemHistory).join([
      innerJoin(
        recoveryCodesHistory,
        recoveryCodesHistory.historyId.equalsExp(vaultItemHistory.id),
      ),
    ]);

    Expression<bool> where =
        vaultItemHistory.itemId.equals(recoveryCodesId) &
        vaultItemHistory.type.equalsValue(VaultItemType.recoveryCodes);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      where =
          where &
          (vaultItemHistory.name.like(q) |
            recoveryCodesHistory.displayHint.like(q));
    }

    query
      ..where(where)
      ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map(_mapToCard).toList();
  }

  Future<int> countRecoveryCodesHistoryByOriginalId(
    String recoveryCodesId,
    String? searchQuery,
  ) async {
    final countExpr = vaultItemHistory.id.count();

    final query = selectOnly(vaultItemHistory)
      ..join([
        innerJoin(
          recoveryCodesHistory,
          recoveryCodesHistory.historyId.equalsExp(vaultItemHistory.id),
        ),
      ])
      ..addColumns([countExpr])
      ..where(
        vaultItemHistory.itemId.equals(recoveryCodesId) &
            vaultItemHistory.type.equalsValue(VaultItemType.recoveryCodes),
      );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      query.where(
        vaultItemHistory.name.like(q) |
        recoveryCodesHistory.displayHint.like(q),
      );
    }

    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  Future<int> deleteRecoveryCodesHistoryById(String historyId) {
    return (delete(vaultItemHistory)..where((h) => h.id.equals(historyId))).go();
  }

  Future<int> deleteRecoveryCodesHistoryByRecoveryCodesId(
    String recoveryCodesId,
  ) {
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.itemId.equals(recoveryCodesId) &
              h.type.equalsValue(VaultItemType.recoveryCodes),
        ))
        .go();
  }

  RecoveryCodesHistoryCardDto _mapToCard(TypedResult row) {
    final history = row.readTable(vaultItemHistory);
    final data = row.readTable(recoveryCodesHistory);

    return RecoveryCodesHistoryCardDto(
      id: history.id,
      originalRecoveryCodesId: history.itemId,
      action: history.action.value,
      name: history.name,
      codesCount: data.codesCount,
      usedCount: data.usedCount,
      oneTime: data.oneTime,
      actionAt: history.actionAt,
    );
  }
}
