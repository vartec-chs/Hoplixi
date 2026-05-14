import 'package:drift/drift.dart';

import '../main_store.dart';
import '../tables/document/document_items.dart';

part 'document_items_dao.g.dart';

@DriftAccessor(tables: [DocumentItems])
class DocumentItemsDao extends DatabaseAccessor<MainStore>
    with _$DocumentItemsDaoMixin {
  DocumentItemsDao(super.db);

  Future<void> insertDocument(DocumentItemsCompanion companion) {
    return into(documentItems).insert(companion);
  }

  Future<int> updateDocumentByItemId(
    String itemId,
    DocumentItemsCompanion companion,
  ) {
    return (update(documentItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .write(companion);
  }

  Future<DocumentItemsData?> getDocumentByItemId(String itemId) {
    return (select(documentItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .getSingleOrNull();
  }

  Future<bool> existsDocumentByItemId(String itemId) async {
    final row = await (selectOnly(documentItems)
          ..addColumns([documentItems.itemId])
          ..where(documentItems.itemId.equals(itemId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteDocumentByItemId(String itemId) {
    return (delete(documentItems)..where((tbl) => tbl.itemId.equals(itemId))).go();
  }
}
