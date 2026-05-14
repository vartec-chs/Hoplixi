import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:uuid/uuid.dart';

import '../main_store.dart';
import '../models/dto/file_dto.dart';
import '../models/mappers/file_mapper.dart';
import '../models/mappers/vault_item_mapper.dart';
import '../tables/vault_items/vault_items.dart';

class FileRepository {
  final MainStore db;

  FileRepository(this.db);

  Future<String> create(CreateFileDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = const Uuid().v4();

      await db.into(db.vaultItems).insert(
            VaultItemsCompanion.insert(
              id: Value(itemId),
              type: VaultItemType.file,
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

      await db.into(db.fileItems).insert(
            FileItemsCompanion.insert(
              itemId: itemId,
              fileName: dto.file.fileName,
              fileSize: dto.file.fileSize,
              mimeType: dto.file.mimeType,
              extension: Value(dto.file.extension),
              blobId: dto.file.blobId,
              metadataId: Value(dto.file.metadataId),
              thumbnailBlobId: Value(dto.file.thumbnailBlobId),
            ),
          );

      return itemId;
    });
  }

  Future<void> update(UpdateFileDto dto) {
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

      await (db.update(db.fileItems)..where((tbl) => tbl.itemId.equals(itemId)))
          .write(
        FileItemsCompanion(
          fileName: Value(dto.file.fileName),
          fileSize: Value(dto.file.fileSize),
          mimeType: Value(dto.file.mimeType),
          extension: Value(dto.file.extension),
          blobId: Value(dto.file.blobId),
          metadataId: Value(dto.file.metadataId),
          thumbnailBlobId: Value(dto.file.thumbnailBlobId),
        ),
      );
    });
  }

  Future<FileViewDto?> getViewById(String itemId) async {
    final query = db.select(db.vaultItems).join([
      innerJoin(
        db.fileItems,
        db.fileItems.itemId.equalsExp(db.vaultItems.id),
      ),
    ])
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.file));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final item = row.readTable(db.vaultItems);
    final file = row.readTable(db.fileItems);

    return FileViewDto(
      item: item.toVaultItemViewDto(),
      file: file.toFileDataDto(),
    );
  }

  Future<FileCardDto?> getCardById(String itemId) async {
    final query = _buildCardQuery()
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.file));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return _mapRowToCardDto(row);
  }

  Future<List<FileCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) async {
    final query = _buildCardQuery()
      ..where(db.vaultItems.type.equalsValue(VaultItemType.file))
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
        db.fileItems,
        db.fileItems.itemId.equalsExp(db.vaultItems.id),
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

        db.fileItems.fileName,
        db.fileItems.fileSize,
        db.fileItems.mimeType,
        db.fileItems.extension,
        db.fileItems.thumbnailBlobId,
        // blobId is omitted for security/performance in card
      ]);
  }

  FileCardDto _mapRowToCardDto(TypedResult row) {
    return FileCardDto(
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
      file: FileCardDataDto(
        fileName: row.read(db.fileItems.fileName)!,
        fileSize: row.read(db.fileItems.fileSize)!,
        mimeType: row.read(db.fileItems.mimeType)!,
        extension: row.read(db.fileItems.extension),
        hasThumbnail: row.read(db.fileItems.thumbnailBlobId) != null,
      ),
    );
  }
}
