import 'package:hoplixi/vault_db/core/scheme/tables/system/item_link/item_links.dart';

sealed class ItemLinksGraphMode {
  const ItemLinksGraphMode();
}

final class AllItemLinksGraphMode extends ItemLinksGraphMode {
  const AllItemLinksGraphMode();
}

final class RelationTypesItemLinksGraphMode extends ItemLinksGraphMode {
  const RelationTypesItemLinksGraphMode(this.relationTypes);

  final Set<ItemLinkType> relationTypes;
}
