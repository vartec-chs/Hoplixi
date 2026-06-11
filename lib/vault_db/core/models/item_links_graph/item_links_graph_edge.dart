import 'package:hoplixi/vault_db/core/scheme/tables/system/item_link/item_links.dart';

final class ItemLinksGraphEdge {
  const ItemLinksGraphEdge({
    required this.id,
    required this.sourceItemId,
    required this.targetItemId,
    required this.relationType,
    required this.displayLabel,
    required this.sortOrder,
    this.relationTypeOther,
    this.label,
  });

  final String id;
  final String sourceItemId;
  final String targetItemId;
  final ItemLinkType relationType;
  final String? relationTypeOther;
  final String? label;
  final String displayLabel;
  final int sortOrder;
}
