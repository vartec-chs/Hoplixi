import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../vault_items/vault_item_history.dart';
import 'item_links.dart';

/// History/snapshot-таблица для связей между vault items.
///
/// Хранит снимок item_links на момент создания записи vault_item_history.
/// FK на live VaultItems специально не используются:
/// source/target item могут быть удалены или изменены после создания истории.
@DataClassName('ItemLinkHistoryData')
class ItemLinkHistory extends Table {
  /// UUID snapshot-записи связи.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// FK → vault_item_history.id ON DELETE CASCADE.
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// ID исходной live-связи item_links на момент snapshot.
  ///
  /// Не FK: live-связь может быть удалена.
  TextColumn get sourceLinkId => text().nullable()();

  /// Snapshot source item id.
  ///
  /// Не FK: исходный item может быть удалён.
  TextColumn get sourceItemId => text()();

  /// Snapshot target item id.
  ///
  /// Не FK: целевой item может быть удалён.
  TextColumn get targetItemId => text()();

  /// Snapshot типа связи.
  TextColumn get relationType => textEnum<ItemLinkType>()();

  /// Snapshot пользовательского типа связи.
  TextColumn get relationTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Snapshot подписи связи.
  TextColumn get label => text().withLength(min: 1, max: 255).nullable()();

  /// Snapshot порядка.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Snapshot даты создания исходной связи.
  DateTimeColumn get createdAt => dateTime()();

  /// Snapshot даты изменения исходной связи.
  DateTimeColumn get modifiedAt => dateTime()();

  /// UUID снимка для группировки связанных записей.
  TextColumn get snapshotId => text().nullable()();

  /// Когда был создан snapshot.
  DateTimeColumn get snapshotCreatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'item_link_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${ItemLinkHistoryConstraint.noSelfLink.constraintName}
    CHECK (
      source_item_id != target_item_id
    )
    ''',

    '''
    CONSTRAINT ${ItemLinkHistoryConstraint.relationTypeOtherRequired.constraintName}
    CHECK (
      relation_type != 'other'
      OR (
        relation_type_other IS NOT NULL
        AND length(trim(relation_type_other)) > 0
      )
    )
    ''',

    '''
    CONSTRAINT ${ItemLinkHistoryConstraint.relationTypeOtherMustBeNull.constraintName}
    CHECK (
      relation_type = 'other'
      OR relation_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${ItemLinkHistoryConstraint.labelNotBlank.constraintName}
    CHECK (
      label IS NULL
      OR length(trim(label)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ItemLinkHistoryConstraint.sortOrderNonNegative.constraintName}
    CHECK (
      sort_order >= 0
    )
    ''',

    '''
    CONSTRAINT ${ItemLinkHistoryConstraint.createdModifiedRange.constraintName}
    CHECK (
      created_at <= modified_at
    )
    ''',
  ];
}

enum ItemLinkHistoryConstraint {
  noSelfLink('chk_item_link_history_no_self_link'),

  relationTypeOtherRequired(
    'chk_item_link_history_relation_type_other_required',
  ),

  relationTypeOtherMustBeNull(
    'chk_item_link_history_relation_type_other_must_be_null',
  ),

  labelNotBlank('chk_item_link_history_label_not_blank'),

  sortOrderNonNegative('chk_item_link_history_sort_order_non_negative'),

  createdModifiedRange('chk_item_link_history_created_modified_range');

  const ItemLinkHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum ItemLinkHistoryIndex {
  snapshotId('idx_item_link_history_snapshot_id'),
  historyId('idx_item_link_history_history_id'),
  sourceLinkId('idx_item_link_history_source_link_id'),
  sourceItemId('idx_item_link_history_source_item_id'),
  targetItemId('idx_item_link_history_target_item_id'),
  relationType('idx_item_link_history_relation_type'),
  sourceRelationType('idx_item_link_history_source_relation_type'),
  targetRelationType('idx_item_link_history_target_relation_type'),
  sourceSortOrder('idx_item_link_history_source_sort_order'),
  snapshotCreatedAt('idx_item_link_history_snapshot_created_at');

  const ItemLinkHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> itemLinkHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${ItemLinkHistoryIndex.snapshotId.indexName} ON item_link_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS ${ItemLinkHistoryIndex.historyId.indexName} ON item_link_history(history_id);',
  'CREATE INDEX IF NOT EXISTS ${ItemLinkHistoryIndex.sourceLinkId.indexName} ON item_link_history(source_link_id);',
  'CREATE INDEX IF NOT EXISTS ${ItemLinkHistoryIndex.sourceItemId.indexName} ON item_link_history(source_item_id);',
  'CREATE INDEX IF NOT EXISTS ${ItemLinkHistoryIndex.targetItemId.indexName} ON item_link_history(target_item_id);',
  'CREATE INDEX IF NOT EXISTS ${ItemLinkHistoryIndex.relationType.indexName} ON item_link_history(relation_type);',
  'CREATE INDEX IF NOT EXISTS ${ItemLinkHistoryIndex.sourceRelationType.indexName} ON item_link_history(source_item_id, relation_type);',
  'CREATE INDEX IF NOT EXISTS ${ItemLinkHistoryIndex.targetRelationType.indexName} ON item_link_history(target_item_id, relation_type);',
  'CREATE INDEX IF NOT EXISTS ${ItemLinkHistoryIndex.sourceSortOrder.indexName} ON item_link_history(source_item_id, sort_order);',
  'CREATE INDEX IF NOT EXISTS ${ItemLinkHistoryIndex.snapshotCreatedAt.indexName} ON item_link_history(snapshot_created_at);',
];
