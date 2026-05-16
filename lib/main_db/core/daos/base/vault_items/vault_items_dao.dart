import 'package:drift/drift.dart';

import '../../../main_store.dart';
import '../../../tables/vault_items/vault_items.dart';

part 'vault_items_dao.g.dart';

@DriftAccessor(tables: [VaultItems])
class VaultItemsDao extends DatabaseAccessor<MainStore>
    with _$VaultItemsDaoMixin {
  VaultItemsDao(super.db);

  Future<void> insertVaultItem(VaultItemsCompanion companion) {
    return into(vaultItems).insert(companion);
  }

  Future<void> upsertVaultItem(VaultItemsCompanion companion) {
    return into(vaultItems).insertOnConflictUpdate(companion);
  }


  Future<int> updateVaultItemById(
    String itemId,
    VaultItemsCompanion companion,
  ) {
    return (update(
      vaultItems,
    )..where((tbl) => tbl.id.equals(itemId))).write(companion);
  }

  Future<VaultItemsData?> getVaultItemById(String itemId) {
    return (select(
      vaultItems,
    )..where((tbl) => tbl.id.equals(itemId))).getSingleOrNull();
  }

  Future<bool> existsVaultItem(String itemId) async {
    final row =
        await (selectOnly(vaultItems)
              ..addColumns([vaultItems.id])
              ..where(vaultItems.id.equals(itemId)))
            .getSingleOrNull();

    return row != null;
  }

  Future<bool> existsVaultItemWithType(
    String itemId,
    VaultItemType type,
  ) async {
    final row =
        await (selectOnly(vaultItems)
              ..addColumns([vaultItems.id])
              ..where(
                vaultItems.id.equals(itemId) &
                    vaultItems.type.equalsValue(type),
              ))
            .getSingleOrNull();

    return row != null;
  }

  Future<int> touchModifiedAt(String itemId, DateTime modifiedAt) {
    return (update(vaultItems)..where((tbl) => tbl.id.equals(itemId))).write(
      VaultItemsCompanion(modifiedAt: Value(modifiedAt)),
    );
  }

  Future<int> incrementUsedCount(String itemId, DateTime lastUsedAt) {
    return customUpdate(
      '''
    UPDATE vault_items
    SET
      used_count = used_count + 1,
      last_used_at = ?,
      modified_at = ?
    WHERE id = ?
    ''',
      variables: [
        Variable<DateTime>(lastUsedAt),
        Variable<DateTime>(lastUsedAt),
        Variable<String>(itemId),
      ],
      updates: {vaultItems},
    );
  }

  Future<int> archiveItem(String itemId, DateTime archivedAt) {
    return (update(vaultItems)..where((tbl) => tbl.id.equals(itemId))).write(
      VaultItemsCompanion(
        isArchived: const Value(true),
        archivedAt: Value(archivedAt),
        isPinned: const Value(false),
        isFavorite: const Value(false),
      ),
    );
  }

  Future<int> restoreArchivedItem(String itemId, DateTime modifiedAt) {
    return (update(vaultItems)..where((tbl) => tbl.id.equals(itemId))).write(
      VaultItemsCompanion(
        isArchived: const Value(false),
        archivedAt: const Value(null),
        modifiedAt: Value(modifiedAt),
      ),
    );
  }

  Future<int> softDeleteItem(String itemId, DateTime deletedAt) {
    return (update(vaultItems)..where((tbl) => tbl.id.equals(itemId))).write(
      VaultItemsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(deletedAt),
        isPinned: const Value(false),
        isFavorite: const Value(false),
      ),
    );
  }

  Future<int> recoverDeletedItem(String itemId, DateTime modifiedAt) {
    return (update(vaultItems)..where((tbl) => tbl.id.equals(itemId))).write(
      VaultItemsCompanion(
        isDeleted: const Value(false),
        deletedAt: const Value(null),
        modifiedAt: Value(modifiedAt),
      ),
    );
  }

  Future<int> setFavorite(String itemId, bool isFavorite, DateTime modifiedAt) {
    return (update(vaultItems)..where((tbl) => tbl.id.equals(itemId))).write(
      VaultItemsCompanion(
        isFavorite: Value(isFavorite),
        modifiedAt: Value(modifiedAt),
      ),
    );
  }

  Future<int> setPinned(String itemId, bool isPinned, DateTime modifiedAt) {
    return (update(vaultItems)..where((tbl) => tbl.id.equals(itemId))).write(
      VaultItemsCompanion(
        isPinned: Value(isPinned),
        modifiedAt: Value(modifiedAt),
      ),
    );
  }
}
