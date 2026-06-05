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

  Future<List<CustomIconsData>> getCustomIconsPage({
    String query = '',
    required int limit,
    required int offset,
  }) {
    final normalizedLimit = limit < 1 ? 1 : limit;
    final normalizedOffset = offset < 0 ? 0 : offset;
    final stmt = select(customIcons)
      ..where((_) => _buildSearchExpression(query))
      ..orderBy([
        (t) => OrderingTerm(
          expression: t.modifiedAt,
          mode: OrderingMode.desc,
        ),
        (t) => OrderingTerm(
          expression: t.name,
          mode: OrderingMode.asc,
        ),
      ])
      ..limit(normalizedLimit, offset: normalizedOffset);

    return stmt.get();
  }

  Future<int> countCustomIcons({String query = ''}) async {
    final countExp = countAll();
    final stmt = selectOnly(customIcons)
      ..addColumns([countExp])
      ..where(_buildSearchExpression(query));
    final row = await stmt.getSingle();
    return row.read(countExp) ?? 0;
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

  Expression<bool> _buildSearchExpression(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return const Constant(true);
    }

    final pattern = '%$trimmedQuery%';
    return customIcons.name.like(pattern) | customIcons.id.like(pattern);
  }
}
