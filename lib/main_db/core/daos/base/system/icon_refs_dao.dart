import 'package:drift/drift.dart';
import '../../../main_store.dart';
import '../../../tables/system/icons/icon_refs.dart';

part 'icon_refs_dao.g.dart';

@DriftAccessor(tables: [IconRefs])
class IconRefsDao extends DatabaseAccessor<MainStore> with _$IconRefsDaoMixin {
  IconRefsDao(super.db);

  Future<int> insertIconRef(IconRefsCompanion companion) {
    return into(iconRefs).insert(companion);
  }

  Future<int> updateIconRefById(String id, IconRefsCompanion companion) {
    return (update(iconRefs)..where((t) => t.id.equals(id))).write(companion);
  }

  Future<IconRefsData?> getIconRefById(String id) {
    return (select(iconRefs)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<IconRefsData>> getAllIconRefs() {
    return select(iconRefs).get();
  }

  Future<int> deleteIconRefById(String id) {
    return (delete(iconRefs)..where((t) => t.id.equals(id))).go();
  }

  Future<bool> existsIconRef(String id) async {
    final query = selectOnly(iconRefs)
      ..addColumns([iconRefs.id])
      ..where(iconRefs.id.equals(id));
    final result = await query.get();
    return result.isNotEmpty;
  }

  Future<List<IconRefsData>> getIconRefsByCustomIconId(String customIconId) {
    return (select(iconRefs)..where((t) => t.customIconId.equals(customIconId)))
        .get();
  }

  Future<List<IconRefsData>> getIconRefsByType(IconSourceType type) {
    return (select(iconRefs)..where((t) => t.iconSourceType.equals(type.name)))
        .get();
  }
}
