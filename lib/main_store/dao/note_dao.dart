import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/note_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/note_items.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';
import 'package:uuid/uuid.dart';

part 'note_dao.g.dart';

@DriftAccessor(tables: [VaultItems, NoteItems])
class NoteDao extends DatabaseAccessor<MainStore> with _$NoteDaoMixin {
  NoteDao(super.db);

  /// Получить все заметки (JOIN)
  Future<List<(VaultItemsData, NoteItemsData)>> getAllNotes() async {
    final query = select(
      vaultItems,
    ).join([innerJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.id))]);
    final rows = await query.get();
    return rows
        .map((row) => (row.readTable(vaultItems), row.readTable(noteItems)))
        .toList();
  }

  /// Получить заметку по ID
  Future<(VaultItemsData, NoteItemsData)?> getById(String id) async {
    final query = select(vaultItems).join([
      innerJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.id)),
    ])..where(vaultItems.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(noteItems));
  }

  /// Смотреть все заметки
  Stream<List<(VaultItemsData, NoteItemsData)>> watchAllNotes() {
    final query = select(vaultItems).join([
      innerJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.id)),
    ])..orderBy([OrderingTerm.desc(vaultItems.modifiedAt)]);
    return query.watch().map(
      (rows) => rows
          .map((row) => (row.readTable(vaultItems), row.readTable(noteItems)))
          .toList(),
    );
  }

  /// Создать новую заметку
  Future<String> createNote(CreateNoteDto dto) {
    final uuid = const Uuid().v4();
    return db.transaction(() async {
      await into(vaultItems).insert(
        VaultItemsCompanion.insert(
          id: Value(uuid),
          type: VaultItemType.note,
          name: dto.title,
          description: Value(dto.description),
          categoryId: Value(dto.categoryId),
        ),
      );
      await into(noteItems).insert(
        NoteItemsCompanion.insert(
          itemId: uuid,
          deltaJson: dto.deltaJson,
          content: dto.content,
        ),
      );
      await db.vaultItemDao.insertTags(uuid, dto.tagsIds);
      // Синхронизация ссылок между заметками
      await db.noteLinkDao.syncLinksFromContent(uuid, dto.deltaJson);
      return uuid;
    });
  }

  /// Обновить заметку
  Future<bool> updateNote(String id, UpdateNoteDto dto) {
    return db.transaction(() async {
      // vault_items
      final vaultCompanion = VaultItemsCompanion(
        name: dto.title != null ? Value(dto.title!) : const Value.absent(),
        description: Value(dto.description),
        categoryId: Value(dto.categoryId),
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

      // note_items
      final noteCompanion = NoteItemsCompanion(
        content: dto.content != null
            ? Value(dto.content!)
            : const Value.absent(),
        deltaJson: dto.deltaJson != null
            ? Value(dto.deltaJson!)
            : const Value.absent(),
      );
      await (update(
        noteItems,
      )..where((n) => n.itemId.equals(id))).write(noteCompanion);

      if (dto.tagsIds != null) {
        await db.vaultItemDao.syncTags(id, dto.tagsIds!);
      }
      if (dto.deltaJson != null) {
        await db.noteLinkDao.syncLinksFromContent(id, dto.deltaJson!);
      }
      return true;
    });
  }

  /// Полное удаление (с удалением связей)
  Future<bool> permanentDelete(String id) {
    return db.transaction(() async {
      await db.noteLinkDao.deleteAllLinksForNote(id);
      return db.vaultItemDao.permanentDelete(id);
    });
  }
}
