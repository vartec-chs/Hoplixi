import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../tables/contact/contact_items.dart';

part 'contact_items_dao.g.dart';

@DriftAccessor(tables: [ContactItems])
class ContactItemsDao extends DatabaseAccessor<MainStore>
    with _$ContactItemsDaoMixin {
  ContactItemsDao(super.db);

  Future<void> insertContact(ContactItemsCompanion companion) {
    return into(contactItems).insert(companion);
  }

  Future<int> updateContactByItemId(
    String itemId,
    ContactItemsCompanion companion,
  ) {
    return (update(contactItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .write(companion);
  }

  Future<ContactItemsData?> getContactByItemId(String itemId) {
    return (select(contactItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .getSingleOrNull();
  }

  Future<bool> existsContactByItemId(String itemId) async {
    final row = await (selectOnly(contactItems)
          ..addColumns([contactItems.itemId])
          ..where(contactItems.itemId.equals(itemId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteContactByItemId(String itemId) {
    return (delete(contactItems)..where((tbl) => tbl.itemId.equals(itemId))).go();
  }
}
