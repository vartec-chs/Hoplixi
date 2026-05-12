import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../vault_items/vault_item_history.dart';
import 'categories.dart';

/// Snapshot категории vault item для восстановления по snapshotId.
@DataClassName('ItemCategoryHistoryData')
class ItemCategoryHistory extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  TextColumn get historyId => text().nullable().references(
    VaultItemHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

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
    CONSTRAINT ${ItemCategoryHistoryConstraint.nameNotBlank.constraintName}
    CHECK (
      length(trim(name)) > 0
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
    CONSTRAINT ${ItemCategoryHistoryConstraint.colorArgbHex.constraintName}
    CHECK (
      color GLOB '[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'
    )
    ''',
  ];
}

enum ItemCategoryHistoryConstraint {
  nameNotBlank('chk_item_category_history_name_not_blank'),
  descriptionNotBlank('chk_item_category_history_description_not_blank'),
  colorArgbHex('chk_item_category_history_color_argb_hex');

  const ItemCategoryHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum ItemCategoryHistoryIndex {
  snapshotId('idx_item_category_history_snapshot_id'),
  historyId('idx_item_category_history_history_id'),
  itemId('idx_item_category_history_item_id'),
  categoryId('idx_item_category_history_category_id'),
  type('idx_item_category_history_type'),
  snapshotCreatedAt('idx_item_category_history_snapshot_created_at');

  const ItemCategoryHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> itemCategoryHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${ItemCategoryHistoryIndex.snapshotId.indexName} ON item_category_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS ${ItemCategoryHistoryIndex.historyId.indexName} ON item_category_history(history_id);',
  'CREATE INDEX IF NOT EXISTS ${ItemCategoryHistoryIndex.itemId.indexName} ON item_category_history(item_id);',
  'CREATE INDEX IF NOT EXISTS ${ItemCategoryHistoryIndex.categoryId.indexName} ON item_category_history(category_id);',
  'CREATE INDEX IF NOT EXISTS ${ItemCategoryHistoryIndex.type.indexName} ON item_category_history(type);',
  'CREATE INDEX IF NOT EXISTS ${ItemCategoryHistoryIndex.snapshotCreatedAt.indexName} ON item_category_history(snapshot_created_at);',
];
