import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/models/item_links_graph/item_graph_sql_record.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/system/item_link/item_links.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

part 'item_links_graph_dao.g.dart';

@DriftAccessor(tables: [VaultItems, ItemLinks])
class ItemLinksGraphDao extends DatabaseAccessor<VaultDB>
    with _$ItemLinksGraphDaoMixin {
  ItemLinksGraphDao(super.db);

  Future<List<ItemGraphSqlRecord>> loadAllGraphRecords() {
    return customSelect(
      _graphSql(),
      readsFrom: {vaultItems, itemLinks},
    ).map(_mapGraphRecord).get();
  }

  Future<List<ItemGraphSqlRecord>> loadGraphRecordsByRelationTypes(
    Set<ItemLinkType> relationTypes,
  ) {
    if (relationTypes.isEmpty) {
      throw ArgumentError.value(
        relationTypes,
        'relationTypes',
        'Must not be empty',
      );
    }

    final placeholders = List.filled(relationTypes.length, '?').join(', ');
    return customSelect(
      _graphSql(filteredLinksWhere: 'WHERE relation_type IN ($placeholders)'),
      variables: relationTypes
          .map((type) => Variable.withString(type.name))
          .toList(growable: false),
      readsFrom: {vaultItems, itemLinks},
    ).map(_mapGraphRecord).get();
  }

  ItemGraphSqlRecord _mapGraphRecord(QueryRow row) {
    final kind = switch (row.read<String>('record_kind')) {
      'node' => ItemGraphSqlRecordKind.node,
      'edge' => ItemGraphSqlRecordKind.edge,
      final value => throw StateError('Unknown graph record kind: $value'),
    };

    return ItemGraphSqlRecord(
      kind: kind,
      nodeId: row.readNullable<String>('node_id'),
      nodeType: _enumByNameOrNull(
        VaultItemType.values,
        row.readNullable<String>('node_type'),
      ),
      nodeTitle: row.readNullable<String>('node_title'),
      nodeIconRefId: row.readNullable<String>('node_icon_ref_id'),
      edgeId: row.readNullable<String>('edge_id'),
      sourceItemId: row.readNullable<String>('source_item_id'),
      targetItemId: row.readNullable<String>('target_item_id'),
      relationType: _enumByNameOrNull(
        ItemLinkType.values,
        row.readNullable<String>('relation_type'),
      ),
      relationTypeOther: row.readNullable<String>('relation_type_other'),
      label: row.readNullable<String>('edge_label'),
      sortOrder: row.readNullable<int>('sort_order'),
    );
  }

  T? _enumByNameOrNull<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw StateError('Unknown enum value: $name');
  }

  String _graphSql({String filteredLinksWhere = ''}) {
    return '''
WITH filtered_links AS (
  SELECT
    id,
    source_item_id,
    target_item_id,
    relation_type,
    relation_type_other,
    label,
    sort_order
  FROM item_links
  $filteredLinksWhere
),
linked_item_ids AS (
  SELECT source_item_id AS item_id
  FROM filtered_links

  UNION

  SELECT target_item_id AS item_id
  FROM filtered_links
)
SELECT
  0 AS record_order,
  'node' AS record_kind,
  vault_items.id AS node_id,
  vault_items.type AS node_type,
  vault_items.name AS node_title,
  vault_items.icon_ref_id AS node_icon_ref_id,
  NULL AS edge_id,
  NULL AS source_item_id,
  NULL AS target_item_id,
  NULL AS relation_type,
  NULL AS relation_type_other,
  NULL AS edge_label,
  NULL AS sort_order
FROM vault_items
INNER JOIN linked_item_ids
  ON linked_item_ids.item_id = vault_items.id

UNION ALL

SELECT
  1 AS record_order,
  'edge' AS record_kind,
  NULL AS node_id,
  NULL AS node_type,
  NULL AS node_title,
  NULL AS node_icon_ref_id,
  filtered_links.id AS edge_id,
  filtered_links.source_item_id,
  filtered_links.target_item_id,
  filtered_links.relation_type,
  filtered_links.relation_type_other,
  filtered_links.label AS edge_label,
  filtered_links.sort_order
FROM filtered_links

ORDER BY
  record_order,
  node_id,
  sort_order,
  edge_id
''';
  }
}
