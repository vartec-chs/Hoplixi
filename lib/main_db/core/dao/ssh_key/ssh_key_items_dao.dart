import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../tables/ssh_key/ssh_key_items.dart';

part 'ssh_key_items_dao.g.dart';

@DriftAccessor(tables: [SshKeyItems])
class SshKeyItemsDao extends DatabaseAccessor<MainStore>
    with _$SshKeyItemsDaoMixin {
  SshKeyItemsDao(super.db);

  Future<void> insertSshKey(SshKeyItemsCompanion companion) {
    return into(sshKeyItems).insert(companion);
  }

  Future<int> updateSshKeyByItemId(
    String itemId,
    SshKeyItemsCompanion companion,
  ) {
    return (update(sshKeyItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .write(companion);
  }

  Future<SshKeyItemsData?> getSshKeyByItemId(String itemId) {
    return (select(sshKeyItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .getSingleOrNull();
  }

  Future<bool> existsSshKeyByItemId(String itemId) async {
    final row = await (selectOnly(sshKeyItems)
          ..addColumns([sshKeyItems.itemId])
          ..where(sshKeyItems.itemId.equals(itemId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteSshKeyByItemId(String itemId) {
    return (delete(sshKeyItems)..where((tbl) => tbl.itemId.equals(itemId))).go();
  }
}
