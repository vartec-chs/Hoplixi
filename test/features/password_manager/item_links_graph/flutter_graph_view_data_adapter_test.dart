import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/features/password_manager/item_links_graph/flutter_graph_view_data_adapter.dart';
import 'package:hoplixi/vault_db/core/models/item_links_graph/item_links_graph_models.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/system/item_link/item_links.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart';

void main() {
  test('converts graph to flutter_graph_view MapConvertor data', () {
    const graph = ItemLinksGraph(
      nodes: [
        ItemLinksGraphNode(
          id: 'password-1',
          type: VaultItemType.password,
          title: 'Email',
          iconRefId: 'icon-1',
        ),
        ItemLinksGraphNode(
          id: 'otp-1',
          type: VaultItemType.otp,
          title: 'Email OTP',
        ),
      ],
      edges: [
        ItemLinksGraphEdge(
          id: 'edge-1',
          sourceItemId: 'password-1',
          targetItemId: 'otp-1',
          relationType: ItemLinkType.otpForPassword,
          displayLabel: '2FA',
          sortOrder: 3,
        ),
      ],
    );

    final result = const FlutterGraphViewDataAdapter().convert(graph);

    expect(result.data['vertexes'], hasLength(2));
    expect(result.data['edges'], hasLength(1));

    final firstVertex = result.data['vertexes']!.first;
    expect(firstVertex['id'], 'password-1');
    expect(firstVertex['tag'], VaultItemType.password.name);
    expect(firstVertex['data'], {
      'title': 'Email',
      'type': VaultItemType.password.name,
      'iconRefId': 'icon-1',
    });

    final edge = result.data['edges']!.single;
    expect(edge['srcId'], 'password-1');
    expect(edge['dstId'], 'otp-1');
    expect(edge['edgeName'], 'edge-1');
    expect(edge['ranking'], 3);
    expect(result.edgeLabelsById['edge-1'], '2FA');
  });
}
