import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/vault_db/core/errors/db_error.dart';
import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/models/item_links_graph/item_links_graph_models.dart';
import 'package:hoplixi/vault_db/core/repositories/base/system/item_links_graph_repository.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/system/item_link/item_links.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart';
import 'package:hoplixi/vault_db/core/services/relations/load_item_links_graph_service.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  group('LoadItemLinksGraphService', () {
    test('returns filter-required without calling repository', () async {
      final repository = _FakeItemLinksGraphRepository();
      final service = LoadItemLinksGraphService(repository: repository);

      final result = await service(const RelationTypesItemLinksGraphMode({}));

      expect(result.getOrThrow(), isA<ItemLinksGraphFilterRequired>());
      expect(repository.calls, 0);
    });

    test('maps node and edge records to graph preserving direction', () async {
      final repository = _FakeItemLinksGraphRepository(
        records: [
          const ItemGraphSqlRecord(
            kind: ItemGraphSqlRecordKind.node,
            nodeId: 'password-1',
            nodeType: VaultItemType.password,
            nodeTitle: 'Email',
          ),
          const ItemGraphSqlRecord(
            kind: ItemGraphSqlRecordKind.node,
            nodeId: 'otp-1',
            nodeType: VaultItemType.otp,
            nodeTitle: 'Email OTP',
          ),
          const ItemGraphSqlRecord(
            kind: ItemGraphSqlRecordKind.edge,
            edgeId: 'edge-1',
            sourceItemId: 'password-1',
            targetItemId: 'otp-1',
            relationType: ItemLinkType.otpForPassword,
            label: '2FA',
            sortOrder: 7,
          ),
        ],
      );
      final service = LoadItemLinksGraphService(repository: repository);

      final result = await service(const AllItemLinksGraphMode());
      final loaded = result.getOrThrow() as ItemLinksGraphLoaded;

      expect(loaded.graph.nodes, hasLength(2));
      expect(loaded.graph.edges, hasLength(1));
      expect(loaded.graph.edges.single.sourceItemId, 'password-1');
      expect(loaded.graph.edges.single.targetItemId, 'otp-1');
      expect(loaded.graph.edges.single.displayLabel, '2FA');
      expect(loaded.graph.edges.single.sortOrder, 7);
      expect(repository.calls, 1);
    });

    test('uses relationTypeOther as display label for other links', () async {
      final repository = _FakeItemLinksGraphRepository(
        records: [
          const ItemGraphSqlRecord(
            kind: ItemGraphSqlRecordKind.node,
            nodeId: 'a',
            nodeType: VaultItemType.note,
            nodeTitle: 'A',
          ),
          const ItemGraphSqlRecord(
            kind: ItemGraphSqlRecordKind.node,
            nodeId: 'b',
            nodeType: VaultItemType.file,
            nodeTitle: 'B',
          ),
          const ItemGraphSqlRecord(
            kind: ItemGraphSqlRecordKind.edge,
            edgeId: 'edge-other',
            sourceItemId: 'a',
            targetItemId: 'b',
            relationType: ItemLinkType.other,
            relationTypeOther: 'Custom relation',
          ),
        ],
      );
      final service = LoadItemLinksGraphService(repository: repository);

      final result = await service(
        const RelationTypesItemLinksGraphMode({ItemLinkType.other}),
      );
      final loaded = result.getOrThrow() as ItemLinksGraphLoaded;

      expect(loaded.graph.edges.single.displayLabel, 'Custom relation');
    });

    test(
      'returns failure when an edge references a missing source node',
      () async {
        final repository = _FakeItemLinksGraphRepository(
          records: [
            const ItemGraphSqlRecord(
              kind: ItemGraphSqlRecordKind.node,
              nodeId: 'target',
              nodeType: VaultItemType.note,
              nodeTitle: 'Target',
            ),
            const ItemGraphSqlRecord(
              kind: ItemGraphSqlRecordKind.edge,
              edgeId: 'edge-1',
              sourceItemId: 'missing',
              targetItemId: 'target',
              relationType: ItemLinkType.related,
            ),
          ],
        );
        final service = LoadItemLinksGraphService(repository: repository);

        final result = await service(const AllItemLinksGraphMode());

        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), isA<DbValidationError>());
      },
    );
  });
}

final class _FakeItemLinksGraphRepository implements ItemLinksGraphRepository {
  _FakeItemLinksGraphRepository({this.records = const []});

  final List<ItemGraphSqlRecord> records;
  int calls = 0;

  @override
  AsyncDBResult<List<ItemGraphSqlRecord>> loadGraphRecords(
    ItemLinksGraphMode mode,
  ) async {
    calls++;
    return Success(records);
  }
}
