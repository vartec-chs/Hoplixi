import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:uuid/uuid.dart';

import '../main_store.dart';
import '../models/dto/document_dto.dart';
import '../models/mappers/document_mapper.dart';
import '../models/mappers/vault_item_mapper.dart';
import '../tables/vault_items/vault_items.dart';

class DocumentRepository {
  final MainStore db;

  DocumentRepository(this.db);

  Future<String> create(CreateDocumentDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = const Uuid().v4();

      await db.into(db.vaultItems).insert(
            VaultItemsCompanion.insert(
              id: Value(itemId),
              type: VaultItemType.document,
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

      await db.into(db.documentItems).insert(
            DocumentItemsCompanion.insert(
              itemId: itemId,
              documentType: Value(dto.document.documentType),
              documentTypeOther: Value(dto.document.documentTypeOther),
              documentNumber: Value(dto.document.documentNumber),
              issueDate: Value(dto.document.issueDate),
              expiryDate: Value(dto.document.expiryDate),
              issuingAuthority: Value(dto.document.issuingAuthority),
              issuingCountry: Value(dto.document.issuingCountry),
              currentVersionId: Value(dto.document.currentVersionId),
            ),
          );

      return itemId;
    });
  }

  Future<void> update(UpdateDocumentDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = dto.item.itemId;

      await (db.update(db.vaultItems)..where((tbl) => tbl.id.equals(itemId)))
          .write(
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

      await (db.update(db.documentItems)
            ..where((tbl) => tbl.itemId.equals(itemId)))
          .write(
        DocumentItemsCompanion(
          documentType: Value(dto.document.documentType),
          documentTypeOther: Value(dto.document.documentTypeOther),
          documentNumber: Value(dto.document.documentNumber),
          issueDate: Value(dto.document.issueDate),
          expiryDate: Value(dto.document.expiryDate),
          issuingAuthority: Value(dto.document.issuingAuthority),
          issuingCountry: Value(dto.document.issuingCountry),
          currentVersionId: Value(dto.document.currentVersionId),
        ),
      );
    });
  }

  Future<DocumentViewDto?> getViewById(String itemId) async {
    final query = db.select(db.vaultItems).join([
      innerJoin(
        db.documentItems,
        db.documentItems.itemId.equalsExp(db.vaultItems.id),
      ),
    ])
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.document));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final item = row.readTable(db.vaultItems);
    final document = row.readTable(db.documentItems);

    return DocumentViewDto(
      item: item.toVaultItemViewDto(),
      document: document.toDocumentDataDto(),
    );
  }

  Future<DocumentCardDto?> getCardById(String itemId) async {
    final query = _buildCardQuery()
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.document));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return _mapRowToCardDto(row);
  }

  Future<List<DocumentCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) async {
    final query = _buildCardQuery()
      ..where(db.vaultItems.type.equalsValue(VaultItemType.document))
      ..where(db.vaultItems.isDeleted.equals(false))
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map(_mapRowToCardDto).toList();
  }

  Future<void> deletePermanently(String itemId) {
    return (db.delete(db.vaultItems)..where((tbl) => tbl.id.equals(itemId)))
        .go();
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCardQuery() {
    return db.selectOnly(db.vaultItems).join([
      innerJoin(
        db.documentItems,
        db.documentItems.itemId.equalsExp(db.vaultItems.id),
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

        db.documentItems.documentType,
        db.documentItems.documentNumber,
        db.documentItems.expiryDate,
        db.documentItems.issuingAuthority,
        db.documentItems.issuingCountry,
        db.documentItems.currentVersionId,
      ]);
  }

  DocumentCardDto _mapRowToCardDto(TypedResult row) {
    return DocumentCardDto(
      item: VaultItemCardDto(
        itemId: row.read(db.vaultItems.id)!,
        type: row.read(db.vaultItems.type)!,
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
      document: DocumentCardDataDto(
        documentType: row.read(db.documentItems.documentType)!,
        documentNumber: row.read(db.documentItems.documentNumber),
        expiryDate: row.read(db.documentItems.expiryDate),
        issuingAuthority: row.read(db.documentItems.issuingAuthority),
        issuingCountry: row.read(db.documentItems.issuingCountry),
        hasVersions: row.read(db.documentItems.currentVersionId) != null,
      ),
    );
  }
}
