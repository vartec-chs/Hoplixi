import 'package:drift/drift.dart';
import '../../../main_store.dart';
import '../../../tables/vault_items/vault_item_custom_fields.dart';
import '../../../tables/vault_items/vault_item_custom_fields_history.dart';
import '../../../models/dto_history/cards/custom_field_history_card_dto.dart';

part 'vault_item_custom_fields_history_dao.g.dart';

@DriftAccessor(tables: [VaultItemCustomFieldsHistory])
class VaultItemCustomFieldsHistoryDao extends DatabaseAccessor<MainStore>
    with _$VaultItemCustomFieldsHistoryDaoMixin {
  VaultItemCustomFieldsHistoryDao(super.db);

  Future<void> insertCustomFieldHistory(
    VaultItemCustomFieldsHistoryCompanion companion,
  ) {
    return into(vaultItemCustomFieldsHistory).insert(companion);
  }

  Future<void> insertCustomFieldsHistoryBatch(
    List<VaultItemCustomFieldsHistoryCompanion> companions,
  ) async {
    await batch((batch) {
      batch.insertAll(vaultItemCustomFieldsHistory, companions);
    });
  }

  Future<List<VaultItemCustomFieldsHistoryData>>
      getCustomFieldsHistoryBySnapshotHistoryId(String snapshotHistoryId) {
    return (select(vaultItemCustomFieldsHistory)
          ..where((tbl) => tbl.snapshotHistoryId.equals(snapshotHistoryId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<List<VaultItemCustomFieldsHistoryData>>
      getCustomFieldsHistoryBySnapshotHistoryIds(
          List<String> snapshotHistoryIds) {
    if (snapshotHistoryIds.isEmpty) return Future.value(const []);
    return (select(vaultItemCustomFieldsHistory)
          ..where((tbl) => tbl.snapshotHistoryId.isIn(snapshotHistoryIds))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<int> deleteCustomFieldsHistoryBySnapshotHistoryId(
    String snapshotHistoryId,
  ) {
    return (delete(vaultItemCustomFieldsHistory)
          ..where((tbl) => tbl.snapshotHistoryId.equals(snapshotHistoryId)))
        .go();
  }

  Future<Map<String, List<VaultItemCustomFieldHistoryCardDataDto>>>
      getCustomFieldHistoryCardsBySnapshotHistoryIds(
    List<String> snapshotHistoryIds,
  ) async {
    if (snapshotHistoryIds.isEmpty) return const {};

    final hasValueExpr = vaultItemCustomFieldsHistory.value.isNotNull();

    final query = selectOnly(vaultItemCustomFieldsHistory)
      ..addColumns([
        vaultItemCustomFieldsHistory.id,
        vaultItemCustomFieldsHistory.snapshotHistoryId,
        vaultItemCustomFieldsHistory.originalFieldId,
        vaultItemCustomFieldsHistory.label,
        vaultItemCustomFieldsHistory.fieldType,
        vaultItemCustomFieldsHistory.isSecret,
        vaultItemCustomFieldsHistory.sortOrder,
        hasValueExpr,
        vaultItemCustomFieldsHistory.createdAt,
        vaultItemCustomFieldsHistory.modifiedAt,
        vaultItemCustomFieldsHistory.historyCreatedAt,
      ])
      ..where(vaultItemCustomFieldsHistory.snapshotHistoryId.isIn(snapshotHistoryIds))
      ..orderBy([OrderingTerm.asc(vaultItemCustomFieldsHistory.sortOrder)]);

    final rows = await query.get();

    final map = <String, List<VaultItemCustomFieldHistoryCardDataDto>>{};

    for (final row in rows) {
      final snapshotHistoryId = row.read(vaultItemCustomFieldsHistory.snapshotHistoryId)!;
      final dto = VaultItemCustomFieldHistoryCardDataDto(
        id: row.read(vaultItemCustomFieldsHistory.id)!,
        snapshotHistoryId: snapshotHistoryId,
        originalFieldId: row.read(vaultItemCustomFieldsHistory.originalFieldId),
        label: row.read(vaultItemCustomFieldsHistory.label)!,
        fieldType: row.readWithConverter<CustomFieldType, String>(vaultItemCustomFieldsHistory.fieldType)!,
        isSecret: row.read(vaultItemCustomFieldsHistory.isSecret)!,
        sortOrder: row.read(vaultItemCustomFieldsHistory.sortOrder)!,
        hasValue: row.read(hasValueExpr) ?? false,
        createdAt: row.read(vaultItemCustomFieldsHistory.createdAt)!,
        modifiedAt: row.read(vaultItemCustomFieldsHistory.modifiedAt)!,
        historyCreatedAt: row.read(vaultItemCustomFieldsHistory.historyCreatedAt)!,
      );
      map.putIfAbsent(snapshotHistoryId, () => []).add(dto);
    }

    return map;
  }

  Future<String?> getCustomFieldHistoryValueById(String id) async {
    final row = await (selectOnly(vaultItemCustomFieldsHistory)
          ..addColumns([vaultItemCustomFieldsHistory.value])
          ..where(vaultItemCustomFieldsHistory.id.equals(id)))
        .getSingleOrNull();

    return row?.read(vaultItemCustomFieldsHistory.value);
  }
}
