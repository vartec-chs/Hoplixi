import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/file_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/file_items.dart';
import 'package:hoplixi/main_store/tables/file_metadata.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';
import 'package:uuid/uuid.dart';

part 'file_dao.g.dart';

@DriftAccessor(tables: [VaultItems, FileItems, FileMetadata])
class FileDao extends DatabaseAccessor<MainStore> with _$FileDaoMixin {
  FileDao(super.db);

  /// Получить все файлы (JOIN)
  Future<List<(VaultItemsData, FileItemsData)>> getAllFiles() async {
    final query = select(
      vaultItems,
    ).join([innerJoin(fileItems, fileItems.itemId.equalsExp(vaultItems.id))]);
    final rows = await query.get();
    return rows
        .map((row) => (row.readTable(vaultItems), row.readTable(fileItems)))
        .toList();
  }

  /// Получить файл по ID
  Future<(VaultItemsData, FileItemsData)?> getById(String id) async {
    final query = select(vaultItems).join([
      innerJoin(fileItems, fileItems.itemId.equalsExp(vaultItems.id)),
    ])..where(vaultItems.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(fileItems));
  }

  /// Получить метаданные файла
  Future<FileMetadataData?> getFileMetadataById(String metadataId) {
    return (select(
      fileMetadata,
    )..where((m) => m.id.equals(metadataId))).getSingleOrNull();
  }

  /// Смотреть все файлы
  Stream<List<(VaultItemsData, FileItemsData)>> watchAllFiles() {
    final query = select(vaultItems).join([
      innerJoin(fileItems, fileItems.itemId.equalsExp(vaultItems.id)),
    ])..orderBy([OrderingTerm.desc(vaultItems.modifiedAt)]);
    return query.watch().map(
      (rows) => rows
          .map((row) => (row.readTable(vaultItems), row.readTable(fileItems)))
          .toList(),
    );
  }

  /// Создать новый файл
  Future<String> createFile(CreateFileDto dto) {
    final uuid = const Uuid().v4();
    return db.transaction(() async {
      // Метаданные файла
      String? metadataId;
      if (dto.fileName != null) {
        metadataId = const Uuid().v4();
        await into(fileMetadata).insert(
          FileMetadataCompanion.insert(
            id: Value(metadataId),
            fileName: dto.fileName!,
            fileExtension: dto.fileExtension ?? '',
            filePath: Value(dto.filePath),
            mimeType: dto.mimeType ?? 'application/octet-stream',
            fileSize: dto.fileSize ?? 0,
            fileHash: Value(dto.fileHash),
          ),
        );
      }

      await into(vaultItems).insert(
        VaultItemsCompanion.insert(
          id: Value(uuid),
          type: VaultItemType.file,
          name: dto.name,
          description: Value(dto.description),
          noteId: Value(dto.noteId),
          categoryId: Value(dto.categoryId),
        ),
      );
      await into(fileItems).insert(
        FileItemsCompanion.insert(itemId: uuid, metadataId: Value(metadataId)),
      );
      await db.vaultItemDao.insertTags(uuid, dto.tagsIds);
      return uuid;
    });
  }

  /// Обновить файл
  Future<bool> updateFile(String id, UpdateFileDto dto) {
    return db.transaction(() async {
      final vaultCompanion = VaultItemsCompanion(
        name: dto.name != null ? Value(dto.name!) : const Value.absent(),
        description: dto.description != null
            ? Value(dto.description)
            : const Value.absent(),
        noteId: dto.noteId != null ? Value(dto.noteId) : const Value.absent(),
        categoryId: dto.categoryId != null
            ? Value(dto.categoryId)
            : const Value.absent(),
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

      if (dto.tagsIds != null) {
        await db.vaultItemDao.syncTags(id, dto.tagsIds!);
      }
      return true;
    });
  }
}
