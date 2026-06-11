import 'item_links_graph.dart';

sealed class ItemLinksGraphLoadResult {
  const ItemLinksGraphLoadResult();
}

final class ItemLinksGraphLoaded extends ItemLinksGraphLoadResult {
  const ItemLinksGraphLoaded(this.graph);

  final ItemLinksGraph graph;
}

final class ItemLinksGraphFilterRequired extends ItemLinksGraphLoadResult {
  const ItemLinksGraphFilterRequired();
}
