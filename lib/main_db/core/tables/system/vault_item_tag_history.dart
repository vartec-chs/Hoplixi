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
    CONSTRAINT ${VaultItemTagHistoryConstraint.idNotBlank.constraintName}
    CHECK (
      length(trim(id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${VaultItemTagHistoryConstraint.historyIdNotBlank.constraintName}
    CHECK (
      history_id IS NULL
      OR length(trim(history_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${VaultItemTagHistoryConstraint.itemIdNotBlank.constraintName}
    CHECK (
      item_id IS NULL
      OR length(trim(item_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${VaultItemTagHistoryConstraint.tagIdNotBlank.constraintName}
    CHECK (
      tag_id IS NULL
      OR length(trim(tag_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${VaultItemTagHistoryConstraint.nameNotBlank.constraintName}
    CHECK (
      length(trim(name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${VaultItemTagHistoryConstraint.nameNoOuterWhitespace.constraintName}
    CHECK (
      name = trim(name)
    )
    ''',

    '''
    CONSTRAINT ${VaultItemTagHistoryConstraint.colorNotBlank.constraintName}
    CHECK (
      color IS NULL
      OR length(trim(color)) > 0
    )
    ''',

    '''
    CONSTRAINT ${VaultItemTagHistoryConstraint.colorNoOuterWhitespace.constraintName}
    CHECK (
      color IS NULL
      OR color = trim(color)
    )
    ''',

    '''
    CONSTRAINT ${VaultItemTagHistoryConstraint.tagModifiedAtRange.constraintName}
    CHECK (
      tag_created_at IS NULL
      OR tag_modified_at IS NULL
      OR tag_modified_at >= tag_created_at
    )
    ''',

    '''
    CONSTRAINT ${VaultItemTagHistoryConstraint.snapshotCreatedAtRange.constraintName}
    CHECK (
      tag_created_at IS NULL
      OR snapshot_created_at >= tag_created_at
    )
    ''',
  ];
}

enum VaultItemTagHistoryConstraint {
  idNotBlank('chk_vault_item_tag_history_id_not_blank'),

  historyIdNotBlank('chk_vault_item_tag_history_history_id_not_blank'),

  itemIdNotBlank('chk_vault_item_tag_history_item_id_not_blank'),

  tagIdNotBlank('chk_vault_item_tag_history_tag_id_not_blank'),

  nameNotBlank('chk_vault_item_tag_history_name_not_blank'),

  nameNoOuterWhitespace('chk_vault_item_tag_history_name_no_outer_whitespace'),

  colorNotBlank('chk_vault_item_tag_history_color_not_blank'),

  colorNoOuterWhitespace(
    'chk_vault_item_tag_history_color_no_outer_whitespace',
  ),

  tagModifiedAtRange('chk_vault_item_tag_history_tag_modified_at_range'),

  snapshotCreatedAtRange(
    'chk_vault_item_tag_history_snapshot_created_at_range',
  );

  const VaultItemTagHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum VaultItemTagHistoryIndex {
  historyId('idx_vault_item_tag_history_history_id'),
  itemId('idx_vault_item_tag_history_item_id'),
  tagId('idx_vault_item_tag_history_tag_id'),
  type('idx_vault_item_tag_history_type'),
  snapshotCreatedAt('idx_vault_item_tag_history_snapshot_created_at');

  const VaultItemTagHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> vaultItemTagHistoryTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemTagHistoryIndex.historyId.indexName}
  ON vault_item_tag_history(history_id)
  WHERE history_id IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemTagHistoryIndex.itemId.indexName}
  ON vault_item_tag_history(item_id)
  WHERE item_id IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemTagHistoryIndex.tagId.indexName}
  ON vault_item_tag_history(tag_id)
  WHERE tag_id IS NOT NULL;
  ''',
  'CREATE INDEX IF NOT EXISTS ${VaultItemTagHistoryIndex.type.indexName} ON vault_item_tag_history(type);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemTagHistoryIndex.snapshotCreatedAt.indexName} ON vault_item_tag_history(snapshot_created_at);',
];

enum VaultItemTagHistoryTrigger {
  preventUpdate('trg_vault_item_tag_history_prevent_update');

  const VaultItemTagHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum VaultItemTagHistoryRaise {
  historyIsImmutable('vault_item_tag_history rows are immutable');

  const VaultItemTagHistoryRaise(this.message);

  final String message;
}

final List<String> vaultItemTagHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${VaultItemTagHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON vault_item_tag_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${VaultItemTagHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
