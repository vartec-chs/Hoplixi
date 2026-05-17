import 'package:drift/drift.dart';
import '../../../main_store.dart';
import '../../../tables/file/file_items.dart';

part 'file_items_dao.g.dart';

@DriftAccessor(tables: [FileItems])
class FileItemsDao extends DatabaseAccessor<MainStore> with _$FileItemsDaoMixin {
  FileItemsDao(super.db);

  Future<void> insertFileItem(FileItemsCompanion companion) {
    return into(fileItems).insert(companion);
  }

  Future<int> updateFileItemByItemId(
    String itemId,
    FileItemsCompanion companion,
  ) {
    return (update(fileItems)..where((t) => t.itemId.equals(itemId)))
        .write(companion);
  }

  Future<FileItemsData?> getFileItemByItemId(String itemId) {
    return (select(fileItems)..where((t) => t.itemId.equals(itemId)))
        .getSingleOrNull();
  }

  Future<bool> existsFileItemByItemId(String itemId) async {
    final query = selectOnly(fileItems)
      ..where(fileItems.itemId.equals(itemId));
    final result = await query.get();
    return result.isNotEmpty;
  }

  Future<int> setMetadataId({
    required String itemId,
    required String? metadataId,
  }) {
    return (update(fileItems)..where((t) => t.itemId.equals(itemId))).write(
      FileItemsCompanion(
        metadataId: Value(metadataId),
      ),
    );
  }

  Future<int> deleteFileItemByItemId(String itemId) {
    return (delete(fileItems)..where((t) => t.itemId.equals(itemId))).go();
  }

  Future<void> upsertFileItem(FileItemsCompanion companion) {
    return into(fileItems).insertOnConflictUpdate(companion);
  }
}
