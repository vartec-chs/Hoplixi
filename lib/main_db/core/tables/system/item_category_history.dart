import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'categories.dart';

/// Snapshot категории vault item для восстановления по snapshotId.
@DataClassName('ItemCategoryHistoryData')
class ItemCategoryHistory extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// UUID снимка для группировки связанных записей.
  TextColumn get snapshotId => text().nullable()();

  /// ID исходного vault item.
  TextColumn get itemId => text().nullable()();

  /// ID исходной категории.
  TextColumn get categoryId => text().nullable()();

  TextColumn get name => text().withLength(min: 1, max: 100)();

  TextColumn get description => text().nullable()();

  TextColumn get iconRefId => text().nullable()();

  TextColumn get color => text().withLength(min: 8, max: 8)();

  TextColumn get type => textEnum<CategoryType>()();

  TextColumn get parentId => text().nullable()();

  DateTimeColumn get categoryCreatedAt => dateTime().nullable()();

  DateTimeColumn get categoryModifiedAt => dateTime().nullable()();

  DateTimeColumn get snapshotCreatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'item_category_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${ItemCategoryHistoryConstraint.idNotBlank.constraintName}
    CHECK (
      length(trim(id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ItemCategoryHistoryConstraint.originalCategoryIdNotBlank.constraintName}
    CHECK (
      category_id IS NULL
      OR length(trim(category_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ItemCategoryHistoryConstraint.nameNotBlank.constraintName}
    CHECK (
      length(trim(name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ItemCategoryHistoryConstraint.nameNoOuterWhitespace.constraintName}
    CHECK (
      name = trim(name)
    )
    ''',

    '''
    CONSTRAINT ${ItemCategoryHistoryConstraint.descriptionNotBlank.constraintName}
    CHECK (
      description IS NULL
      OR length(trim(description)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ItemCategoryHistoryConstraint.parentIdNotBlank.constraintName}
    CHECK (
      parent_id IS NULL
      OR length(trim(parent_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ItemCategoryHistoryConstraint.noSelfParent.constraintName}
    CHECK (
      parent_id IS NULL
      OR parent_id != category_id
    )
    ''',

    '''
    CONSTRAINT ${ItemCategoryHistoryConstraint.colorNotBlank.constraintName}
    CHECK (
      color IS NULL
      OR length(trim(color)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ItemCategoryHistoryConstraint.colorNoOuterWhitespace.constraintName}
    CHECK (
      color IS NULL
      OR color = trim(color)
    )
    ''',

    '''
    CONSTRAINT ${ItemCategoryHistoryConstraint.iconRefIdNotBlank.constraintName}
    CHECK (
      icon_ref_id IS NULL
      OR length(trim(icon_ref_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ItemCategoryHistoryConstraint.createdModifiedRange.constraintName}
    CHECK (
      category_created_at IS NULL
      OR category_modified_at IS NULL
      OR category_modified_at >= category_created_at
    )
    ''',

    '''
    CONSTRAINT ${ItemCategoryHistoryConstraint.snapshotCreatedAtRange.constraintName}
    CHECK (
      category_created_at IS NULL
      OR snapshot_created_at >= category_created_at
    )
    ''',
  ];
}

enum ItemCategoryHistoryConstraint {
  idNotBlank('chk_item_category_history_id_not_blank'),

  originalCategoryIdNotBlank(
    'chk_item_category_history_original_category_id_not_blank',
  ),

  nameNotBlank('chk_item_category_history_name_not_blank'),

  nameNoOuterWhitespace('chk_item_category_history_name_no_outer_whitespace'),

  descriptionNotBlank('chk_item_category_history_description_not_blank'),

  parentIdNotBlank('chk_item_category_history_parent_id_not_blank'),

  noSelfParent('chk_item_category_history_no_self_parent'),

  colorNotBlank('chk_item_category_history_color_not_blank'),

  colorNoOuterWhitespace('chk_item_category_history_color_no_outer_whitespace'),

  iconRefIdNotBlank('chk_item_category_history_icon_ref_id_not_blank'),

  createdModifiedRange('chk_item_category_history_created_modified_range'),

  snapshotCreatedAtRange('chk_item_category_history_snapshot_created_at_range');

  const ItemCategoryHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum ItemCategoryHistoryIndex {
  snapshotId('idx_item_category_history_snapshot_id'),
  itemId('idx_item_category_history_item_id'),
  originalCategoryId('idx_item_category_history_category_id'),
  parentId('idx_item_category_history_parent_id'),
  iconRefId('idx_item_category_history_icon_ref_id'),
  type('idx_item_category_history_type'),
  snapshotCreatedAt('idx_item_category_history_snapshot_created_at');

  const ItemCategoryHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> itemCategoryHistoryTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${ItemCategoryHistoryIndex.snapshotId.indexName}
  ON item_category_history(snapshot_id)
  WHERE snapshot_id IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${ItemCategoryHistoryIndex.itemId.indexName}
  ON item_category_history(item_id)
  WHERE item_id IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${ItemCategoryHistoryIndex.originalCategoryId.indexName}
  ON item_category_history(category_id)
  WHERE category_id IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${ItemCategoryHistoryIndex.parentId.indexName}
  ON item_category_history(parent_id)
  WHERE parent_id IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${ItemCategoryHistoryIndex.iconRefId.indexName}
  ON item_category_history(icon_ref_id)
  WHERE icon_ref_id IS NOT NULL;
  ''',
  'CREATE INDEX IF NOT EXISTS ${ItemCategoryHistoryIndex.type.indexName} ON item_category_history(type);',
  'CREATE INDEX IF NOT EXISTS ${ItemCategoryHistoryIndex.snapshotCreatedAt.indexName} ON item_category_history(snapshot_created_at);',
];

enum ItemCategoryHistoryTrigger {
  preventUpdate('trg_item_category_history_prevent_update');

  const ItemCategoryHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum ItemCategoryHistoryRaise {
  historyIsImmutable('item_category_history rows are immutable');

  const ItemCategoryHistoryRaise(this.message);

  final String message;
}

final List<String> itemCategoryHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemCategoryHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON item_category_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${ItemCategoryHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
