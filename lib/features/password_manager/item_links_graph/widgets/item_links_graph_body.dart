import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/item_links_graph/widgets/graph_message.dart';
import 'package:hoplixi/features/password_manager/item_links_graph/widgets/item_links_graph_legend.dart';
import 'package:hoplixi/features/password_manager/item_links_graph/widgets/item_links_graph_view.dart';
import 'package:hoplixi/vault_db/core/models/item_links_graph/item_links_graph_models.dart';

class ItemLinksGraphBody extends StatelessWidget {
  const ItemLinksGraphBody({
    super.key,
    required this.graph,
    required this.theme,
  });

  final ItemLinksGraph graph;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (graph.isEmpty) {
      return const GraphMessage(
        icon: Icons.hub_outlined,
        title: 'Связей пока нет',
        subtitle: 'Граф показывает только элементы, участвующие в связях.',
      );
    }

    final relationTypes = graph.edges.map((edge) => edge.relationType).toSet();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(
            children: [
              Text(
                'Узлы: ${graph.nodes.length}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(width: 12),
              Text(
                'Связи: ${graph.edges.length}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        ItemLinksGraphLegend(relationTypes: relationTypes),
        const Divider(height: 1),
        Expanded(
          child: RepaintBoundary(
            child: ItemLinksGraphView(
              key: ValueKey('graph_${graph.nodes.length}_${graph.edges.length}'),
              graph: graph,
              theme: theme,
            ),
          ),
        ),
      ],
    );
  }
}
