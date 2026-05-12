import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../vault_items/vault_snapshots_history.dart';
import 'tags.dart';

/// Snapshot тегов vault item для восстановления по snapshotId.
@DataClassName('VaultItemTagHistoryData')
class VaultItemTagHistory extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  TextColumn get historyId => text().nullable().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// UUID снимка для группировки связанных записей.
  TextColumn get snapshotId => text().nullable()();

  /// ID исходного vault item.
  TextColumn get itemId => text().nullable()();

  /// ID исходного tag.
  TextColumn get tagId => text().nullable()();

  TextColumn get name => text().withLength(min: 1, max: 100)();

  TextColumn get color => text().withLength(min: 8, max: 8)();

  TextColumn get type => textEnum<TagType>()();

  DateTimeColumn get tagCreatedAt => dateTime().nullable()();

  DateTimeColumn get tagModifiedAt => dateTime().nullable()();

  DateTimeColumn get snapshotCreatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'vault_item_tag_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${VaultItemTagHistoryConstraint.nameNotBlank.constraintName}
    CHECK (
      length(trim(name)) > 0
    )
    ''',
    '''
    CONSTRAINT ${VaultItemTagHistoryConstraint.colorArgbHex.constraintName}
    CHECK (
      color GLOB '[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'
    )
    ''',
  ];
}

enum VaultItemTagHistoryConstraint {
  nameNotBlank('chk_vault_item_tag_history_name_not_blank'),
  colorArgbHex('chk_vault_item_tag_history_color_argb_hex');

  const VaultItemTagHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum VaultItemTagHistoryIndex {
  snapshotId('idx_vault_item_tag_history_snapshot_id'),
  historyId('idx_vault_item_tag_history_history_id'),
  itemId('idx_vault_item_tag_history_item_id'),
  tagId('idx_vault_item_tag_history_tag_id'),
  type('idx_vault_item_tag_history_type'),
  snapshotCreatedAt('idx_vault_item_tag_history_snapshot_created_at');

  const VaultItemTagHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> vaultItemTagHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${VaultItemTagHistoryIndex.snapshotId.indexName} ON vault_item_tag_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemTagHistoryIndex.historyId.indexName} ON vault_item_tag_history(history_id);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemTagHistoryIndex.itemId.indexName} ON vault_item_tag_history(item_id);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemTagHistoryIndex.tagId.indexName} ON vault_item_tag_history(tag_id);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemTagHistoryIndex.type.indexName} ON vault_item_tag_history(type);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemTagHistoryIndex.snapshotCreatedAt.indexName} ON vault_item_tag_history(snapshot_created_at);',
];
