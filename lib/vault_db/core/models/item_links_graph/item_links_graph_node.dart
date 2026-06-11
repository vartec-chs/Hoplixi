import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart';

final class ItemLinksGraphNode {
  const ItemLinksGraphNode({
    required this.id,
    required this.type,
    required this.title,
    this.iconRefId,
  });

  final String id;
  final VaultItemType type;
  final String title;
  final String? iconRefId;
}
