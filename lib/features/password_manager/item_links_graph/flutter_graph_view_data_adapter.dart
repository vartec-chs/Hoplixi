import 'package:hoplixi/vault_db/core/models/item_links_graph/item_links_graph_models.dart';

final class FlutterGraphViewData {
  const FlutterGraphViewData({
    required this.data,
    required this.edgeLabelsById,
  });

  final Map<String, List<Map<String, Object?>>> data;
  final Map<String, String> edgeLabelsById;
}

final class FlutterGraphViewDataAdapter {
  const FlutterGraphViewDataAdapter();

  FlutterGraphViewData convert(ItemLinksGraph graph) {
    final edgeLabelsById = <String, String>{};

    return FlutterGraphViewData(
      data: {
        'vertexes': graph.nodes
            .map(
              (node) => {
                'id': node.id,
                'tag': node.type.name,
                'tags': [node.type.name],
                'data': {
                  'title': node.title,
                  'type': node.type.name,
                  'iconRefId': node.iconRefId,
                },
              },
            )
            .toList(growable: false),
        'edges': graph.edges
            .map((edge) {
              edgeLabelsById[edge.id] = edge.displayLabel;
              return {
                'srcId': edge.sourceItemId,
                'dstId': edge.targetItemId,
                'edgeName': edge.id,
                'ranking': edge.sortOrder,
              };
            })
            .toList(growable: false),
      },
      edgeLabelsById: Map.unmodifiable(edgeLabelsById),
    );
  }
}
