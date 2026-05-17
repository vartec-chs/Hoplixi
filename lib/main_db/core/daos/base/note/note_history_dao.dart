import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';

import '../../../main_store.dart';
import '../../../tables/note/note_history.dart';

part 'note_history_dao.g.dart';

@DriftAccessor(tables: [NoteHistory])
class NoteHistoryDao extends DatabaseAccessor<MainStore>
    with _$NoteHistoryDaoMixin {
  NoteHistoryDao(super.db);

  Future<void> insertNoteHistory(NoteHistoryCompanion companion) {
    return into(noteHistory).insert(companion);
  }

  Future<NoteHistoryData?> getNoteHistoryByHistoryId(String historyId) {
    return (select(
      noteHistory,
    )..where((tbl) => tbl.historyId.equals(historyId))).getSingleOrNull();
  }

  Future<bool> existsNoteHistoryByHistoryId(String historyId) async {
    final row =
        await (selectOnly(noteHistory)
              ..addColumns([noteHistory.historyId])
              ..where(noteHistory.historyId.equals(historyId)))
            .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteNoteHistoryByHistoryId(String historyId) {
    return (delete(
      noteHistory,
    )..where((tbl) => tbl.historyId.equals(historyId))).go();
  }

  // --- HISTORY CARD BATCH METHODS ---
  Future<List<NoteHistoryData>> getNoteHistoryByHistoryIds(
    List<String> historyIds,
  ) {
    if (historyIds.isEmpty) return Future.value(const []);
    return (select(
      noteHistory,
    )..where((tbl) => tbl.historyId.isIn(historyIds))).get();
  }

  Future<Map<String, NoteHistoryCardDataDto>>
  getNoteHistoryCardDataByHistoryIds(List<String> historyIds) async {
    if (historyIds.isEmpty) return const {};

    final query = selectOnly(noteHistory)
      ..addColumns([
        noteHistory.historyId,
        noteHistory.deltaJson,
        noteHistory.content,
      ])
      ..where(noteHistory.historyId.isIn(historyIds));

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read(noteHistory.historyId)!: NoteHistoryCardDataDto(
          deltaJson: row.read(noteHistory.deltaJson),
          content: row.read(noteHistory.content),
        ),
    };
  }
}
