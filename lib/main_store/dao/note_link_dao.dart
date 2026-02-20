import 'package:drift/drift.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/main_store/models/graph_data.dart';
import 'package:hoplixi/main_store/tables/categories.dart';
import 'package:hoplixi/main_store/tables/item_tags.dart';
import 'package:hoplixi/main_store/tables/note_items.dart';
import 'package:hoplixi/main_store/tables/note_links.dart';
import 'package:hoplixi/main_store/tables/tags.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';

part 'note_link_dao.g.dart';

/// DAO для управления связями между заметками
@DriftAccessor(
  tables: [NoteLinks, VaultItems, NoteItems, Categories, Tags, ItemTags],
)
class NoteLinkDao extends DatabaseAccessor<MainStore> with _$NoteLinkDaoMixin {
  NoteLinkDao(super.db);

  static const String _logTag = 'NoteLinkDao';

  /// Подготовить данные для графа.
  Future<GraphData> getGraphData() async {
    // Загружаем заметки (vault_items WHERE type=note,
    // без удалённых)
    final notesQuery = select(vaultItems)
      ..where(
        (v) =>
            v.type.equalsValue(VaultItemType.note) & v.isDeleted.equals(false),
      )
      ..orderBy([(v) => OrderingTerm.desc(v.modifiedAt)]);
    final notesRows = await notesQuery.get();

    final noteIds = notesRows.map((n) => n.id).toSet();

    final linksRows = await select(noteLinks).get();

    final vertexes = <VertexData>{};
    final edges = <EdgeData>{};

    for (final n in notesRows) {
      final bucket = (n.categoryId?.hashCode ?? n.id.hashCode).abs() % 4;
      final tag = 'tag$bucket';
      vertexes.add(VertexData(id: n.id, tag: tag, tags: [tag], title: n.name));
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
  Future<bool> createLink(String sourceNoteId, String targetNoteId) async {
    if (sourceNoteId == targetNoteId) {
      logWarning(
        'Попытка создать связь на саму себя: '
        '$sourceNoteId',
        tag: _logTag,
      );
      return false;
    }

    try {
      await db.transaction(() async {
        await into(noteLinks).insert(
          NoteLinksCompanion.insert(
            sourceNoteId: sourceNoteId,
            targetNoteId: targetNoteId,
          ),
        );
        await _incrementItemUsage(targetNoteId);
        logInfo(
          'Создана связь: '
          '$sourceNoteId -> $targetNoteId',
          tag: _logTag,
        );
      });
      return true;
    } catch (e) {
      logWarning(
        'Связь уже существует: '
        '$sourceNoteId -> $targetNoteId',
        tag: _logTag,
      );
      return false;
    }
  }

  /// Удалить связь между заметками
  Future<bool> deleteLink(String sourceNoteId, String targetNoteId) async {
    return await db.transaction(() async {
      final linkExists =
          await (select(noteLinks)..where(
                (link) =>
                    link.sourceNoteId.equals(sourceNoteId) &
                    link.targetNoteId.equals(targetNoteId),
              ))
              .getSingleOrNull();

      if (linkExists == null) {
        logWarning(
          'Попытка удалить несуществующую связь: '
          '$sourceNoteId -> $targetNoteId',
          tag: _logTag,
        );
        return false;
      }

      final rowsAffected =
          await (delete(noteLinks)..where(
                (link) =>
                    link.sourceNoteId.equals(sourceNoteId) &
                    link.targetNoteId.equals(targetNoteId),
              ))
              .go();

      if (rowsAffected > 0) {
        await _decrementItemUsage(targetNoteId);
        logInfo(
          'Удалена связь: '
          '$sourceNoteId -> $targetNoteId',
          tag: _logTag,
        );
        return true;
      }
      return false;
    });
  }

  /// Удалить связь по ID
  Future<bool> deleteLinkById(String linkId) async {
    return await db.transaction(() async {
      final link = await (select(
        noteLinks,
      )..where((l) => l.id.equals(linkId))).getSingleOrNull();

      if (link == null) {
        logWarning(
          'Попытка удалить несуществующую связь: '
          '$linkId',
          tag: _logTag,
        );
        return false;
      }

      final rowsAffected = await (delete(
        noteLinks,
      )..where((l) => l.id.equals(linkId))).go();

      if (rowsAffected > 0) {
        await _decrementItemUsage(link.targetNoteId);
        logInfo(
          'Удалена связь по ID: '
          '${link.sourceNoteId} -> '
          '${link.targetNoteId}',
          tag: _logTag,
        );
        return true;
      }
      return false;
    });
  }

  /// Получить исходящие связи (NoteCardDto)
  Future<List<NoteCardDto>> getOutgoingLinks(String sourceNoteId) async {
    final query =
        select(noteLinks).join([
            innerJoin(
              vaultItems,
              vaultItems.id.equalsExp(noteLinks.targetNoteId),
            ),
            leftOuterJoin(
              categories,
              categories.id.equalsExp(vaultItems.categoryId),
            ),
          ])
          ..where(noteLinks.sourceNoteId.equals(sourceNoteId))
          ..orderBy([OrderingTerm.desc(noteLinks.createdAt)]);

    final results = await query.get();

    final targetIds = results
        .map((row) => row.readTable(vaultItems).id)
        .toList();
    final tagsMap = await _loadTagsForItems(targetIds);

    return results.map((row) {
      final item = row.readTable(vaultItems);
      final category = row.readTableOrNull(categories);

      return NoteCardDto(
        id: item.id,
        title: item.name,
        description: item.description,
        isFavorite: item.isFavorite,
        isPinned: item.isPinned,
        isArchived: item.isArchived,
        isDeleted: item.isDeleted,
        usedCount: item.usedCount,
        modifiedAt: item.modifiedAt,
        category: category != null
            ? CategoryInCardDto(
                id: category.id,
                name: category.name,
                type: category.type.name,
                color: category.color,
                iconId: category.iconId,
              )
            : null,
        tags: tagsMap[item.id] ?? [],
      );
    }).toList();
  }

  /// Получить входящие связи
  Future<List<NoteCardDto>> getIncomingLinks(String targetNoteId) async {
    final query =
        select(noteLinks).join([
            innerJoin(
              vaultItems,
              vaultItems.id.equalsExp(noteLinks.sourceNoteId),
            ),
            leftOuterJoin(
              categories,
              categories.id.equalsExp(vaultItems.categoryId),
            ),
          ])
          ..where(noteLinks.targetNoteId.equals(targetNoteId))
          ..orderBy([OrderingTerm.desc(noteLinks.createdAt)]);

    final results = await query.get();

    final sourceIds = results
        .map((row) => row.readTable(vaultItems).id)
        .toList();
    final tagsMap = await _loadTagsForItems(sourceIds);

    return results.map((row) {
      final item = row.readTable(vaultItems);
      final category = row.readTableOrNull(categories);

      return NoteCardDto(
        id: item.id,
        title: item.name,
        description: item.description,
        isFavorite: item.isFavorite,
        isPinned: item.isPinned,
        isArchived: item.isArchived,
        isDeleted: item.isDeleted,
        usedCount: item.usedCount,
        modifiedAt: item.modifiedAt,
        category: category != null
            ? CategoryInCardDto(
                id: category.id,
                name: category.name,
                type: category.type.name,
                color: category.color,
                iconId: category.iconId,
              )
            : null,
        tags: tagsMap[item.id] ?? [],
      );
    }).toList();
  }

  /// Количество исходящих связей
  Future<int> countOutgoingLinks(String sourceNoteId) async {
    final query = selectOnly(noteLinks)
      ..addColumns([noteLinks.id.count()])
      ..where(noteLinks.sourceNoteId.equals(sourceNoteId));
    final result = await query.getSingle();
    return result.read(noteLinks.id.count()) ?? 0;
  }

  /// Количество входящих связей
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

  /// Все связи заметки
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

  /// Удалить все связи заметки
  Future<void> deleteAllLinksForNote(String noteId) async {
    await db.transaction(() async {
      final outgoingCount = await countOutgoingLinks(noteId);
      final incomingCount = await countIncomingLinks(noteId);

      final incomingLinks = await (select(
        noteLinks,
      )..where((link) => link.targetNoteId.equals(noteId))).get();

      await (delete(
        noteLinks,
      )..where((link) => link.sourceNoteId.equals(noteId))).go();
      await (delete(
        noteLinks,
      )..where((link) => link.targetNoteId.equals(noteId))).go();

      if (incomingLinks.isNotEmpty) {
        await _decrementItemUsage(noteId, count: incomingLinks.length);
      }

      logInfo(
        'Удалены все связи $noteId: '
        'исходящих=$outgoingCount, '
        'входящих=$incomingCount',
        tag: _logTag,
      );
    });
  }

  /// Синхронизировать связи из контента
  Future<void> syncLinksFromContent(
    String sourceNoteId,
    String deltaJson,
  ) async {
    final noteIdPattern = RegExp(r'note://([a-f0-9-]+)');
    final matches = noteIdPattern.allMatches(deltaJson);
    final targetNoteIds = matches.map((m) => m.group(1)!).toSet().toList();

    await db.transaction(() async {
      final existingLinks = await (select(
        noteLinks,
      )..where((link) => link.sourceNoteId.equals(sourceNoteId))).get();
      final existingTargetIds = existingLinks
          .map((link) => link.targetNoteId)
          .toSet();

      final newTargetIds = targetNoteIds.toSet();

      final toDelete = existingTargetIds.difference(newTargetIds);
      if (toDelete.isNotEmpty) {
        for (final targetId in toDelete) {
          await _decrementItemUsage(targetId);
        }
        await (delete(noteLinks)..where(
              (link) =>
                  link.sourceNoteId.equals(sourceNoteId) &
                  link.targetNoteId.isIn(toDelete),
            ))
            .go();
      }

      final toCreate = newTargetIds.difference(existingTargetIds);
      for (final targetId in toCreate) {
        await createLink(sourceNoteId, targetId);
      }

      if (toDelete.isNotEmpty || toCreate.isNotEmpty) {
        logInfo(
          'Синхронизированы связи для '
          '$sourceNoteId: '
          'удалено=${toDelete.length}, '
          'создано=${toCreate.length}',
          tag: _logTag,
        );
      }
    });
  }

  /// Увеличить usedCount через vault_items
  Future<void> _incrementItemUsage(String itemId) async {
    final item = await (select(
      vaultItems,
    )..where((v) => v.id.equals(itemId))).getSingleOrNull();

    if (item != null) {
      await (update(vaultItems)..where((v) => v.id.equals(itemId))).write(
        VaultItemsCompanion(
          usedCount: Value(item.usedCount + 1),
          lastUsedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Уменьшить usedCount
  Future<void> _decrementItemUsage(String itemId, {int count = 1}) async {
    final item = await (select(
      vaultItems,
    )..where((v) => v.id.equals(itemId))).getSingleOrNull();

    if (item != null && item.usedCount > 0) {
      final newCount = (item.usedCount - count)
          .clamp(0, double.infinity)
          .toInt();
      await (update(vaultItems)..where((v) => v.id.equals(itemId))).write(
        VaultItemsCompanion(usedCount: Value(newCount)),
      );
    }
  }

  /// Загрузить теги для элементов (item_tags)
  Future<Map<String, List<TagInCardDto>>> _loadTagsForItems(
    List<String> itemIds,
  ) async {
    if (itemIds.isEmpty) return {};

    final query = select(itemTags).join([
      innerJoin(tags, tags.id.equalsExp(itemTags.tagId)),
    ])..where(itemTags.itemId.isIn(itemIds));

    final results = await query.get();

    final tagsMap = <String, List<TagInCardDto>>{};
    for (final row in results) {
      final it = row.readTable(itemTags);
      final tag = row.readTable(tags);

      tagsMap
          .putIfAbsent(it.itemId, () => [])
          .add(TagInCardDto(id: tag.id, name: tag.name, color: tag.color));
    }
    return tagsMap;
  }
}
