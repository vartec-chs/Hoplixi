import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../tables/note/note_history.dart';

part 'note_history_dao.g.dart';

@DriftAccessor(tables: [NoteHistory])
class NoteHistoryDao extends DatabaseAccessor<MainStore>
    with _$NoteHistoryDaoMixin {
  NoteHistoryDao(super.db);

  Future<void> insertNoteHistory(NoteHistoryCompanion companion) {
    return into(noteHistory).insert(companion);
  }

  Future<NoteHistoryData?> getNoteHistoryByHistoryId(String historyId) {
    return (select(noteHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .getSingleOrNull();
  }

  Future<bool> existsNoteHistoryByHistoryId(String historyId) async {
    final row = await (selectOnly(noteHistory)
          ..addColumns([noteHistory.historyId])
          ..where(noteHistory.historyId.equals(historyId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteNoteHistoryByHistoryId(String historyId) {
    return (delete(noteHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .go();
  }
}
