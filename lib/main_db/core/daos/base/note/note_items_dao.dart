import 'package:drift/drift.dart';

import '../../../main_store.dart';
import '../../../tables/note/note_items.dart';

part 'note_items_dao.g.dart';

@DriftAccessor(tables: [NoteItems])
class NoteItemsDao extends DatabaseAccessor<MainStore> with _$NoteItemsDaoMixin {
  NoteItemsDao(super.db);

  Future<void> insertNote(NoteItemsCompanion companion) {
    return into(noteItems).insert(companion);
  }

  Future<int> updateNoteByItemId(
    String itemId,
    NoteItemsCompanion companion,
  ) {
    return (update(noteItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .write(companion);
  }

  Future<NoteItemsData?> getNoteByItemId(String itemId) {
    return (select(noteItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .getSingleOrNull();
  }

  Future<bool> existsNoteByItemId(String itemId) async {
    final row = await (selectOnly(noteItems)
          ..addColumns([noteItems.itemId])
          ..where(noteItems.itemId.equals(itemId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteNoteByItemId(String itemId) {
    return (delete(noteItems)..where((tbl) => tbl.itemId.equals(itemId))).go();
  }

  Future<void> upsertNoteItem(NoteItemsCompanion companion) {
    return into(noteItems).insertOnConflictUpdate(companion);
  }
}
