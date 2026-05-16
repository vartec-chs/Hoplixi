import 'package:drift/drift.dart';

import '../../../main_store.dart';
import '../../../tables/recovery_codes/recovery_codes_items.dart';

part 'recovery_codes_items_dao.g.dart';

@DriftAccessor(tables: [RecoveryCodesItems])
class RecoveryCodesItemsDao extends DatabaseAccessor<MainStore>
    with _$RecoveryCodesItemsDaoMixin {
  RecoveryCodesItemsDao(super.db);

  Future<void> insertRecoveryCodesItem(
    RecoveryCodesItemsCompanion companion,
  ) {
    return into(recoveryCodesItems).insert(companion);
  }

  Future<int> updateRecoveryCodesItemByItemId(
    String itemId,
    RecoveryCodesItemsCompanion companion,
  ) {
    return (update(recoveryCodesItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .write(companion);
  }

  Future<RecoveryCodesItemsData?> getRecoveryCodesItemByItemId(
    String itemId,
  ) {
    return (select(recoveryCodesItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .getSingleOrNull();
  }

  Future<bool> existsRecoveryCodesItemByItemId(String itemId) async {
    final row = await (selectOnly(recoveryCodesItems)
          ..addColumns([recoveryCodesItems.itemId])
          ..where(recoveryCodesItems.itemId.equals(itemId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteRecoveryCodesItemByItemId(String itemId) {
    return (delete(recoveryCodesItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .go();
  }
}
