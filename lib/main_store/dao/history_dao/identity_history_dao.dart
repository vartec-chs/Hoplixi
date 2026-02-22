import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/identity_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/identity_history.dart';
import 'package:hoplixi/main_store/tables/vault_item_history.dart';

part 'identity_history_dao.g.dart';

@DriftAccessor(tables: [VaultItemHistory, IdentityHistory])
class IdentityHistoryDao extends DatabaseAccessor<MainStore>
    with _$IdentityHistoryDaoMixin {
  IdentityHistoryDao(super.db);

  Future<List<IdentityHistoryCardDto>> getIdentityHistoryCardsByOriginalId(
    String identityId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    final query = select(vaultItemHistory).join([
      innerJoin(
        identityHistory,
        identityHistory.historyId.equalsExp(vaultItemHistory.id),
      ),
    ]);

    Expression<bool> where =
        vaultItemHistory.itemId.equals(identityId) &
        vaultItemHistory.type.equalsValue(VaultItemType.identity);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      where =
          where &
          (vaultItemHistory.name.like(q) |
              identityHistory.idType.like(q) |
              identityHistory.idNumber.like(q) |
              identityHistory.fullName.like(q) |
              identityHistory.nationality.like(q));
    }

    query
      ..where(where)
      ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map(_mapToCard).toList();
  }

  Future<int> countIdentityHistoryByOriginalId(
    String identityId,
    String? searchQuery,
  ) async {
    final countExpr = vaultItemHistory.id.count();

    final query = selectOnly(vaultItemHistory)
      ..join([
        innerJoin(
          identityHistory,
          identityHistory.historyId.equalsExp(vaultItemHistory.id),
        ),
      ])
      ..addColumns([countExpr])
      ..where(
        vaultItemHistory.itemId.equals(identityId) &
            vaultItemHistory.type.equalsValue(VaultItemType.identity),
      );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      query.where(
        vaultItemHistory.name.like(q) |
            identityHistory.idType.like(q) |
            identityHistory.idNumber.like(q) |
            identityHistory.fullName.like(q) |
            identityHistory.nationality.like(q),
      );
    }

    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  Future<int> deleteIdentityHistoryById(String historyId) {
    return (delete(
      vaultItemHistory,
    )..where((h) => h.id.equals(historyId))).go();
  }

  Future<int> deleteIdentityHistoryByIdentityId(String identityId) {
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.itemId.equals(identityId) &
              h.type.equalsValue(VaultItemType.identity),
        ))
        .go();
  }

  IdentityHistoryCardDto _mapToCard(TypedResult row) {
    final history = row.readTable(vaultItemHistory);
    final identity = row.readTable(identityHistory);

    return IdentityHistoryCardDto(
      id: history.id,
      originalIdentityId: history.itemId,
      action: history.action.value,
      name: history.name,
      idType: identity.idType,
      idNumber: identity.idNumber,
      fullName: identity.fullName,
      expiryDate: identity.expiryDate,
      verified: identity.verified,
      actionAt: history.actionAt,
    );
  }
}
