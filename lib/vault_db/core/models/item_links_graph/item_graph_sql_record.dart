import 'package:hoplixi/vault_db/core/scheme/tables/system/item_link/item_links.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart';

enum ItemGraphSqlRecordKind { node, edge }

final class ItemGraphSqlRecord {
  const ItemGraphSqlRecord({
    required this.kind,
    this.nodeId,
    this.nodeType,
    this.nodeTitle,
    this.nodeIconRefId,
    this.edgeId,
    this.sourceItemId,
    this.targetItemId,
    this.relationType,
    this.relationTypeOther,
    this.label,
    this.sortOrder,
  });

  final ItemGraphSqlRecordKind kind;

  final String? nodeId;
  final VaultItemType? nodeType;
  final String? nodeTitle;
  final String? nodeIconRefId;

  final String? edgeId;
  final String? sourceItemId;
  final String? targetItemId;
  final ItemLinkType? relationType;
  final String? relationTypeOther;
  final String? label;
  final int? sortOrder;
}
