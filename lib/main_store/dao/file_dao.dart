import 'dart:math' show exp;

import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/file_dto.dart';
import 'package:hoplixi/main_store/tables/file_metadata.dart';
import 'package:hoplixi/main_store/tables/file_tags.dart';
import 'package:hoplixi/main_store/tables/files.dart';
import 'package:uuid/uuid.dart';

part 'file_dao.g.dart';

@DriftAccessor(tables: [Files, FilesTags, FileMetadata])
class FileDao extends DatabaseAccessor<MainStore>
    with _$FileDaoMixin
    implements BaseMainEntityDao {
  FileDao(super.db);

  /// Получить все файлы
  Future<List<FilesData>> getAllFiles() {
    return select(files).get();
  }

  /// Получить файл по ID
  Future<FilesData?> getFileById(String id) {
    return (select(files)..where((f) => f.id.equals(id))).getSingleOrNull();
  }

  /// Получить метаданные файла по ID метаданных
  Future<FileMetadataData?> getFileMetadataById(String metadataId) {
    return (select(
      db.fileMetadata,
    )..where((m) => m.id.equals(metadataId))).getSingleOrNull();
  }

  /// Получить теги файла по ID
  Future<List<String>> getFileTagIds(String fileId) async {
    final rows = await (select(
      db.filesTags,
    )..where((t) => t.fileId.equals(fileId))).get();
    return rows.map((row) => row.tagId).toList();
  }

  /// Переключить избранное
  @override
  Future<bool> toggleFavorite(String id, bool isFavorite) async {
    final result = await (update(files)..where((f) => f.id.equals(id))).write(
      FilesCompanion(isFavorite: Value(isFavorite)),
    );

    return result > 0;
  }

  /// Переключить закрепление
  @override
  Future<bool> togglePin(String id, bool isPinned) async {
    final result = await (update(files)..where((f) => f.id.equals(id))).write(
      FilesCompanion(isPinned: Value(isPinned)),
    );

    return result > 0;
  }

  /// Переключить архивирование
  @override
  Future<bool> toggleArchive(String id, bool isArchived) async {
    final result = await (update(files)..where((f) => f.id.equals(id))).write(
      FilesCompanion(isArchived: Value(isArchived)),
    );

    return result > 0;
  }

  /// Смотреть все файлы с автообновлением
  Stream<List<FilesData>> watchAllFiles() {
    return (select(
      files,
    )..orderBy([(f) => OrderingTerm.desc(f.modifiedAt)])).watch();
  }

  /// Создать новый файл
  Future<String> createFile(CreateFileDto dto) async {
    final uuid = const Uuid().v4();
    return await db.transaction(() async {
      // Создаем FileMetadata если нужно (и если переданы данные для него)
      String? metadataId;
      if (dto.fileName != null) {
        metadataId = const Uuid().v4();
        await into(db.fileMetadata).insert(
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

      // Создаем запись Files
      final companion = FilesCompanion.insert(
        id: Value(uuid),
        name: dto.name,
        description: Value(dto.description),
        metadataId: Value(metadataId),
        noteId: Value(dto.noteId),
        categoryId: Value(dto.categoryId),
      );
      await into(files).insert(companion);
      await _insertFileTags(uuid, dto.tagsIds);
      return uuid;
    });
  }

  Future<void> _insertFileTags(String fileId, List<String>? tagIds) async {
    if (tagIds == null || tagIds.isEmpty) return;
    for (final tagId in tagIds) {
      await db
          .into(db.filesTags)
          .insert(FilesTagsCompanion.insert(fileId: fileId, tagId: tagId));
    }
  }

  /// Синхронизировать теги файла
  Future<void> syncFileTags(String fileId, List<String> tagIds) async {
    await db.transaction(() async {
      final existing = await (select(
        db.filesTags,
      )..where((t) => t.fileId.equals(fileId))).get();
      final existingIds = existing.map((row) => row.tagId).toSet();
      final newIds = tagIds.toSet();

      final toDelete = existingIds.difference(newIds);
      if (toDelete.isNotEmpty) {
        await (delete(
          db.filesTags,
        )..where((t) => t.fileId.equals(fileId) & t.tagId.isIn(toDelete))).go();
      }

      final toInsert = newIds.difference(existingIds);
      for (final tagId in toInsert) {
        await db
            .into(db.filesTags)
            .insert(FilesTagsCompanion.insert(fileId: fileId, tagId: tagId));
      }
    });
  }

  /// Увеличить счетчик использования и обновить метрики
  @override
  Future<bool> incrementUsage(String id) async {
    final file = await getFileById(id);
    if (file == null) return false;

    final now = DateTime.now();
    final currentUsedCount = file.usedCount + 1;

    // Вычисляем новый recentScore по формуле EWMA: score = score * exp(-Δt / τ) + 1
    double newScore = 1.0;
    if (file.lastUsedAt != null && file.recentScore != null) {
      final deltaSeconds = now
          .difference(file.lastUsedAt!)
          .inSeconds
          .toDouble();
      final tau = const Duration(
        days: 7,
      ).inSeconds.toDouble(); // 7 дней в секундах
      final decayFactor = exp(-deltaSeconds / tau);
      newScore = file.recentScore! * decayFactor + 1.0;
    }

    final result = await (update(files)..where((f) => f.id.equals(id))).write(
      FilesCompanion(
        usedCount: Value(currentUsedCount),
        recentScore: Value(newScore),
        lastUsedAt: Value(now),
      ),
    );

    return result > 0;
  }

  /// Обновить файл
  Future<bool> updateFile(String id, UpdateFileDto dto) async {
    return await db.transaction(() async {
      final companion = FilesCompanion(
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

      final rowsAffected = await (update(
        files,
      )..where((f) => f.id.equals(id))).write(companion);

      if (dto.tagsIds != null) {
        await syncFileTags(id, dto.tagsIds!);
      }

      return rowsAffected > 0;
    });
  }

  /// Мягкое удаление файла
  @override
  Future<bool> softDelete(String id) async {
    final query = (update(files)..where((f) => f.id.equals(id)));
    return query
        .write(const FilesCompanion(isDeleted: Value(true)))
        .then((rowsAffected) => rowsAffected > 0);
  }

  /// Восстановить файл из удалённых
  @override
  Future<bool> restoreFromDeleted(String id) async {
    final rowsAffected = await (update(files)..where((f) => f.id.equals(id)))
        .write(const FilesCompanion(isDeleted: Value(false)));
    return rowsAffected > 0;
  }

  /// Полное удаление файл
  @override
  Future<bool> permanentDelete(String id) async {
    final rowsAffected = await (delete(
      files,
    )..where((f) => f.id.equals(id))).go();
    return rowsAffected > 0;
  }
}
