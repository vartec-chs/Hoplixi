import 'package:drift/drift.dart';

import 'package:hoplixi/main_db/core/old/daos/crud/crud_types.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/old/models/dto/identity_dto.dart';
import 'package:hoplixi/main_db/core/old/models/enums/index.dart';
import 'package:hoplixi/main_db/core/tables/identity/identity_items.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';
import 'package:uuid/uuid.dart';

part 'identity_dao.g.dart';

@DriftAccessor(tables: [VaultItems, IdentityItems])
class IdentityDao extends DatabaseAccessor<MainStore> with _$IdentityDaoMixin {
  IdentityDao(super.db);

  Future<List<VaultItemWith<IdentityItemsData>>> getAllIdentities() async {
    final query = select(vaultItems).join([
      innerJoin(identityItems, identityItems.itemId.equalsExp(vaultItems.id)),
    ]);
    final rows = await query.get();
    return rows
        .map((row) => (row.readTable(vaultItems), row.readTable(identityItems)))
        .toList();
  }

  Future<VaultItemWith<IdentityItemsData>?> getById(String id) async {
    final query = select(vaultItems).join([
      innerJoin(identityItems, identityItems.itemId.equalsExp(vaultItems.id)),
    ])..where(vaultItems.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(identityItems));
  }

  Stream<List<VaultItemWith<IdentityItemsData>>> watchAllIdentities() {
    final query = select(vaultItems).join([
      innerJoin(identityItems, identityItems.itemId.equalsExp(vaultItems.id)),
    ])..orderBy([OrderingTerm.desc(vaultItems.modifiedAt)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => (row.readTable(vaultItems), row.readTable(identityItems)),
          )
          .toList(),
    );
  }

  Future<String> createIdentity(CreateIdentityDto dto) {
    final id = const Uuid().v4();

    return db.transaction(() async {
      await into(vaultItems).insert(
        VaultItemsCompanion.insert(
          id: Value(id),
          type: VaultItemType.identity,
          name: dto.name,
          description: Value(dto.description),
          noteId: Value(dto.noteId),
          categoryId: Value(dto.categoryId),
        ),
      );

      await into(identityItems).insert(
        IdentityItemsCompanion.insert(
          itemId: id,
          idType: dto.idType,
          idNumber: dto.idNumber,
          fullName: Value(dto.fullName),
          dateOfBirth: Value(dto.dateOfBirth),
          placeOfBirth: Value(dto.placeOfBirth),
          nationality: Value(dto.nationality),
          issuingAuthority: Value(dto.issuingAuthority),
          issueDate: Value(dto.issueDate),
          expiryDate: Value(dto.expiryDate),
          mrz: Value(dto.mrz),
          scanAttachmentId: Value(dto.scanAttachmentId),
          photoAttachmentId: Value(dto.photoAttachmentId),
          verified: Value(dto.verified ?? false),
        ),
      );

      await db.vaultItemDao.insertTags(id, dto.tagsIds);
      return id;
    });
  }

  Future<bool> updateIdentity(String id, UpdateIdentityDto dto) {
    return db.transaction(() async {
      final vaultCompanion = VaultItemsCompanion(
        name: dto.name != null ? Value(dto.name!) : const Value.absent(),
        description: Value(dto.description),
        noteId: Value(dto.noteId),
        categoryId: Value(dto.categoryId),
        isFavorite: dto.isFavorite != null
            ? Value(dto.isFavorite!)
            : const Value.absent(),
        isArchived: dto.isArchived != null
            ? Value(dto.isArchived!)
            : const Value.absent(),
        isPinned: dto.isPinned != null
            ? Value(dto.isPinned!)
            : const Value.absent(),
        modifiedAt: Value(DateTime.now()),
      );

      await (update(
        vaultItems,
      )..where((v) => v.id.equals(id))).write(vaultCompanion);

      final itemCompanion = IdentityItemsCompanion(
        idType: dto.idType != null ? Value(dto.idType!) : const Value.absent(),
        idNumber: dto.idNumber != null
            ? Value(dto.idNumber!)
            : const Value.absent(),
        fullName: Value(dto.fullName),
        dateOfBirth: Value(dto.dateOfBirth),
        placeOfBirth: Value(dto.placeOfBirth),
        nationality: Value(dto.nationality),
        issuingAuthority: Value(dto.issuingAuthority),
        issueDate: Value(dto.issueDate),
        expiryDate: Value(dto.expiryDate),
        mrz: Value(dto.mrz),
        scanAttachmentId: Value(dto.scanAttachmentId),
        photoAttachmentId: Value(dto.photoAttachmentId),
        verified: dto.verified != null
            ? Value(dto.verified!)
            : const Value.absent(),
      );

      await (update(
        identityItems,
      )..where((i) => i.itemId.equals(id))).write(itemCompanion);

      if (dto.tagsIds != null) {
        await db.vaultItemDao.syncTags(id, dto.tagsIds!);
      }

      return true;
    });
  }
}
