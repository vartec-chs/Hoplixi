import 'package:drift/drift.dart';
import '../../../main_store.dart';
import '../../../tables/document/document_items.dart';

part 'document_items_dao.g.dart';

@DriftAccessor(tables: [DocumentItems])
class DocumentItemsDao extends DatabaseAccessor<MainStore>
    with _$DocumentItemsDaoMixin {
  DocumentItemsDao(super.db);

  Future<void> insertDocumentItem(DocumentItemsCompanion companion) {
    return into(documentItems).insert(companion);
  }

  Future<int> updateDocumentItemByItemId(
    String itemId,
    DocumentItemsCompanion companion,
  ) {
    return (update(documentItems)..where((t) => t.itemId.equals(itemId)))
        .write(companion);
  }

  Future<DocumentItemsData?> getDocumentItemByItemId(String itemId) {
    return (select(documentItems)..where((t) => t.itemId.equals(itemId)))
        .getSingleOrNull();
  }

  Future<bool> existsDocumentItemByItemId(String itemId) async {
    final query = selectOnly(documentItems)
      ..where(documentItems.itemId.equals(itemId));
    final result = await query.get();
    return result.isNotEmpty;
  }

  Future<int> setCurrentVersionId({
    required String itemId,
    required String? currentVersionId,
  }) {
    return (update(documentItems)..where((t) => t.itemId.equals(itemId)))
        .write(DocumentItemsCompanion(
      currentVersionId: Value(currentVersionId),
    ));
  }

  Future<int> deleteDocumentItemByItemId(String itemId) {
    return (delete(documentItems)..where((t) => t.itemId.equals(itemId))).go();
  }
}
