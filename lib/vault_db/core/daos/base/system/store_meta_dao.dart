import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/store_meta_dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

import '../../../tables/system/store/store_meta_table.dart';

part 'store_meta_dao.g.dart';

@DriftAccessor(tables: [StoreMetaTable])
class StoreMetaDao extends DatabaseAccessor<VaultDB> with _$StoreMetaDaoMixin {
  StoreMetaDao(super.db);

  Future<StoreInfoDto?> getStoreInfo() async {
    final row =
        await (select(storeMetaTable)..addColumns([
              storeMetaTable.singletonId,
              storeMetaTable.id,
              storeMetaTable.name,
              storeMetaTable.description,
              storeMetaTable.createdAt,
              storeMetaTable.modifiedAt,
              storeMetaTable.lastOpenedAt,
            ]))
            .getSingleOrNull();

    if (row == null) return null;

    return StoreInfoDto(
      id: row.id,
      name: row.name,
      description: row.description,
      createdAt: row.createdAt,
      modifiedAt: row.modifiedAt,
      lastOpenedAt: row.lastOpenedAt,
    );
  }

  Future<StoreMetaDto?> getStoreMeta() async {
    final row =
        await (select(storeMetaTable)..addColumns([
              storeMetaTable.singletonId,
              storeMetaTable.id,
              storeMetaTable.name,
              storeMetaTable.description,
              storeMetaTable.passwordHash,
              storeMetaTable.attachmentKey,
              storeMetaTable.createdAt,
              storeMetaTable.modifiedAt,
              storeMetaTable.lastOpenedAt,
            ]))
            .getSingleOrNull();

    if (row == null) return null;

    return StoreMetaDto(
      id: row.id,
      name: row.name,
      description: row.description,
      passwordHash: row.passwordHash,
      attachmentKey: row.attachmentKey,
      createdAt: row.createdAt,
      modifiedAt: row.modifiedAt,
      lastOpenedAt: row.lastOpenedAt,
    );
  }

  Future<void> insertStoreMeta(StoreMetaTableCompanion companion) {
    return into(storeMetaTable).insert(companion);
  }

  Future<int> updateStoreMeta(StoreMetaTableCompanion companion) {
    return update(storeMetaTable).write(companion);
  }

  Future<bool> hasStoreMeta() async {
    final result = await selectOnly(storeMetaTable).get();
    return result.isNotEmpty;
  }

  Future<String?> getAttachmentKey() async {
    final row = await (select(
      storeMetaTable,
    )..addColumns([storeMetaTable.attachmentKey])).getSingleOrNull();
    return row?.attachmentKey;
  }

  Future<String?> getPasswordHash() async {
    final row = await (select(
      storeMetaTable,
    )..addColumns([storeMetaTable.passwordHash])).getSingleOrNull();
    return row?.passwordHash;
  }
}
