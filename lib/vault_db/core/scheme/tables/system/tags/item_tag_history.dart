import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../vault_items/vault_snapshots_history.dart';
import 'tags.dart';

/// Snapshot тегов vault item для восстановления по snapshotId.
@DataClassName('ItemTagHistoryData')
class ItemTagHistory extends Table {
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

  IntColumn get color => integer()();

  TextColumn get type => textEnum<TagType>()();

  DateTimeColumn get tagCreatedAt => dateTime().nullable()();

  DateTimeColumn get tagModifiedAt => dateTime().nullable()();

  DateTimeColumn get snapshotCreatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'item_tag_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${ItemTagHistoryConstraint.idNotBlank.constraintName}
    CHECK (
      length(trim(id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ItemTagHistoryConstraint.historyIdNotBlank.constraintName}
    CHECK (
      history_id IS NULL
      OR length(trim(history_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ItemTagHistoryConstraint.itemIdNotBlank.constraintName}
    CHECK (
      item_id IS NULL
      OR length(trim(item_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ItemTagHistoryConstraint.tagIdNotBlank.constraintName}
    CHECK (
      tag_id IS NULL
      OR length(trim(tag_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ItemTagHistoryConstraint.nameNotBlank.constraintName}
    CHECK (
      length(trim(name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ItemTagHistoryConstraint.nameNoOuterWhitespace.constraintName}
    CHECK (
      name = trim(name)
    )
    ''',

    '''
    CONSTRAINT ${ItemTagHistoryConstraint.colorRange.constraintName}
    CHECK (
      color BETWEEN 0 AND 16777215
    )
    ''',

    '''
    CONSTRAINT ${ItemTagHistoryConstraint.tagModifiedAtRange.constraintName}
    CHECK (
      tag_created_at IS NULL
      OR tag_modified_at IS NULL
      OR tag_modified_at >= tag_created_at
    )
    ''',

    '''
    CONSTRAINT ${ItemTagHistoryConstraint.snapshotCreatedAtRange.constraintName}
    CHECK (
      tag_created_at IS NULL
      OR snapshot_created_at >= tag_created_at
    )
    ''',
  ];
}

enum ItemTagHistoryConstraint {
  idNotBlank('chk_item_tag_history_id_not_blank'),

  historyIdNotBlank('chk_item_tag_history_history_id_not_blank'),

  itemIdNotBlank('chk_item_tag_history_item_id_not_blank'),

  tagIdNotBlank('chk_item_tag_history_tag_id_not_blank'),

  nameNotBlank('chk_item_tag_history_name_not_blank'),

  nameNoOuterWhitespace('chk_item_tag_history_name_no_outer_whitespace'),

  colorRange('chk_item_tag_history_color_range'),

  tagModifiedAtRange('chk_item_tag_history_tag_modified_at_range'),

  snapshotCreatedAtRange('chk_item_tag_history_snapshot_created_at_range');

  const ItemTagHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum ItemTagHistoryIndex {
  historyId('idx_item_tag_history_history_id'),
  itemId('idx_item_tag_history_item_id'),
  tagId('idx_item_tag_history_tag_id'),
  type('idx_item_tag_history_type'),
  snapshotCreatedAt('idx_item_tag_history_snapshot_created_at');

  const ItemTagHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> itemTagHistoryTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${ItemTagHistoryIndex.historyId.indexName}
  ON item_tag_history(history_id)
  WHERE history_id IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${ItemTagHistoryIndex.itemId.indexName}
  ON item_tag_history(item_id)
  WHERE item_id IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${ItemTagHistoryIndex.tagId.indexName}
  ON item_tag_history(tag_id)
  WHERE tag_id IS NOT NULL;
  ''',
  'CREATE INDEX IF NOT EXISTS ${ItemTagHistoryIndex.type.indexName} ON item_tag_history(type);',
  'CREATE INDEX IF NOT EXISTS ${ItemTagHistoryIndex.snapshotCreatedAt.indexName} ON item_tag_history(snapshot_created_at);',
];

enum ItemTagHistoryTrigger {
  preventUpdate('trg_item_tag_history_prevent_update');

  const ItemTagHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum ItemTagHistoryRaise {
  historyIsImmutable('item_tag_history rows are immutable');

  const ItemTagHistoryRaise(this.message);

  final String message;
}

final List<String> itemTagHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemTagHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON item_tag_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${ItemTagHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
