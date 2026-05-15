import 'package:drift/drift.dart';
import '../../main_store.dart';
import '../../tables/file/file_history.dart';

part 'file_history_dao.g.dart';

@DriftAccessor(tables: [FileHistory])
class FileHistoryDao extends DatabaseAccessor<MainStore>
    with _$FileHistoryDaoMixin {
  FileHistoryDao(super.db);

  Future<void> insertFileHistory(FileHistoryCompanion companion) {
    return into(fileHistory).insert(companion);
  }

  Future<FileHistoryData?> getFileHistoryByHistoryId(String historyId) {
    return (select(fileHistory)..where((t) => t.historyId.equals(historyId)))
        .getSingleOrNull();
  }

  Future<int> deleteFileHistoryByHistoryId(String historyId) {
    return (delete(fileHistory)..where((t) => t.historyId.equals(historyId)))
        .go();
  }
}
