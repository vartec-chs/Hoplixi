import 'item_links_graph_edge.dart';
import 'item_links_graph_node.dart';

final class ItemLinksGraph {
  const ItemLinksGraph({required this.nodes, required this.edges});

  final List<ItemLinksGraphNode> nodes;
  final List<ItemLinksGraphEdge> edges;

  bool get isEmpty => nodes.isEmpty && edges.isEmpty;
}
