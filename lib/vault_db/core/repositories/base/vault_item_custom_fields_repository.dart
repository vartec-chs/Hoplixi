import 'package:hoplixi/vault_db/core/vault_db.dart';

class VaultItemCustomFieldsRepository {
  final VaultDB db;

  VaultItemCustomFieldsRepository(this.db);

  Future<void> create(VaultItemCustomFieldsCompanion companion) {
    return db.vaultItemCustomFieldsDao.insertCustomField(companion);
  }

  Future<void> update(String id, VaultItemCustomFieldsCompanion companion) {
    return db.vaultItemCustomFieldsDao.updateCustomFieldById(id, companion);
  }

  Future<VaultItemCustomFieldsData?> getById(String id) {
    return db.vaultItemCustomFieldsDao.getCustomFieldById(id);
  }

  Future<List<VaultItemCustomFieldsData>> getByItemId(String itemId) {
    return db.vaultItemCustomFieldsDao.getCustomFieldsByItemId(itemId);
  }

  Future<List<VaultItemCustomFieldsData>> getByItemIds(List<String> itemIds) {
    return db.vaultItemCustomFieldsDao.getCustomFieldsByItemIds(itemIds);
  }

  Future<void> delete(String id) {
    return db.vaultItemCustomFieldsDao.deleteCustomFieldById(id);
  }

  Future<void> deleteByItemId(String itemId) {
    return db.vaultItemCustomFieldsDao.deleteCustomFieldsByItemId(itemId);
  }

  Future<void> replaceFields({
    required String itemId,
    required List<VaultItemCustomFieldsCompanion> fields,
  }) {
    return db.vaultItemCustomFieldsDao.replaceCustomFieldsForItem(
      itemId: itemId,
      fields: fields,
    );
  }
}
