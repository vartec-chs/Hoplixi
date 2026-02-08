import 'dart:math' show exp;

import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/note_dto.dart';
import 'package:hoplixi/main_store/tables/notes.dart';
import 'package:uuid/uuid.dart';

part 'note_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NoteDao extends DatabaseAccessor<MainStore>
    with _$NoteDaoMixin
    implements BaseMainEntityDao {
  NoteDao(super.db);

  /// Получить все заметки
  Future<List<NotesData>> getAllNotes() {
    return select(notes).get();
  }

  /// Получить заметку по ID
  Future<NotesData?> getNoteById(String id) {
    return (select(notes)..where((n) => n.id.equals(id))).getSingleOrNull();
  }

  /// Переключить избранное
  @override
  Future<bool> toggleFavorite(String id, bool isFavorite) async {
    final result = await (update(notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(isFavorite: Value(isFavorite)),
    );

    return result > 0;
  }

  /// Переключить закрепление
  @override
  Future<bool> togglePin(String id, bool isPinned) async {
    final result = await (update(notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(isPinned: Value(isPinned)),
    );

    return result > 0;
  }

  /// Переключить архивирование
  @override
  Future<bool> toggleArchive(String id, bool isArchived) async {
    final result = await (update(notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(isArchived: Value(isArchived)),
    );

    return result > 0;
  }

  /// Смотреть все заметки с автообновлением
  Stream<List<NotesData>> watchAllNotes() {
    return (select(
      notes,
    )..orderBy([(n) => OrderingTerm.desc(n.modifiedAt)])).watch();
  }

  /// Создать новую заметку
  Future<String> createNote(CreateNoteDto dto) async {
    final uuid = const Uuid().v4();
    return await db.transaction(() async {
      final companion = NotesCompanion.insert(
        id: Value(uuid),
        title: dto.title,
        content: dto.content,
        deltaJson: dto.deltaJson,
        description: Value(dto.description),
        categoryId: Value(dto.categoryId),
      );
      await into(notes).insert(companion);
      await _insertNoteTags(uuid, dto.tagsIds);

      // Синхронизируем связи на основе deltaJson
      await db.noteLinkDao.syncLinksFromContent(uuid, dto.deltaJson);

      return uuid;
    });
  }

  Future<void> _insertNoteTags(String noteId, List<String>? tagIds) async {
    if (tagIds == null || tagIds.isEmpty) return;
    for (final tagId in tagIds) {
      await db
          .into(db.notesTags)
          .insert(NotesTagsCompanion.insert(noteId: noteId, tagId: tagId));
    }
  }

  /// Получить ID тегов заметки
  Future<List<String>> getNoteTagIds(String noteId) async {
    final rows = await (select(
      db.notesTags,
    )..where((t) => t.noteId.equals(noteId))).get();
    return rows.map((row) => row.tagId).toList();
  }

  /// Синхронизировать теги заметки
  Future<void> syncNoteTags(String noteId, List<String> tagIds) async {
    await db.transaction(() async {
      final existing = await (select(
        db.notesTags,
      )..where((t) => t.noteId.equals(noteId))).get();
      final existingIds = existing.map((row) => row.tagId).toSet();
      final newIds = tagIds.toSet();

      final toDelete = existingIds.difference(newIds);
      if (toDelete.isNotEmpty) {
        await (delete(
          db.notesTags,
        )..where((t) => t.noteId.equals(noteId) & t.tagId.isIn(toDelete))).go();
      }

      final toInsert = newIds.difference(existingIds);
      for (final tagId in toInsert) {
        await db
            .into(db.notesTags)
            .insert(NotesTagsCompanion.insert(noteId: noteId, tagId: tagId));
      }
    });
  }

  /// Увеличить счетчик использования и обновить метрики
  @override
  Future<bool> incrementUsage(String id) async {
    final note = await getNoteById(id);
    if (note == null) return false;

    final now = DateTime.now();
    final currentUsedCount = note.usedCount + 1;

    // Вычисляем новый recentScore по формуле EWMA: score = score * exp(-Δt / τ) + 1
    double newScore = 1.0;
    if (note.lastUsedAt != null && note.recentScore != null) {
      final deltaSeconds = now
          .difference(note.lastUsedAt!)
          .inSeconds
          .toDouble();
      final tau = const Duration(days: 7).inSeconds.toDouble(); // 7 дней в секундах
      final decayFactor = exp(-deltaSeconds / tau);
      newScore = note.recentScore! * decayFactor + 1.0;
    }

    final result = await (update(notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(
        usedCount: Value(currentUsedCount),
        recentScore: Value(newScore),
        lastUsedAt: Value(now),
      ),
    );

    return result > 0;
  }

  /// Обновить заметку
  Future<bool> updateNote(String id, UpdateNoteDto dto) async {
    return await db.transaction(() async {
      final companion = NotesCompanion(
        // Обязательные поля - пропускаем если null
        title: dto.title != null ? Value(dto.title!) : const Value.absent(),
        content: dto.content != null
            ? Value(dto.content!)
            : const Value.absent(),
        deltaJson: dto.deltaJson != null
            ? Value(dto.deltaJson!)
            : const Value.absent(),
        // Nullable поля - затираем при любом значении (включая null)
        description: Value(dto.description),
        categoryId: Value(dto.categoryId),
        // Bool флаги - пропускаем если null
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
        attachedDatabase.notes,
      )..where((t) => t.id.equals(id))).write(companion);

      if (dto.tagsIds != null) {
        await syncNoteTags(id, dto.tagsIds!);
      }

      // Синхронизируем связи если deltaJson был обновлен
      if (dto.deltaJson != null) {
        await db.noteLinkDao.syncLinksFromContent(id, dto.deltaJson!);
      }

      return rowsAffected > 0;
    });
  }

  /// Мягкое удаление заметки
  @override
  Future<bool> softDelete(String id) async {
    final rowsAffected = await (update(notes)..where((n) => n.id.equals(id)))
        .write(const NotesCompanion(isDeleted: Value(true)));
    return rowsAffected > 0;
  }

  /// Восстановить заметку из удалённых
  @override
  Future<bool> restoreFromDeleted(String id) async {
    final rowsAffected = await (update(notes)..where((n) => n.id.equals(id)))
        .write(const NotesCompanion(isDeleted: Value(false)));
    return rowsAffected > 0;
  }

  /// Полное удаление заметки
  @override
  Future<bool> permanentDelete(String id) async {
    return await db.transaction(() async {
      // Удаляем все связи заметки
      await db.noteLinkDao.deleteAllLinksForNote(id);

      // Удаляем саму заметку
      final rowsAffected = await (delete(
        notes,
      )..where((n) => n.id.equals(id))).go();

      return rowsAffected > 0;
    });
  }
}
