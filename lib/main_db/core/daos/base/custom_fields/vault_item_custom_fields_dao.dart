import 'package:drift/drift.dart';
import '../../../main_store.dart';
import '../../../tables/vault_items/vault_item_custom_fields.dart';

part 'vault_item_custom_fields_dao.g.dart';

@DriftAccessor(tables: [VaultItemCustomFields])
class VaultItemCustomFieldsDao extends DatabaseAccessor<MainStore>
    with _$VaultItemCustomFieldsDaoMixin {
  VaultItemCustomFieldsDao(super.db);

  Future<void> insertCustomField(VaultItemCustomFieldsCompanion companion) {
    return into(vaultItemCustomFields).insert(companion);
  }

  Future<int> updateCustomFieldById(
    String id,
    VaultItemCustomFieldsCompanion companion,
  ) {
    return (update(vaultItemCustomFields)..where((tbl) => tbl.id.equals(id)))
        .write(companion);
  }

  Future<VaultItemCustomFieldsData?> getCustomFieldById(String id) {
    return (select(vaultItemCustomFields)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<VaultItemCustomFieldsData>> getCustomFieldsByItemId(
    String itemId,
  ) {
    return (select(vaultItemCustomFields)
          ..where((tbl) => tbl.itemId.equals(itemId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<List<VaultItemCustomFieldsData>> getCustomFieldsByItemIds(
    List<String> itemIds,
  ) {
    if (itemIds.isEmpty) return Future.value(const []);
    return (select(vaultItemCustomFields)
          ..where((tbl) => tbl.itemId.isIn(itemIds))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<int> deleteCustomFieldById(String id) {
    return (delete(vaultItemCustomFields)..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  Future<int> deleteCustomFieldsByItemId(String itemId) {
    return (delete(vaultItemCustomFields)
          ..where((tbl) => tbl.itemId.equals(itemId)))
        .go();
  }

  Future<void> replaceCustomFieldsForItem({
    required String itemId,
    required List<VaultItemCustomFieldsCompanion> fields,
  }) async {
    await transaction(() async {
      await deleteCustomFieldsByItemId(itemId);
      await batch((batch) {
        batch.insertAll(vaultItemCustomFields, fields);
      });
    });
  }
}
