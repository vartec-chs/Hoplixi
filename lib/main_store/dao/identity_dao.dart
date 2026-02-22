import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/identity_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/identity_items.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';
import 'package:uuid/uuid.dart';

part 'identity_dao.g.dart';

@DriftAccessor(tables: [VaultItems, IdentityItems])
class IdentityDao extends DatabaseAccessor<MainStore>
    with _$IdentityDaoMixin
    implements BaseMainEntityDao {
  IdentityDao(super.db);

  Future<List<(VaultItemsData, IdentityItemsData)>> getAllIdentities() async {
    final query = select(vaultItems).join([
      innerJoin(identityItems, identityItems.itemId.equalsExp(vaultItems.id)),
    ]);
    final rows = await query.get();
    return rows
        .map((row) => (row.readTable(vaultItems), row.readTable(identityItems)))
        .toList();
  }

  Future<(VaultItemsData, IdentityItemsData)?> getById(String id) async {
    final query = select(vaultItems).join([
      innerJoin(identityItems, identityItems.itemId.equalsExp(vaultItems.id)),
    ])..where(vaultItems.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(identityItems));
  }

  Stream<List<(VaultItemsData, IdentityItemsData)>> watchAllIdentities() {
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
          notes: Value(dto.notes),
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
        notes: Value(dto.notes),
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

  @override
  Future<bool> incrementUsage(String id) => db.vaultItemDao.incrementUsage(id);

  @override
  Future<bool> permanentDelete(String id) =>
      db.vaultItemDao.permanentDelete(id);

  @override
  Future<bool> restoreFromDeleted(String id) =>
      db.vaultItemDao.restoreFromDeleted(id);

  @override
  Future<bool> softDelete(String id) => db.vaultItemDao.softDelete(id);

  @override
  Future<bool> toggleArchive(String id, bool isArchived) =>
      db.vaultItemDao.toggleArchive(id, isArchived);

  @override
  Future<bool> toggleFavorite(String id, bool isFavorite) =>
      db.vaultItemDao.toggleFavorite(id, isFavorite);

  @override
  Future<bool> togglePin(String id, bool isPinned) =>
      db.vaultItemDao.togglePin(id, isPinned);
}
