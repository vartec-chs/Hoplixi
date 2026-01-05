import 'package:drift/drift.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/graph_data.dart';
import 'package:hoplixi/main_store/tables/index.dart';

part 'note_link_dao.g.dart';

/// DAO для управления связями между заметками
@DriftAccessor(tables: [NoteLinks, Notes, Categories, Tags, NotesTags])
class NoteLinkDao extends DatabaseAccessor<MainStore> with _$NoteLinkDaoMixin {
  NoteLinkDao(super.db);

  static const String _logTag = 'NoteLinkDao';

  /// Подготовить данные для графа (flutter_graph_view).
  ///
  /// Возвращает структуру GraphData с вершинами и рёбрами графа.
  Future<GraphData> getGraphData() async {
    // 1) Загружаем заметки (без удалённых)
    final notesRows =
        await (select(notes)
              ..where((n) => n.isDeleted.equals(false))
              ..orderBy([(n) => OrderingTerm.desc(n.modifiedAt)]))
            .get();

    final noteIds = notesRows.map((n) => n.id).toSet();

    // 2) Загружаем связи и фильтруем по существующим заметкам
    final linksRows = await select(noteLinks).get();

    final vertexes = <VertexData>{};
    final edges = <EdgeData>{};

    for (final n in notesRows) {
      // Tag для раскраски: используем стабильное распределение по 4 цветам.
      final bucket = (n.categoryId?.hashCode ?? n.id.hashCode).abs() % 4;
      final tag = 'tag$bucket';

      vertexes.add(VertexData(id: n.id, tag: tag, tags: [tag], title: n.title));
    }

    for (final l in linksRows) {
      if (!noteIds.contains(l.sourceNoteId) ||
          !noteIds.contains(l.targetNoteId)) {
        continue;
      }

      edges.add(
        EdgeData(
          srcId: l.sourceNoteId,
          dstId: l.targetNoteId,
          edgeName: 'link',
          ranking: l.createdAt.millisecondsSinceEpoch,
        ),
      );
    }

    return GraphData(vertexes: vertexes.toList(), edges: edges.toList());
  }

  /// Создать связь между заметками
  ///
  /// [sourceNoteId] - ID заметки, откуда идет ссылка
  /// [targetNoteId] - ID заметки, куда идет ссылка
  /// Возвращает true если связь создана, false если уже существует
  Future<bool> createLink(String sourceNoteId, String targetNoteId) async {
    // Предотвращаем создание связи заметки на саму себя
    if (sourceNoteId == targetNoteId) {
      logWarning(
        'Попытка создать связь заметки на саму себя: $sourceNoteId',
        tag: _logTag,
      );
      return false;
    }

    try {
      await db.transaction(() async {
        // Создаем связь
        await into(noteLinks).insert(
          NoteLinksCompanion.insert(
            sourceNoteId: sourceNoteId,
            targetNoteId: targetNoteId,
          ),
        );

        // Увеличиваем счетчик использования целевой заметки
        await _incrementNoteUsage(targetNoteId);

        logInfo('Создана связь: $sourceNoteId -> $targetNoteId', tag: _logTag);
      });
      return true;
    } catch (e) {
      // Ошибка уникальности - связь уже существует
      logWarning(
        'Связь уже существует: $sourceNoteId -> $targetNoteId',
        tag: _logTag,
      );
      return false;
    }
  }

  /// Удалить связь между заметками
  ///
  /// Возвращает true если связь удалена
  Future<bool> deleteLink(String sourceNoteId, String targetNoteId) async {
    return await db.transaction(() async {
      // Проверяем существование связи
      final linkExists =
          await (select(noteLinks)..where(
                (link) =>
                    link.sourceNoteId.equals(sourceNoteId) &
                    link.targetNoteId.equals(targetNoteId),
              ))
              .getSingleOrNull();

      if (linkExists == null) {
        logWarning(
          'Попытка удалить несуществующую связь: $sourceNoteId -> $targetNoteId',
          tag: _logTag,
        );
        return false;
      }

      // Удаляем связь
      final rowsAffected =
          await (delete(noteLinks)..where(
                (link) =>
                    link.sourceNoteId.equals(sourceNoteId) &
                    link.targetNoteId.equals(targetNoteId),
              ))
              .go();

      if (rowsAffected > 0) {
        // Уменьшаем счетчик использования целевой заметки
        await _decrementNoteUsage(targetNoteId);

        logInfo('Удалена связь: $sourceNoteId -> $targetNoteId', tag: _logTag);
        return true;
      }

      return false;
    });
  }

  /// Удалить связь по ID
  Future<bool> deleteLinkById(String linkId) async {
    return await db.transaction(() async {
      // Получаем информацию о связи для логирования
      final link = await (select(
        noteLinks,
      )..where((l) => l.id.equals(linkId))).getSingleOrNull();

      if (link == null) {
        logWarning(
          'Попытка удалить несуществующую связь: $linkId',
          tag: _logTag,
        );
        return false;
      }

      // Удаляем связь
      final rowsAffected = await (delete(
        noteLinks,
      )..where((l) => l.id.equals(linkId))).go();

      if (rowsAffected > 0) {
        // Уменьшаем счетчик использования целевой заметки
        await _decrementNoteUsage(link.targetNoteId);

        logInfo(
          'Удалена связь по ID: ${link.sourceNoteId} -> ${link.targetNoteId}',
          tag: _logTag,
        );
        return true;
      }

      return false;
    });
  }

  /// Получить все исходящие связи (на которые ссылается заметка)
  ///
  /// Возвращает список заметок, на которые ссылается [sourceNoteId]
  Future<List<NoteCardDto>> getOutgoingLinks(String sourceNoteId) async {
    final query =
        select(noteLinks).join([
            innerJoin(notes, notes.id.equalsExp(noteLinks.targetNoteId)),
            leftOuterJoin(
              categories,
              categories.id.equalsExp(notes.categoryId),
            ),
          ])
          ..where(noteLinks.sourceNoteId.equals(sourceNoteId))
          ..orderBy([OrderingTerm.desc(noteLinks.createdAt)]);

    final results = await query.get();

    // Загружаем теги для всех связанных заметок
    final targetNoteIds = results
        .map((row) => row.readTable(notes).id)
        .toList();
    final tagsMap = await _loadTagsForNotes(targetNoteIds);

    return results.map((row) {
      final note = row.readTable(notes);
      final category = row.readTableOrNull(categories);

      return NoteCardDto(
        id: note.id,
        title: note.title,
        description: note.description,
        isFavorite: note.isFavorite,
        isPinned: note.isPinned,
        isArchived: note.isArchived,
        isDeleted: note.isDeleted,
        usedCount: note.usedCount,
        modifiedAt: note.modifiedAt,
        category: category != null
            ? CategoryInCardDto(
                id: category.id,
                name: category.name,
                type: category.type.name,
                color: category.color,
                iconId: category.iconId,
              )
            : null,
        tags: tagsMap[note.id] ?? [],
      );
    }).toList();
  }

  /// Получить все входящие связи (которые ссылаются на заметку)
  ///
  /// Возвращает список заметок, которые ссылаются на [targetNoteId]
  Future<List<NoteCardDto>> getIncomingLinks(String targetNoteId) async {
    final query =
        select(noteLinks).join([
            innerJoin(notes, notes.id.equalsExp(noteLinks.sourceNoteId)),
            leftOuterJoin(
              categories,
              categories.id.equalsExp(notes.categoryId),
            ),
          ])
          ..where(noteLinks.targetNoteId.equals(targetNoteId))
          ..orderBy([OrderingTerm.desc(noteLinks.createdAt)]);

    final results = await query.get();

    // Загружаем теги для всех связанных заметок
    final sourceNoteIds = results
        .map((row) => row.readTable(notes).id)
        .toList();
    final tagsMap = await _loadTagsForNotes(sourceNoteIds);

    return results.map((row) {
      final note = row.readTable(notes);
      final category = row.readTableOrNull(categories);

      return NoteCardDto(
        id: note.id,
        title: note.title,
        description: note.description,
        isFavorite: note.isFavorite,
        isPinned: note.isPinned,
        isArchived: note.isArchived,
        isDeleted: note.isDeleted,
        usedCount: note.usedCount,
        modifiedAt: note.modifiedAt,
        category: category != null
            ? CategoryInCardDto(
                id: category.id,
                name: category.name,
                type: category.type.name,
                color: category.color,
                iconId: category.iconId,
              )
            : null,
        tags: tagsMap[note.id] ?? [],
      );
    }).toList();
  }

  /// Получить количество исходящих связей
  Future<int> countOutgoingLinks(String sourceNoteId) async {
    final query = selectOnly(noteLinks)
      ..addColumns([noteLinks.id.count()])
      ..where(noteLinks.sourceNoteId.equals(sourceNoteId));

    final result = await query.getSingle();
    return result.read(noteLinks.id.count()) ?? 0;
  }

  /// Получить количество входящих связей
  Future<int> countIncomingLinks(String targetNoteId) async {
    final query = selectOnly(noteLinks)
      ..addColumns([noteLinks.id.count()])
      ..where(noteLinks.targetNoteId.equals(targetNoteId));

    final result = await query.getSingle();
    return result.read(noteLinks.id.count()) ?? 0;
  }

  /// Проверить существование связи
  Future<bool> linkExists(String sourceNoteId, String targetNoteId) async {
    final link =
        await (select(noteLinks)..where(
              (link) =>
                  link.sourceNoteId.equals(sourceNoteId) &
                  link.targetNoteId.equals(targetNoteId),
            ))
            .getSingleOrNull();
    return link != null;
  }

  /// Получить все связи заметки (входящие и исходящие)
  Future<Map<String, dynamic>> getAllLinks(String noteId) async {
    final outgoing = await getOutgoingLinks(noteId);
    final incoming = await getIncomingLinks(noteId);

    return {
      'outgoing': outgoing,
      'incoming': incoming,
      'outgoingCount': outgoing.length,
      'incomingCount': incoming.length,
    };
  }

  /// Удалить все связи заметки (при удалении заметки)
  Future<void> deleteAllLinksForNote(String noteId) async {
    await db.transaction(() async {
      // Подсчитываем количество удаляемых связей для логирования
      final outgoingCount = await countOutgoingLinks(noteId);
      final incomingCount = await countIncomingLinks(noteId);

      // Получаем все входящие связи для обновления счетчиков
      final incomingLinks = await (select(
        noteLinks,
      )..where((link) => link.targetNoteId.equals(noteId))).get();

      // Удаляем исходящие связи
      await (delete(
        noteLinks,
      )..where((link) => link.sourceNoteId.equals(noteId))).go();

      // Удаляем входящие связи
      await (delete(
        noteLinks,
      )..where((link) => link.targetNoteId.equals(noteId))).go();

      // Уменьшаем счетчик использования для каждой связи, которая ссылалась на удаляемую заметку
      // (это входящие связи, где noteId является целевым)
      if (incomingLinks.isNotEmpty) {
        await _decrementNoteUsage(noteId, count: incomingLinks.length);
      }

      logInfo(
        'Удалены все связи заметки $noteId: исходящих=$outgoingCount, входящих=$incomingCount',
        tag: _logTag,
      );
    });
  }

  /// Синхронизировать связи заметки на основе содержимого
  ///
  /// Анализирует deltaJson и создает связи для всех ссылок формата note://
  Future<void> syncLinksFromContent(
    String sourceNoteId,
    String deltaJson,
  ) async {
    // Извлекаем все ID заметок из ссылок в deltaJson
    final noteIdPattern = RegExp(r'note://([a-f0-9-]+)');
    final matches = noteIdPattern.allMatches(deltaJson);
    final targetNoteIds = matches.map((m) => m.group(1)!).toSet().toList();

    await db.transaction(() async {
      // Получаем существующие связи
      final existingLinks = await (select(
        noteLinks,
      )..where((link) => link.sourceNoteId.equals(sourceNoteId))).get();
      final existingTargetIds = existingLinks
          .map((link) => link.targetNoteId)
          .toSet();

      final newTargetIds = targetNoteIds.toSet();

      // Удаляем связи, которых больше нет в контенте
      final toDelete = existingTargetIds.difference(newTargetIds);
      if (toDelete.isNotEmpty) {
        // Для корректного usedCount: уменьшаем счетчик на количество удаляемых связей
        for (final targetId in toDelete) {
          await _decrementNoteUsage(targetId);
        }
        await (delete(noteLinks)..where(
              (link) =>
                  link.sourceNoteId.equals(sourceNoteId) &
                  link.targetNoteId.isIn(toDelete),
            ))
            .go();
      }

      // Создаем новые связи
      final toCreate = newTargetIds.difference(existingTargetIds);
      for (final targetId in toCreate) {
        await createLink(sourceNoteId, targetId);
      }

      if (toDelete.isNotEmpty || toCreate.isNotEmpty) {
        logInfo(
          'Синхронизированы связи для $sourceNoteId: удалено=${toDelete.length}, создано=${toCreate.length}',
          tag: _logTag,
        );
      }
    });
  }

  /// Увеличить счетчик использования заметки
  Future<void> _incrementNoteUsage(String noteId) async {
    // Получаем текущее значение счетчика
    final note = await (select(
      notes,
    )..where((n) => n.id.equals(noteId))).getSingleOrNull();

    if (note != null) {
      await (update(notes)..where((n) => n.id.equals(noteId))).write(
        NotesCompanion(
          usedCount: Value(note.usedCount + 1),
          lastUsedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Уменьшить счетчик использования заметки
  Future<void> _decrementNoteUsage(String noteId, {int count = 1}) async {
    // Получаем текущее значение счетчика
    final note = await (select(
      notes,
    )..where((n) => n.id.equals(noteId))).getSingleOrNull();

    if (note != null && note.usedCount > 0) {
      final newCount = (note.usedCount - count)
          .clamp(0, double.infinity)
          .toInt();
      await (update(notes)..where((n) => n.id.equals(noteId))).write(
        NotesCompanion(usedCount: Value(newCount)),
      );
    }
  }

  /// Загрузить теги для списка заметок
  Future<Map<String, List<TagInCardDto>>> _loadTagsForNotes(
    List<String> noteIds,
  ) async {
    if (noteIds.isEmpty) return {};

    final query = select(db.notesTags).join([
      innerJoin(tags, tags.id.equalsExp(db.notesTags.tagId)),
    ])..where(db.notesTags.noteId.isIn(noteIds));

    final results = await query.get();

    final tagsMap = <String, List<TagInCardDto>>{};
    for (final row in results) {
      final noteId = row.readTable(db.notesTags).noteId;
      final tag = row.readTable(tags);

      tagsMap
          .putIfAbsent(noteId, () => [])
          .add(TagInCardDto(id: tag.id, name: tag.name, color: tag.color));
    }

    return tagsMap;
  }
}
