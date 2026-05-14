import 'package:drift/drift.dart';

import '../main_store.dart';
import '../tables/file/file_items.dart';

part 'file_items_dao.g.dart';

@DriftAccessor(tables: [FileItems])
class FileItemsDao extends DatabaseAccessor<MainStore>
    with _$FileItemsDaoMixin {
  FileItemsDao(super.db);

  Future<void> insertFile(FileItemsCompanion companion) {
    return into(fileItems).insert(companion);
  }

  Future<int> updateFileByItemId(
    String itemId,
    FileItemsCompanion companion,
  ) {
    return (update(fileItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .write(companion);
  }

  Future<FileItemsData?> getFileByItemId(String itemId) {
    return (select(fileItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .getSingleOrNull();
  }

  Future<bool> existsFileByItemId(String itemId) async {
    final row = await (selectOnly(fileItems)
          ..addColumns([fileItems.itemId])
          ..where(fileItems.itemId.equals(itemId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteFileByItemId(String itemId) {
    return (delete(fileItems)..where((tbl) => tbl.itemId.equals(itemId))).go();
  }
}
