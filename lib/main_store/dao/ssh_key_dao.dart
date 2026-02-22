import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/ssh_key_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/ssh_key_items.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';
import 'package:uuid/uuid.dart';

part 'ssh_key_dao.g.dart';

@DriftAccessor(tables: [VaultItems, SshKeyItems])
class SshKeyDao extends DatabaseAccessor<MainStore>
    with _$SshKeyDaoMixin
    implements BaseMainEntityDao {
  SshKeyDao(super.db);

  Future<List<(VaultItemsData, SshKeyItemsData)>> getAllSshKeys() async {
    final query = select(vaultItems).join([
      innerJoin(sshKeyItems, sshKeyItems.itemId.equalsExp(vaultItems.id)),
    ]);
    final rows = await query.get();
    return rows
        .map((row) => (row.readTable(vaultItems), row.readTable(sshKeyItems)))
        .toList();
  }

  Future<(VaultItemsData, SshKeyItemsData)?> getById(String id) async {
    final query = select(vaultItems).join([
      innerJoin(sshKeyItems, sshKeyItems.itemId.equalsExp(vaultItems.id)),
    ])..where(vaultItems.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(sshKeyItems));
  }

  Stream<List<(VaultItemsData, SshKeyItemsData)>> watchAllSshKeys() {
    final query = select(vaultItems).join([
      innerJoin(sshKeyItems, sshKeyItems.itemId.equalsExp(vaultItems.id)),
    ])..orderBy([OrderingTerm.desc(vaultItems.modifiedAt)]);

    return query.watch().map(
      (rows) => rows
          .map((row) => (row.readTable(vaultItems), row.readTable(sshKeyItems)))
          .toList(),
    );
  }

  Future<String> createSshKey(CreateSshKeyDto dto) {
    final id = const Uuid().v4();

    return db.transaction(() async {
      await into(vaultItems).insert(
        VaultItemsCompanion.insert(
          id: Value(id),
          type: VaultItemType.sshKey,
          name: dto.name,
          description: Value(dto.description),
          noteId: Value(dto.noteId),
          categoryId: Value(dto.categoryId),
        ),
      );

      await into(sshKeyItems).insert(
        SshKeyItemsCompanion.insert(
          itemId: id,
          publicKey: dto.publicKey,
          privateKey: dto.privateKey,
          keyType: Value(dto.keyType),
          keySize: Value(dto.keySize),
          passphraseHint: Value(dto.passphraseHint),
          comment: Value(dto.comment),
          fingerprint: Value(dto.fingerprint),
          createdBy: Value(dto.createdBy),
          addedToAgent: Value(dto.addedToAgent ?? false),
          usage: Value(dto.usage),
          publicKeyFileId: Value(dto.publicKeyFileId),
          privateKeyFileId: Value(dto.privateKeyFileId),
          metadata: Value(dto.metadata),
        ),
      );

      await db.vaultItemDao.insertTags(id, dto.tagsIds);
      return id;
    });
  }

  Future<bool> updateSshKey(String id, UpdateSshKeyDto dto) {
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

      final itemCompanion = SshKeyItemsCompanion(
        publicKey: dto.publicKey != null
            ? Value(dto.publicKey!)
            : const Value.absent(),
        privateKey: dto.privateKey != null
            ? Value(dto.privateKey!)
            : const Value.absent(),
        keyType: Value(dto.keyType),
        keySize: Value(dto.keySize),
        passphraseHint: Value(dto.passphraseHint),
        comment: Value(dto.comment),
        fingerprint: Value(dto.fingerprint),
        createdBy: Value(dto.createdBy),
        addedToAgent: dto.addedToAgent != null
            ? Value(dto.addedToAgent!)
            : const Value.absent(),
        usage: Value(dto.usage),
        publicKeyFileId: Value(dto.publicKeyFileId),
        privateKeyFileId: Value(dto.privateKeyFileId),
        metadata: Value(dto.metadata),
      );

      await (update(
        sshKeyItems,
      )..where((i) => i.itemId.equals(id))).write(itemCompanion);

      if (dto.tagsIds != null) {
        await db.vaultItemDao.syncTags(id, dto.tagsIds!);
      }

      return true;
    });
  }

  Future<String?> getPrivateKeyFieldById(String id) async {
    final query = selectOnly(sshKeyItems)
      ..addColumns([sshKeyItems.privateKey])
      ..where(sshKeyItems.itemId.equals(id));

    final result = await query.getSingleOrNull();
    return result?.read(sshKeyItems.privateKey);
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
