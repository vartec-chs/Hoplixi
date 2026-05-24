import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

import '../../../scheme/tables/system/icons/custom_icons.dart';

part 'custom_icons_dao.g.dart';

@DriftAccessor(tables: [CustomIcons])
class CustomIconsDao extends DatabaseAccessor<VaultDB>
    with _$CustomIconsDaoMixin {
  CustomIconsDao(super.db);

  Future<int> insertCustomIcon(CustomIconsCompanion companion) {
    return into(customIcons).insert(companion);
  }

  Future<int> updateCustomIconById(String id, CustomIconsCompanion companion) {
    return (update(
      customIcons,
    )..where((t) => t.id.equals(id))).write(companion);
  }

  Future<CustomIconsData?> getCustomIconById(String id) {
    return (select(
      customIcons,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<CustomIconsData>> getAllCustomIcons() {
    return select(customIcons).get();
  }

  Future<int> deleteCustomIconById(String id) {
    return (delete(customIcons)..where((t) => t.id.equals(id))).go();
  }

  Future<bool> existsCustomIcon(String id) async {
    final query = selectOnly(customIcons)
      ..addColumns([customIcons.id])
      ..where(customIcons.id.equals(id));
    final result = await query.get();
    return result.isNotEmpty;
  }
}
