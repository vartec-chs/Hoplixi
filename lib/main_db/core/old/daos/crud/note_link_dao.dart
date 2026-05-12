import 'package:drift/drift.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/old/models/dto/index.dart';
import 'package:hoplixi/main_db/core/models/enums/entity_types.dart';
import 'package:hoplixi/main_db/core/old/models/dto/tag_dto.dart';
import 'package:hoplixi/main_db/core/old/models/graph_data.dart';
import 'package:hoplixi/shared/utils/vault_link_utils.dart';
import 'package:hoplixi/main_db/core/tables/system/categories.dart';
import 'package:hoplixi/main_db/core/tables/system/item_tags.dart';
import 'package:hoplixi/main_db/core/tables/note/note_items.dart';
import 'package:hoplixi/main_db/core/tables/note/note_links.dart';
import 'package:hoplixi/main_db/core/tables/system/tags.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';

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
          !noteIds.contains(l.targetVaultItemId)) {
        continue;
      }
      edges.add(
        EdgeData(
          srcId: l.sourceNoteId,
          dstId: l.targetVaultItemId,
          edgeName: 'link',
          ranking: l.createdAt.millisecondsSinceEpoch,
        ),
      );
    }

    return GraphData(vertexes: vertexes.toList(), edges: edges.toList());
  }

  /// Создать связь note -> vault item.
  Future<bool> createLink(String sourceNoteId, String targetItemId) async {
    if (sourceNoteId == targetItemId) {
      logWarning(
        'Попытка создать self-link note -> note: $sourceNoteId',
        tag: _logTag,
      );
      return false;
    }

    try {
      await db.transaction(() async {
        await into(noteLinks).insert(
          NoteLinksCompanion.insert(
            sourceNoteId: sourceNoteId,
            targetVaultItemId: targetItemId,
          ),
        );
        await _incrementItemUsage(targetItemId);
        logInfo('Создана связь: $sourceNoteId -> $targetItemId', tag: _logTag);
      });
      return true;
    } catch (e) {
      logWarning(
        'Связь уже существует: $sourceNoteId -> $targetItemId',
        tag: _logTag,
      );
      return false;
    }
  }

  /// Удалить связь note -> vault item.
  Future<bool> deleteLink(String sourceNoteId, String targetItemId) async {
    return await db.transaction(() async {
      final linkExists =
          await (select(noteLinks)..where(
                (link) =>
                    link.sourceNoteId.equals(sourceNoteId) &
                    link.targetVaultItemId.equals(targetItemId),
              ))
              .getSingleOrNull();

      if (linkExists == null) {
        logWarning(
          'Попытка удалить несуществующую связь: $sourceNoteId -> $targetItemId',
          tag: _logTag,
        );
        return false;
      }

      final rowsAffected =
          await (delete(noteLinks)..where(
                (link) =>
                    link.sourceNoteId.equals(sourceNoteId) &
                    link.targetVaultItemId.equals(targetItemId),
              ))
              .go();

      if (rowsAffected > 0) {
        await _decrementItemUsage(targetItemId);
        logInfo('Удалена связь: $sourceNoteId -> $targetItemId', tag: _logTag);
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
        await _decrementItemUsage(link.targetVaultItemId);
        logInfo(
          'Удалена связь по ID: ${link.sourceNoteId} -> ${link.targetVaultItemId}',
          tag: _logTag,
        );
        return true;
      }
      return false;
    });
  }

  /// Получить исходящие связи note -> vault item.
  Future<List<LinkedVaultItemCardDto>> getOutgoingLinks(
    String sourceNoteId,
  ) async {
    final query =
        select(noteLinks).join([
            innerJoin(
              vaultItems,
              vaultItems.id.equalsExp(noteLinks.targetVaultItemId),
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
      return _mapLinkedItem(row, tagsMap);
    }).toList();
  }

  /// Получить входящие связи на vault item.
  Future<List<LinkedVaultItemCardDto>> getIncomingLinks(
    String targetItemId,
  ) async {
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
          ..where(noteLinks.targetVaultItemId.equals(targetItemId))
          ..orderBy([OrderingTerm.desc(noteLinks.createdAt)]);

    final results = await query.get();

    final sourceIds = results
        .map((row) => row.readTable(vaultItems).id)
        .toList();
    final tagsMap = await _loadTagsForItems(sourceIds);

    return results.map((row) {
      return _mapLinkedItem(row, tagsMap);
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
  Future<int> countIncomingLinks(String targetItemId) async {
    final query = selectOnly(noteLinks)
      ..addColumns([noteLinks.id.count()])
      ..where(noteLinks.targetVaultItemId.equals(targetItemId));
    final result = await query.getSingle();
    return result.read(noteLinks.id.count()) ?? 0;
  }

  /// Проверить существование связи
  Future<bool> linkExists(String sourceNoteId, String targetItemId) async {
    final link =
        await (select(noteLinks)..where(
              (link) =>
                  link.sourceNoteId.equals(sourceNoteId) &
                  link.targetVaultItemId.equals(targetItemId),
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
      )..where((link) => link.targetVaultItemId.equals(noteId))).get();

      await (delete(
        noteLinks,
      )..where((link) => link.sourceNoteId.equals(noteId))).go();
      await (delete(
        noteLinks,
      )..where((link) => link.targetVaultItemId.equals(noteId))).go();

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
    final targetItemIds = extractLinkedItemIds(
      deltaJson,
    ).where((itemId) => itemId != sourceNoteId).toSet().toList();

    await db.transaction(() async {
      final existingLinks = await (select(
        noteLinks,
      )..where((link) => link.sourceNoteId.equals(sourceNoteId))).get();
      final existingTargetIds = existingLinks
          .map((link) => link.targetVaultItemId)
          .toSet();

      final newTargetIds = targetItemIds.toSet();

      final toDelete = existingTargetIds.difference(newTargetIds);
      if (toDelete.isNotEmpty) {
        for (final targetId in toDelete) {
          await _decrementItemUsage(targetId);
        }
        await (delete(noteLinks)..where(
              (link) =>
                  link.sourceNoteId.equals(sourceNoteId) &
                  link.targetVaultItemId.isIn(toDelete),
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

  LinkedVaultItemCardDto _mapLinkedItem(
    TypedResult row,
    Map<String, List<TagInCardDto>> tagsMap,
  ) {
    final item = row.readTable(vaultItems);
    final category = row.readTableOrNull(categories);

    return LinkedVaultItemCardDto(
      id: item.id,
      title: item.name,
      description: item.description,
      vaultItemType: item.type,
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
      tags: tagsMap[item.id] ?? const <TagInCardDto>[],
    );
  }
}
