import 'dart:math' show exp;

import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/document_dto.dart';
import 'package:hoplixi/main_store/tables/documents.dart';
import 'package:hoplixi/main_store/tables/documents_tags.dart';
import 'package:uuid/uuid.dart';

part 'document_dao.g.dart';

@DriftAccessor(tables: [Documents, DocumentsTags])
class DocumentDao extends DatabaseAccessor<MainStore>
    with _$DocumentDaoMixin
    implements BaseMainEntityDao {
  DocumentDao(super.db);

  /// Получить все документы
  Future<List<DocumentsData>> getAllDocuments() {
    return select(documents).get();
  }

  /// Получить документ по ID
  Future<DocumentsData?> getDocumentById(String id) {
    return (select(documents)..where((d) => d.id.equals(id))).getSingleOrNull();
  }

  /// Получить теги документа по ID
  Future<List<String>> getDocumentTagIds(String documentId) async {
    final query = select(db.documentsTags)
      ..where((t) => t.documentId.equals(documentId));
    final result = await query.get();
    return result.map((row) => row.tagId).toList();
  }

  /// Создать новый документ
  Future<String> createDocument(CreateDocumentDto dto) async {
    return await db.transaction(() async {
      final uuid = const Uuid().v4();
      final companion = DocumentsCompanion.insert(
        id: Value(uuid),
        title: Value(dto.title),
        documentType: Value(dto.documentType),
        description: Value(dto.description),
        aggregatedText: Value(dto.aggregatedText),
        aggregateHash: Value(dto.aggregateHash),
        pageCount: Value(dto.pageCount),
        categoryId: Value(dto.categoryId),
        noteId: Value(dto.noteId),
      );
      await into(documents).insert(companion);
      await _insertDocumentTags(uuid, dto.tagsIds);
      return uuid;
    });
  }

  Future<void> _insertDocumentTags(
    String documentId,
    List<String>? tagIds,
  ) async {
    if (tagIds == null || tagIds.isEmpty) return;
    for (final tagId in tagIds) {
      await db
          .into(db.documentsTags)
          .insert(
            DocumentsTagsCompanion.insert(documentId: documentId, tagId: tagId),
          );
    }
  }

  /// Синхронизировать теги документа
  Future<void> syncDocumentTags(String documentId, List<String> tagIds) async {
    await db.transaction(() async {
      final existing = await (select(
        db.documentsTags,
      )..where((t) => t.documentId.equals(documentId))).get();
      final existingIds = existing.map((row) => row.tagId).toSet();
      final newIds = tagIds.toSet();

      final toDelete = existingIds.difference(newIds);
      if (toDelete.isNotEmpty) {
        await (delete(db.documentsTags)..where(
              (t) => t.documentId.equals(documentId) & t.tagId.isIn(toDelete),
            ))
            .go();
      }

      final toInsert = newIds.difference(existingIds);
      for (final tagId in toInsert) {
        await db
            .into(db.documentsTags)
            .insert(
              DocumentsTagsCompanion.insert(
                documentId: documentId,
                tagId: tagId,
              ),
            );
      }
    });
  }

  /// Увеличить счетчик использования и обновить метрики
  @override
  Future<bool> incrementUsage(String id) async {
    final document = await getDocumentById(id);
    if (document == null) return false;

    final now = DateTime.now();
    final currentUsedCount = document.usedCount + 1;

    // Вычисляем новый recentScore по формуле EWMA: score = score * exp(-Δt / τ) + 1
    double newScore = 1.0;
    if (document.lastUsedAt != null && document.recentScore != null) {
      final deltaSeconds = now
          .difference(document.lastUsedAt!)
          .inSeconds
          .toDouble();
      final tau = const Duration(
        days: 7,
      ).inSeconds.toDouble(); // 7 дней в секундах
      final decayFactor = exp(-deltaSeconds / tau);
      newScore = document.recentScore! * decayFactor + 1.0;
    }

    final result = await (update(documents)..where((d) => d.id.equals(id)))
        .write(
          DocumentsCompanion(
            usedCount: Value(currentUsedCount),
            recentScore: Value(newScore),
            lastUsedAt: Value(now),
          ),
        );

    return result > 0;
  }

  /// Обновить документ
  Future<bool> updateDocument(String id, UpdateDocumentDto dto) async {
    return await db.transaction(() async {
      final companion = DocumentsCompanion(
        title: dto.title != null ? Value(dto.title) : const Value.absent(),
        documentType: dto.documentType != null
            ? Value(dto.documentType)
            : const Value.absent(),
        description: dto.description != null
            ? Value(dto.description)
            : const Value.absent(),
        aggregatedText: dto.aggregatedText != null
            ? Value(dto.aggregatedText)
            : const Value.absent(),
        aggregateHash: dto.aggregateHash != null
            ? Value(dto.aggregateHash)
            : const Value.absent(),
        pageCount: dto.pageCount != null
            ? Value(dto.pageCount!)
            : const Value.absent(),
        categoryId: dto.categoryId != null
            ? Value(dto.categoryId)
            : const Value.absent(),
        noteId: dto.noteId != null ? Value(dto.noteId) : const Value.absent(),
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
        documents,
      )..where((d) => d.id.equals(id))).write(companion);

      if (dto.tagsIds != null) {
        await syncDocumentTags(id, dto.tagsIds!);
      }

      return rowsAffected > 0;
    });
  }

  /// Переключить избранное
  @override
  Future<bool> toggleFavorite(String id, bool isFavorite) async {
    final result = await (update(documents)..where((d) => d.id.equals(id)))
        .write(DocumentsCompanion(isFavorite: Value(isFavorite)));
    return result > 0;
  }

  /// Переключить закрепление
  @override
  Future<bool> togglePin(String id, bool isPinned) async {
    final result = await (update(documents)..where((d) => d.id.equals(id)))
        .write(DocumentsCompanion(isPinned: Value(isPinned)));
    return result > 0;
  }

  /// Переключить архивирование
  @override
  Future<bool> toggleArchive(String id, bool isArchived) async {
    final result = await (update(documents)..where((d) => d.id.equals(id)))
        .write(DocumentsCompanion(isArchived: Value(isArchived)));
    return result > 0;
  }

  /// Мягкое удаление
  @override
  Future<bool> softDelete(String id) async {
    final result = await (update(documents)..where((d) => d.id.equals(id)))
        .write(const DocumentsCompanion(isDeleted: Value(true)));
    return result > 0;
  }

  /// Восстановить из удаленных
  @override
  Future<bool> restoreFromDeleted(String id) async {
    final result = await (update(documents)..where((d) => d.id.equals(id)))
        .write(const DocumentsCompanion(isDeleted: Value(false)));
    return result > 0;
  }

  /// Окончательное удаление
  @override
  Future<bool> permanentDelete(String id) async {
    final result = await (delete(
      documents,
    )..where((d) => d.id.equals(id))).go();
    return result > 0;
  }

  /// Получить документы по категории
  Future<List<DocumentsData>> getDocumentsByCategory(String categoryId) {
    return (select(
      documents,
    )..where((d) => d.categoryId.equals(categoryId))).get();
  }

  /// Получить избранные документы
  Future<List<DocumentsData>> getFavoriteDocuments() {
    return (select(documents)..where((d) => d.isFavorite.equals(true))).get();
  }

  /// Получить архивные документы
  Future<List<DocumentsData>> getArchivedDocuments() {
    return (select(documents)..where((d) => d.isArchived.equals(true))).get();
  }

  /// Получить удаленные документы
  Future<List<DocumentsData>> getDeletedDocuments() {
    return (select(documents)..where((d) => d.isDeleted.equals(true))).get();
  }

  /// Получить закрепленные документы
  Future<List<DocumentsData>> getPinnedDocuments() {
    return (select(documents)..where((d) => d.isPinned.equals(true))).get();
  }

  /// Подсчитать общее количество документов
  Future<int> countAllDocuments() async {
    final query = selectOnly(documents)..addColumns([documents.id.count()]);
    final result = await query.getSingle();
    return result.read(documents.id.count()) ?? 0;
  }

  /// Подсчитать документы по категории
  Future<int> countDocumentsByCategory(String categoryId) async {
    final query = selectOnly(documents)
      ..addColumns([documents.id.count()])
      ..where(documents.categoryId.equals(categoryId));
    final result = await query.getSingle();
    return result.read(documents.id.count()) ?? 0;
  }

  /// Поиск документов по запросу
  Future<List<DocumentsData>> searchDocuments(String query) {
    final searchQuery = query.toLowerCase();
    return (select(documents)..where(
          (d) =>
              d.title.lower().like('%$searchQuery%') |
              d.description.lower().like('%$searchQuery%') |
              d.aggregatedText.lower().like('%$searchQuery%'),
        ))
        .get();
  }

  /// Получить последние измененные документы
  Future<List<DocumentsData>> getRecentlyModifiedDocuments({int limit = 10}) {
    return (select(documents)
          ..orderBy([(d) => OrderingTerm.desc(d.modifiedAt)])
          ..limit(limit))
        .get();
  }

  /// Получить часто используемые документы
  Future<List<DocumentsData>> getFrequentlyUsedDocuments({int limit = 10}) {
    return (select(documents)
          ..where((d) => d.usedCount.isBiggerThanValue(0))
          ..orderBy([(d) => OrderingTerm.desc(d.usedCount)])
          ..limit(limit))
        .get();
  }
}
