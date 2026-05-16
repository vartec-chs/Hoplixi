import 'package:drift/drift.dart';
import '../../../main_store.dart';
import '../../../tables/system/store/store_meta_table.dart';

part 'store_meta_dao.g.dart';

@DriftAccessor(tables: [StoreMetaTable])
class StoreMetaDao extends DatabaseAccessor<MainStore> with _$StoreMetaDaoMixin {
  StoreMetaDao(super.db);

  Future<StoreMetaData?> getStoreMeta() {
    return select(storeMetaTable).getSingleOrNull();
  }

  Future<void> insertStoreMeta(StoreMetaTableCompanion companion) {
    return into(storeMetaTable).insert(companion);
  }

  Future<int> updateStoreMeta(StoreMetaTableCompanion companion) {
    return update(storeMetaTable).write(companion);
  }

  Future<bool> hasStoreMeta() async {
    final result = await selectOnly(storeMetaTable).get();
    return result.isNotEmpty;
  }
}
