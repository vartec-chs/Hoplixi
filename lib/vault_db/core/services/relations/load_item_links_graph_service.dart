import 'package:result_dart/result_dart.dart';

import 'package:hoplixi/vault_db/core/errors/db_error.dart';
import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/models/item_links_graph/item_links_graph_models.dart';
import 'package:hoplixi/vault_db/core/repositories/base/system/item_links_graph_repository.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/system/item_link/item_links.dart';

final class LoadItemLinksGraphService {
  const LoadItemLinksGraphService({required this.repository});

  final ItemLinksGraphRepository repository;

  AsyncDBResult<ItemLinksGraphLoadResult> call(ItemLinksGraphMode mode) async {
    if (mode case RelationTypesItemLinksGraphMode(
      relationTypes: final relationTypes,
    ) when relationTypes.isEmpty) {
      return const Success(ItemLinksGraphFilterRequired());
    }

    final recordsResult = await repository.loadGraphRecords(mode);
    if (recordsResult.isError()) {
      return Failure(recordsResult.exceptionOrNull()!);
    }

    return tryCatch(
      () => ItemLinksGraphLoaded(_buildGraph(recordsResult.getOrThrow())),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при построении графа связей элементов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  ItemLinksGraph _buildGraph(List<ItemGraphSqlRecord> records) {
    final nodesById = <String, ItemLinksGraphNode>{};
    final edges = <ItemLinksGraphEdge>[];

    for (final record in records) {
      switch (record.kind) {
        case ItemGraphSqlRecordKind.node:
          final node = _mapNode(record);
          final existing = nodesById[node.id];
          if (existing != null) {
            if (existing.type != node.type ||
                existing.title != node.title ||
                existing.iconRefId != node.iconRefId) {
              throw DBCoreError.validation(
                code: 'item_links_graph.node_conflict',
                message: 'Conflicting node data for item graph',
                entity: 'vault_items',
                data: {'itemId': node.id},
              );
            }
            continue;
          }
          nodesById[node.id] = node;

        case ItemGraphSqlRecordKind.edge:
          edges.add(_mapEdge(record));
      }
    }

    for (final edge in edges) {
      if (!nodesById.containsKey(edge.sourceItemId)) {
        throw DBCoreError.validation(
          code: 'item_links_graph.missing_source_node',
          message: 'Graph edge references missing source node',
          entity: 'item_links',
          data: {'edgeId': edge.id, 'sourceItemId': edge.sourceItemId},
        );
      }
      if (!nodesById.containsKey(edge.targetItemId)) {
        throw DBCoreError.validation(
          code: 'item_links_graph.missing_target_node',
          message: 'Graph edge references missing target node',
          entity: 'item_links',
          data: {'edgeId': edge.id, 'targetItemId': edge.targetItemId},
        );
      }
    }

    return ItemLinksGraph(
      nodes: List.unmodifiable(nodesById.values),
      edges: List.unmodifiable(edges),
    );
  }

  ItemLinksGraphNode _mapNode(ItemGraphSqlRecord record) {
    final id = record.nodeId;
    final type = record.nodeType;
    final title = record.nodeTitle;
    if (id == null || type == null || title == null) {
      throw const DBCoreError.validation(
        code: 'item_links_graph.invalid_node_record',
        message: 'Invalid node record for item graph',
        entity: 'vault_items',
      );
    }

    return ItemLinksGraphNode(
      id: id,
      type: type,
      title: title,
      iconRefId: record.nodeIconRefId,
    );
  }

  ItemLinksGraphEdge _mapEdge(ItemGraphSqlRecord record) {
    final id = record.edgeId;
    final sourceItemId = record.sourceItemId;
    final targetItemId = record.targetItemId;
    final relationType = record.relationType;
    if (id == null ||
        sourceItemId == null ||
        targetItemId == null ||
        relationType == null) {
      throw const DBCoreError.validation(
        code: 'item_links_graph.invalid_edge_record',
        message: 'Invalid edge record for item graph',
        entity: 'item_links',
      );
    }

    return ItemLinksGraphEdge(
      id: id,
      sourceItemId: sourceItemId,
      targetItemId: targetItemId,
      relationType: relationType,
      relationTypeOther: record.relationTypeOther,
      label: record.label,
      displayLabel: _edgeDisplayLabel(
        relationType,
        relationTypeOther: record.relationTypeOther,
        label: record.label,
      ),
      sortOrder: record.sortOrder ?? 0,
    );
  }

  String _edgeDisplayLabel(
    ItemLinkType relationType, {
    required String? relationTypeOther,
    required String? label,
  }) {
    final trimmedLabel = label?.trim();
    if (trimmedLabel != null && trimmedLabel.isNotEmpty) {
      return trimmedLabel;
    }

    if (relationType == ItemLinkType.other) {
      final trimmedOther = relationTypeOther?.trim();
      if (trimmedOther != null && trimmedOther.isNotEmpty) {
        return trimmedOther;
      }
    }

    return relationType.name;
  }
}
