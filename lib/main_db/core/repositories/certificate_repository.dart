import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/tables/certificate/certificate_items.dart';
import 'package:uuid/uuid.dart';

import '../main_store.dart';
import '../models/mappers/certificate_mapper.dart';
import '../models/mappers/vault_item_mapper.dart';
import '../tables/vault_items/vault_items.dart';

class CertificateRepository {
  final MainStore db;

  CertificateRepository(this.db);

  Future<String> create(CreateCertificateDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = const Uuid().v4();

      await db
          .into(db.vaultItems)
          .insert(
            VaultItemsCompanion.insert(
              id: Value(itemId),
              type: VaultItemType.certificate,
              name: dto.item.name,
              description: Value(dto.item.description),
              categoryId: Value(dto.item.categoryId),
              iconRefId: Value(dto.item.iconRefId),
              isFavorite: Value(dto.item.isFavorite),
              isPinned: Value(dto.item.isPinned),
              createdAt: Value(now),
              modifiedAt: Value(now),
            ),
          );

      await db
          .into(db.certificateItems)
          .insert(
            CertificateItemsCompanion.insert(
              itemId: itemId,
              certificateFormat: Value(dto.certificate.certificateFormat),
              certificateFormatOther: Value(
                dto.certificate.certificateFormatOther,
              ),
              certificatePem: Value(dto.certificate.certificatePem),
              certificateBlob: Value(dto.certificate.certificateBlob),
              privateKey: Value(dto.certificate.privateKey),
              privateKeyPassword: Value(dto.certificate.privateKeyPassword),
              passwordForPfx: Value(dto.certificate.passwordForPfx),
              keyAlgorithm: Value(dto.certificate.keyAlgorithm),
              keyAlgorithmOther: Value(dto.certificate.keyAlgorithmOther),
              keySize: Value(dto.certificate.keySize),
              serialNumber: Value(dto.certificate.serialNumber),
              issuer: Value(dto.certificate.issuer),
              subject: Value(dto.certificate.subject),
              validFrom: Value(dto.certificate.validFrom),
              validTo: Value(dto.certificate.validTo),
            ),
          );

      return itemId;
    });
  }

  Future<void> update(UpdateCertificateDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = dto.item.itemId;

      await (db.update(
        db.vaultItems,
      )..where((tbl) => tbl.id.equals(itemId))).write(
        VaultItemsCompanion(
          name: Value(dto.item.name),
          description: Value(dto.item.description),
          categoryId: Value(dto.item.categoryId),
          iconRefId: Value(dto.item.iconRefId),
          isFavorite: Value(dto.item.isFavorite),
          isPinned: Value(dto.item.isPinned),
          modifiedAt: Value(now),
        ),
      );

      await (db.update(
        db.certificateItems,
      )..where((tbl) => tbl.itemId.equals(itemId))).write(
        CertificateItemsCompanion(
          certificateFormat: Value(dto.certificate.certificateFormat),
          certificateFormatOther: Value(dto.certificate.certificateFormatOther),
          certificatePem: Value(dto.certificate.certificatePem),
          certificateBlob: Value(dto.certificate.certificateBlob),
          privateKey: Value(dto.certificate.privateKey),
          privateKeyPassword: Value(dto.certificate.privateKeyPassword),
          passwordForPfx: Value(dto.certificate.passwordForPfx),
          keyAlgorithm: Value(dto.certificate.keyAlgorithm),
          keyAlgorithmOther: Value(dto.certificate.keyAlgorithmOther),
          keySize: Value(dto.certificate.keySize),
          serialNumber: Value(dto.certificate.serialNumber),
          issuer: Value(dto.certificate.issuer),
          subject: Value(dto.certificate.subject),
          validFrom: Value(dto.certificate.validFrom),
          validTo: Value(dto.certificate.validTo),
        ),
      );
    });
  }

  Future<CertificateViewDto?> getViewById(String itemId) async {
    final query =
        db.select(db.vaultItems).join([
            innerJoin(
              db.certificateItems,
              db.certificateItems.itemId.equalsExp(db.vaultItems.id),
            ),
          ])
          ..where(db.vaultItems.id.equals(itemId))
          ..where(db.vaultItems.type.equalsValue(VaultItemType.certificate));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final item = row.readTable(db.vaultItems);
    final certificate = row.readTable(db.certificateItems);

    return CertificateViewDto(
      item: item.toVaultItemViewDto(),
      certificate: certificate.toCertificateDataDto(),
    );
  }

  Future<CertificateCardDto?> getCardById(String itemId) async {
    final expr = _CertificateCardExpressions(db);
    final query = _buildCardQuery(expr)
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.certificate));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return _mapRowToCardDto(row, expr);
  }

  Future<List<CertificateCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) async {
    final expr = _CertificateCardExpressions(db);
    final query = _buildCardQuery(expr)
      ..where(db.vaultItems.type.equalsValue(VaultItemType.certificate))
      ..where(db.vaultItems.isDeleted.equals(false))
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map((row) => _mapRowToCardDto(row, expr)).toList();
  }

  Future<void> deletePermanently(String itemId) {
    return (db.delete(
      db.vaultItems,
    )..where((tbl) => tbl.id.equals(itemId))).go();
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCardQuery(
    _CertificateCardExpressions expr,
  ) {
    return db.selectOnly(db.vaultItems).join([
      innerJoin(
        db.certificateItems,
        db.certificateItems.itemId.equalsExp(db.vaultItems.id),
      ),
    ])
      ..addColumns([
        db.vaultItems.id,
        db.vaultItems.type,
        db.vaultItems.name,
        db.vaultItems.description,
        db.vaultItems.categoryId,
        db.vaultItems.iconRefId,
        db.vaultItems.isFavorite,
        db.vaultItems.isArchived,
        db.vaultItems.isPinned,
        db.vaultItems.isDeleted,
        db.vaultItems.createdAt,
        db.vaultItems.modifiedAt,
        db.vaultItems.lastUsedAt,
        db.vaultItems.archivedAt,
        db.vaultItems.deletedAt,
        db.vaultItems.recentScore,

        db.certificateItems.certificateFormat,
        db.certificateItems.keyAlgorithm,
        db.certificateItems.keySize,
        db.certificateItems.serialNumber,
        db.certificateItems.issuer,
        db.certificateItems.subject,
        db.certificateItems.validFrom,
        db.certificateItems.validTo,
        expr.hasPrivateKey,
        expr.hasCertificateBlob,
        expr.hasPrivateKeyPassword,
        expr.hasPasswordForPfx,
        expr.hasCertificatePem,
      ]);
  }

  CertificateCardDto _mapRowToCardDto(
    TypedResult row,
    _CertificateCardExpressions expr,
  ) {
    return CertificateCardDto(
      item: VaultItemCardDto(
        itemId: row.read(db.vaultItems.id)!,
        type: row.readWithConverter<VaultItemType, String>(db.vaultItems.type)!,
        name: row.read(db.vaultItems.name)!,
        description: row.read(db.vaultItems.description),
        categoryId: row.read(db.vaultItems.categoryId),
        iconRefId: row.read(db.vaultItems.iconRefId),
        isFavorite: row.read(db.vaultItems.isFavorite)!,
        isArchived: row.read(db.vaultItems.isArchived)!,
        isPinned: row.read(db.vaultItems.isPinned)!,
        isDeleted: row.read(db.vaultItems.isDeleted)!,
        createdAt: row.read(db.vaultItems.createdAt)!,
        modifiedAt: row.read(db.vaultItems.modifiedAt)!,
        lastUsedAt: row.read(db.vaultItems.lastUsedAt),
        archivedAt: row.read(db.vaultItems.archivedAt),
        deletedAt: row.read(db.vaultItems.deletedAt),
        recentScore: row.read(db.vaultItems.recentScore),
      ),
      certificate: CertificateCardDataDto(
        certificateFormat: row.readWithConverter<CertificateFormat?, String>(
          db.certificateItems.certificateFormat,
        ),
        keyAlgorithm: row.readWithConverter<CertificateKeyAlgorithm?, String>(
          db.certificateItems.keyAlgorithm,
        ),
        keySize: row.read(db.certificateItems.keySize),
        serialNumber: row.read(db.certificateItems.serialNumber),
        issuer: row.read(db.certificateItems.issuer),
        subject: row.read(db.certificateItems.subject),
        validFrom: row.read(db.certificateItems.validFrom),
        validTo: row.read(db.certificateItems.validTo),
        hasPrivateKey: row.read(expr.hasPrivateKey) ?? false,
        hasCertificateBlob: row.read(expr.hasCertificateBlob) ?? false,
        hasPrivateKeyPassword: row.read(expr.hasPrivateKeyPassword) ?? false,
        hasPasswordForPfx: row.read(expr.hasPasswordForPfx) ?? false,
        hasCertificatePem: row.read(expr.hasCertificatePem) ?? false,
      ),
    );
  }
}

class _CertificateCardExpressions {
  _CertificateCardExpressions(this.db)
      : hasPrivateKey = db.certificateItems.privateKey.isNotNull(),
        hasCertificateBlob = db.certificateItems.certificateBlob.isNotNull(),
        hasPrivateKeyPassword =
            db.certificateItems.privateKeyPassword.isNotNull(),
        hasPasswordForPfx = db.certificateItems.passwordForPfx.isNotNull(),
        hasCertificatePem = db.certificateItems.certificatePem.isNotNull();

  final MainStore db;

  final Expression<bool> hasPrivateKey;
  final Expression<bool> hasCertificateBlob;
  final Expression<bool> hasPrivateKeyPassword;
  final Expression<bool> hasPasswordForPfx;
  final Expression<bool> hasCertificatePem;
}
