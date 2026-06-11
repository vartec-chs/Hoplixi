import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/vault_db/core/models/item_links_graph/item_links_graph_models.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/system/item_link/item_links.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

void main() {
  late VaultDB db;

  setUp(() {
    db = VaultDB(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('ItemLinksGraphDao', () {
    test('empty database returns no records', () async {
      final records = await db.itemLinksGraphDao.loadAllGraphRecords();

      expect(records, isEmpty);
    });

    test('one link returns two node records and one edge record', () async {
      await _insertItem(db, id: 'password-1', type: VaultItemType.password);
      await _insertItem(db, id: 'otp-1', type: VaultItemType.otp);
      await _insertItem(db, id: 'note-1', type: VaultItemType.note);
      await _insertLink(
        db,
        id: 'edge-1',
        sourceItemId: 'password-1',
        targetItemId: 'otp-1',
        relationType: ItemLinkType.otpForPassword,
      );

      final records = await db.itemLinksGraphDao.loadAllGraphRecords();
      final nodes = records
          .where((record) => record.kind == ItemGraphSqlRecordKind.node)
          .toList();
      final edges = records
          .where((record) => record.kind == ItemGraphSqlRecordKind.edge)
          .toList();

      expect(nodes.map((node) => node.nodeId), ['otp-1', 'password-1']);
      expect(edges, hasLength(1));
      expect(edges.single.edgeId, 'edge-1');
      expect(edges.single.sourceItemId, 'password-1');
      expect(edges.single.targetItemId, 'otp-1');
      expect(edges.single.relationType, ItemLinkType.otpForPassword);
    });

    test('filters links by bound relation types in SQL', () async {
      await _insertItem(db, id: 'password-1', type: VaultItemType.password);
      await _insertItem(db, id: 'otp-1', type: VaultItemType.otp);
      await _insertItem(db, id: 'note-1', type: VaultItemType.note);
      await _insertLink(
        db,
        id: 'edge-otp',
        sourceItemId: 'password-1',
        targetItemId: 'otp-1',
        relationType: ItemLinkType.otpForPassword,
      );
      await _insertLink(
        db,
        id: 'edge-note',
        sourceItemId: 'password-1',
        targetItemId: 'note-1',
        relationType: ItemLinkType.note,
      );

      final records = await db.itemLinksGraphDao
          .loadGraphRecordsByRelationTypes({ItemLinkType.note});
      final edges = records
          .where((record) => record.kind == ItemGraphSqlRecordKind.edge)
          .toList();

      expect(edges, hasLength(1));
      expect(edges.single.edgeId, 'edge-note');
      expect(records.where((record) => record.nodeId == 'otp-1'), isEmpty);
    });
  });
}

Future<void> _insertItem(
  VaultDB db, {
  required String id,
  required VaultItemType type,
}) {
  final now = DateTime(2026);
  return db
      .into(db.vaultItems)
      .insert(
        VaultItemsCompanion.insert(
          id: Value(id),
          type: type,
          name: '$id title',
          createdAt: Value(now),
          modifiedAt: Value(now),
        ),
      );
}

Future<void> _insertLink(
  VaultDB db, {
  required String id,
  required String sourceItemId,
  required String targetItemId,
  required ItemLinkType relationType,
}) {
  final now = DateTime(2026);
  return db
      .into(db.itemLinks)
      .insert(
        ItemLinksCompanion.insert(
          id: Value(id),
          sourceItemId: sourceItemId,
          targetItemId: targetItemId,
          relationType: relationType,
          createdAt: Value(now),
          modifiedAt: Value(now),
        ),
      );
}
