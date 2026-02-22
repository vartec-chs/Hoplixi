import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/license_key_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/license_key_history.dart';
import 'package:hoplixi/main_store/tables/vault_item_history.dart';

part 'license_key_history_dao.g.dart';

@DriftAccessor(tables: [VaultItemHistory, LicenseKeyHistory])
class LicenseKeyHistoryDao extends DatabaseAccessor<MainStore>
    with _$LicenseKeyHistoryDaoMixin {
  LicenseKeyHistoryDao(super.db);

  Future<List<LicenseKeyHistoryCardDto>> getLicenseKeyHistoryCardsByOriginalId(
    String licenseKeyId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    final query = select(vaultItemHistory).join([
      innerJoin(
        licenseKeyHistory,
        licenseKeyHistory.historyId.equalsExp(vaultItemHistory.id),
      ),
    ]);

    Expression<bool> where =
        vaultItemHistory.itemId.equals(licenseKeyId) &
        vaultItemHistory.type.equalsValue(VaultItemType.licenseKey);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      where =
          where &
          (vaultItemHistory.name.like(q) |
              licenseKeyHistory.product.like(q) |
              licenseKeyHistory.licenseType.like(q) |
              licenseKeyHistory.orderId.like(q) |
              licenseKeyHistory.purchaseFrom.like(q));
    }

    query
      ..where(where)
      ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map(_mapToCard).toList();
  }

  Future<int> countLicenseKeyHistoryByOriginalId(
    String licenseKeyId,
    String? searchQuery,
  ) async {
    final countExpr = vaultItemHistory.id.count();

    final query = selectOnly(vaultItemHistory)
      ..join([
        innerJoin(
          licenseKeyHistory,
          licenseKeyHistory.historyId.equalsExp(vaultItemHistory.id),
        ),
      ])
      ..addColumns([countExpr])
      ..where(
        vaultItemHistory.itemId.equals(licenseKeyId) &
            vaultItemHistory.type.equalsValue(VaultItemType.licenseKey),
      );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      query.where(
        vaultItemHistory.name.like(q) |
            licenseKeyHistory.product.like(q) |
            licenseKeyHistory.licenseType.like(q) |
            licenseKeyHistory.orderId.like(q) |
            licenseKeyHistory.purchaseFrom.like(q),
      );
    }

    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  Future<int> deleteLicenseKeyHistoryById(String historyId) {
    return (delete(
      vaultItemHistory,
    )..where((h) => h.id.equals(historyId))).go();
  }

  Future<int> deleteLicenseKeyHistoryByLicenseKeyId(String licenseKeyId) {
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.itemId.equals(licenseKeyId) &
              h.type.equalsValue(VaultItemType.licenseKey),
        ))
        .go();
  }

  LicenseKeyHistoryCardDto _mapToCard(TypedResult row) {
    final history = row.readTable(vaultItemHistory);
    final license = row.readTable(licenseKeyHistory);

    return LicenseKeyHistoryCardDto(
      id: history.id,
      originalLicenseKeyId: history.itemId,
      action: history.action.value,
      name: history.name,
      product: license.product,
      licenseType: license.licenseType,
      orderId: license.orderId,
      expiresAt: license.expiresAt,
      actionAt: history.actionAt,
    );
  }
}
