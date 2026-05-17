import 'package:drift/drift.dart';
import '../../../main_store.dart';
import '../../../tables/document/document_items.dart';

part 'document_items_dao.g.dart';

@DriftAccessor(tables: [DocumentItems])
class DocumentItemsDao extends DatabaseAccessor<MainStore>
    with _$DocumentItemsDaoMixin {
  DocumentItemsDao(super.db);

  Future<DocumentItemsData?> getDocumentItemByItemId(String itemId) {
    return (select(
      documentItems,
    )..where((t) => t.itemId.equals(itemId))).getSingleOrNull();
  }

  Future<void> upsertDocumentItem({
    required String itemId,
    String? currentVersionId,
  }) async {
    await into(documentItems).insertOnConflictUpdate(
      DocumentItemsCompanion.insert(
        itemId: itemId,
        currentVersionId: Value(currentVersionId),
      ),
    );
  }

  Future<int> updateCurrentVersion({
    required String documentId,
    required String? versionId,
  }) {
    return (update(documentItems)..where((t) => t.itemId.equals(documentId))).write(
      DocumentItemsCompanion(currentVersionId: Value(versionId)),
    );
  }
}
