import 'package:hoplixi/vault_db/core/models/dto/vault_item_base_dto.dart';
import 'package:hoplixi/vault_db/core/models/mappers/vault_item_mapper.dart';
import 'package:hoplixi/vault_db/core/tables/tables.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

class VaultItemRepository {
  final VaultDB db;

  VaultItemRepository(this.db);

  Future<VaultItemViewDto?> getById(String itemId) async {
    final row = await db.vaultItemsDao.getVaultItemById(itemId);
    return row?.toVaultItemViewDto();
  }

  Future<bool> exists(String itemId) {
    return db.vaultItemsDao.existsVaultItem(itemId);
  }

  Future<bool> existsWithType(String itemId, VaultItemType type) {
    return db.vaultItemsDao.existsVaultItemWithType(itemId, type);
  }

  Future<void> update(String itemId, VaultItemsCompanion companion) {
    return db.vaultItemsDao.updateVaultItemById(itemId, companion);
  }

  Future<void> touch(String itemId) {
    return db.vaultItemsDao.touchModifiedAt(itemId, DateTime.now());
  }

  Future<void> incrementUsedCount(String itemId) {
    return db.vaultItemsDao.incrementUsedCount(itemId, DateTime.now());
  }

  Future<void> archive(String itemId) {
    return db.vaultItemsDao.archiveItem(itemId, DateTime.now());
  }

  Future<void> restoreArchived(String itemId) {
    return db.vaultItemsDao.restoreArchivedItem(itemId, DateTime.now());
  }

  Future<void> softDelete(String itemId) {
    return db.vaultItemsDao.softDeleteItem(itemId, DateTime.now());
  }

  Future<void> recover(String itemId) {
    return db.vaultItemsDao.recoverDeletedItem(itemId, DateTime.now());
  }

  Future<void> setFavorite(String itemId, bool isFavorite) {
    return db.vaultItemsDao.setFavorite(itemId, isFavorite, DateTime.now());
  }

  Future<void> setPinned(String itemId, bool isPinned) {
    return db.vaultItemsDao.setPinned(itemId, isPinned, DateTime.now());
  }
}
