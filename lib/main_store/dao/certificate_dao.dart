import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/certificate_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/certificate_items.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';
import 'package:uuid/uuid.dart';

part 'certificate_dao.g.dart';

@DriftAccessor(tables: [VaultItems, CertificateItems])
class CertificateDao extends DatabaseAccessor<MainStore>
    with _$CertificateDaoMixin
    implements BaseMainEntityDao {
  CertificateDao(super.db);

  Future<List<(VaultItemsData, CertificateItemsData)>>
  getAllCertificates() async {
    final query = select(vaultItems).join([
      innerJoin(
        certificateItems,
        certificateItems.itemId.equalsExp(vaultItems.id),
      ),
    ]);
    final rows = await query.get();
    return rows
        .map(
          (row) => (row.readTable(vaultItems), row.readTable(certificateItems)),
        )
        .toList();
  }

  Future<(VaultItemsData, CertificateItemsData)?> getById(String id) async {
    final query = select(vaultItems).join([
      innerJoin(
        certificateItems,
        certificateItems.itemId.equalsExp(vaultItems.id),
      ),
    ])..where(vaultItems.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(certificateItems));
  }

  Stream<List<(VaultItemsData, CertificateItemsData)>> watchAllCertificates() {
    final query = select(vaultItems).join([
      innerJoin(
        certificateItems,
        certificateItems.itemId.equalsExp(vaultItems.id),
      ),
    ])..orderBy([OrderingTerm.desc(vaultItems.modifiedAt)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) =>
                (row.readTable(vaultItems), row.readTable(certificateItems)),
          )
          .toList(),
    );
  }

  Future<String> createCertificate(CreateCertificateDto dto) {
    final id = const Uuid().v4();

    return db.transaction(() async {
      await into(vaultItems).insert(
        VaultItemsCompanion.insert(
          id: Value(id),
          type: VaultItemType.certificate,
          name: dto.name,
          description: Value(dto.description),
          noteId: Value(dto.noteId),
          categoryId: Value(dto.categoryId),
        ),
      );

      await into(certificateItems).insert(
        CertificateItemsCompanion.insert(
          itemId: id,
          certificatePem: dto.certificatePem,
          privateKey: Value(dto.privateKey),
          serialNumber: Value(dto.serialNumber),
          issuer: Value(dto.issuer),
          subject: Value(dto.subject),
          validFrom: Value(dto.validFrom),
          validTo: Value(dto.validTo),
          fingerprint: Value(dto.fingerprint),
          keyUsage: Value(dto.keyUsage),
          extensions: Value(dto.extensions),
          pfxBlob: Value(
            dto.pfxBlob == null ? null : Uint8List.fromList(dto.pfxBlob!),
          ),
          passwordForPfx: Value(dto.passwordForPfx),
          ocspUrl: Value(dto.ocspUrl),
          crlUrl: Value(dto.crlUrl),
          autoRenew: Value(dto.autoRenew ?? false),
          lastCheckedAt: Value(dto.lastCheckedAt),
        ),
      );

      await db.vaultItemDao.insertTags(id, dto.tagsIds);
      return id;
    });
  }

  Future<bool> updateCertificate(String id, UpdateCertificateDto dto) {
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

      final itemCompanion = CertificateItemsCompanion(
        certificatePem: dto.certificatePem != null
            ? Value(dto.certificatePem!)
            : const Value.absent(),
        privateKey: Value(dto.privateKey),
        serialNumber: Value(dto.serialNumber),
        issuer: Value(dto.issuer),
        subject: Value(dto.subject),
        validFrom: Value(dto.validFrom),
        validTo: Value(dto.validTo),
        fingerprint: Value(dto.fingerprint),
        keyUsage: Value(dto.keyUsage),
        extensions: Value(dto.extensions),
        pfxBlob: Value(
          dto.pfxBlob == null ? null : Uint8List.fromList(dto.pfxBlob!),
        ),
        passwordForPfx: Value(dto.passwordForPfx),
        ocspUrl: Value(dto.ocspUrl),
        crlUrl: Value(dto.crlUrl),
        autoRenew: dto.autoRenew != null
            ? Value(dto.autoRenew!)
            : const Value.absent(),
        lastCheckedAt: Value(dto.lastCheckedAt),
      );

      await (update(
        certificateItems,
      )..where((i) => i.itemId.equals(id))).write(itemCompanion);

      if (dto.tagsIds != null) {
        await db.vaultItemDao.syncTags(id, dto.tagsIds!);
      }

      return true;
    });
  }

  Future<String?> getPrivateKeyFieldById(String id) async {
    final query = selectOnly(certificateItems)
      ..addColumns([certificateItems.privateKey])
      ..where(certificateItems.itemId.equals(id));

    final result = await query.getSingleOrNull();
    return result?.read(certificateItems.privateKey);
  }

  Future<String?> getPasswordForPfxFieldById(String id) async {
    final query = selectOnly(certificateItems)
      ..addColumns([certificateItems.passwordForPfx])
      ..where(certificateItems.itemId.equals(id));

    final result = await query.getSingleOrNull();
    return result?.read(certificateItems.passwordForPfx);
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
