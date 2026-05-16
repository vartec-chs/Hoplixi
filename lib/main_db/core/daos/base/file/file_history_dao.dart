import 'package:drift/drift.dart';

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
}
