import 'package:drift/drift.dart';
import '../../../models/dto_history/cards/file_history_card_dto.dart';

import '../../../main_store.dart';
import '../../../tables/file/file_history.dart';


part 'file_history_dao.g.dart';

@DriftAccessor(tables: [FileHistory])
class FileHistoryDao extends DatabaseAccessor<MainStore>
    with _$FileHistoryDaoMixin {
  FileHistoryDao(super.db);

  Future<void> insertFileHistory(FileHistoryCompanion companion) {
    return into(fileHistory).insert(companion);
  }

  Future<FileHistoryData?> getFileHistoryByHistoryId(String historyId) {
    return (select(fileHistory)..where((tbl) => tbl.historyId.equals(historyId)))
        .getSingleOrNull();
  }

  Future<bool> existsFileHistoryByHistoryId(String historyId) async {
    final row = await (selectOnly(fileHistory)
          ..addColumns([fileHistory.historyId])
          ..where(fileHistory.historyId.equals(historyId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteFileHistoryByHistoryId(String historyId) {
    return (delete(fileHistory)..where((tbl) => tbl.historyId.equals(historyId)))
        .go();
  }

  // --- HISTORY CARD BATCH METHODS ---
  Future<List<FileHistoryData>> getFileHistoryByHistoryIds(
    List<String> historyIds,
  ) {
    if (historyIds.isEmpty) return Future.value(const []);
    return (select(fileHistory)..where((tbl) => tbl.historyId.isIn(historyIds)))
        .get();
  }

  Future<Map<String, FileHistoryCardDataDto>> getFileHistoryCardDataByHistoryIds(
    List<String> historyIds,
  ) async {
    if (historyIds.isEmpty) return const {};

    final query = selectOnly(fileHistory)
      ..addColumns([fileHistory.historyId, fileHistory.metadataHistoryId])
      ..where(fileHistory.historyId.isIn(historyIds));

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read(fileHistory.historyId)!: FileHistoryCardDataDto(
          metadataHistoryId: row.read(fileHistory.metadataHistoryId),
          // Other fields are loaded from metadata history if needed, 
          // but for the card we only need metadataId/metadataHistoryId usually.
          // Wait, FileHistoryCardDataDto should probably have more fields.
        ),
    };
  }
}
