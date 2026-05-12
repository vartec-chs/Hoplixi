import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../system/categories.dart';
import 'vault_items.dart';

enum VaultItemHistoryAction {
  created,
  updated,
  archived,
  restored,
  deleted,
  recovered,
  favorited,
  unfavorited,
  pinned,
  unpinned,
}

@DataClassName('VaultItemHistoryData')
class VaultItemHistory extends Table {
  /// UUID записи истории.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// ID исходного vault item.
  ///
  /// FK можно оставить, если при удалении vault item история тоже должна удаляться.
  /// Если хочешь сохранять историю даже после физического удаления item —
  /// убери FK и оставь обычный text().
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Тип действия.
  TextColumn get action => textEnum<VaultItemHistoryAction>()();

  /// Тип элемента snapshot: password, otp, note и т.д.
  TextColumn get type => textEnum<VaultItemType>()();

  /// Имя элемента snapshot.
  TextColumn get name => text().withLength(min: 1, max: 255)();

  /// Описание элемента snapshot.
  TextColumn get description => text().nullable()();

  /// ID категории на момент snapshot.
  ///
  /// Не FK: категория может быть удалена.
  TextColumn get categoryId => text().nullable()();

  /// Snapshot имени категории.
  TextColumn get categoryName =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Snapshot типа категории.
  TextColumn get categoryType => textEnum<CategoryType>().nullable()();

  /// Snapshot цвета категории.
  TextColumn get categoryColor => text().nullable()();

  /// Snapshot icon_ref категории.
  TextColumn get categoryIconRefId => text().nullable()();

  /// Snapshot тегов на момент истории.
  ///
  /// Формат задаётся приложением, SQLite его не валидирует.
  ///
  /// Пример:
  /// [
  ///   {
  ///     "id": "tag-1",
  ///     "name": "Work",
  ///     "type": "password",
  ///     "color": "#FFAA00",
  ///     "iconRefId": null
  ///   }
  /// ]
  TextColumn get tagsSnapshotJson => text().withDefault(const Constant('[]'))();

  /// ID icon_ref snapshot.
  ///
  /// Не FK: icon_ref может быть удалён.
  TextColumn get iconRefId => text().nullable()();

  /// Количество использований snapshot.
  IntColumn get usedCount => integer().withDefault(const Constant(0))();

  /// Флаг избранного snapshot.
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// Флаг архивации snapshot.
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// Флаг закрепления snapshot.
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  /// Флаг мягкого удаления snapshot.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// Дата создания исходного item snapshot.
  DateTimeColumn get createdAt => dateTime()();

  /// Дата последнего изменения исходного item snapshot.
  DateTimeColumn get modifiedAt => dateTime()();

  /// EWMA-скор snapshot.
  RealColumn get recentScore => real().nullable()();

  /// Дата последнего использования snapshot.
  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  /// Когда создана запись истории.
  DateTimeColumn get historyCreatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'vault_item_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${VaultItemHistoryConstraint.nameNotBlank.constraintName}
    CHECK (
      length(trim(name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${VaultItemHistoryConstraint.categoryNameNotBlank.constraintName}
    CHECK (
      category_name IS NULL
      OR length(trim(category_name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${VaultItemHistoryConstraint.categoryColorNotBlank.constraintName}
    CHECK (
      category_color IS NULL
      OR length(trim(category_color)) > 0
    )
    ''',

    '''
    CONSTRAINT ${VaultItemHistoryConstraint.categoryIconRefIdNotBlank.constraintName}
    CHECK (
      category_icon_ref_id IS NULL
      OR length(trim(category_icon_ref_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${VaultItemHistoryConstraint.categorySnapshotConsistency.constraintName}
    CHECK (
      (
        category_id IS NULL
        AND category_name IS NULL
        AND category_type IS NULL
        AND category_color IS NULL
        AND category_icon_ref_id IS NULL
      )
      OR
      (
        category_id IS NOT NULL
        AND category_name IS NOT NULL
        AND category_type IS NOT NULL
      )
    )
    ''',

    '''
    CONSTRAINT ${VaultItemHistoryConstraint.tagsSnapshotJsonNotBlank.constraintName}
    CHECK (
      length(trim(tags_snapshot_json)) > 0
    )
    ''',

    '''
    CONSTRAINT ${VaultItemHistoryConstraint.iconRefIdNotBlank.constraintName}
    CHECK (
      icon_ref_id IS NULL
      OR length(trim(icon_ref_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${VaultItemHistoryConstraint.usedCountNonNegative.constraintName}
    CHECK (
      used_count >= 0
    )
    ''',

    '''
    CONSTRAINT ${VaultItemHistoryConstraint.recentScoreNonNegative.constraintName}
    CHECK (
      recent_score IS NULL
      OR recent_score >= 0
    )
    ''',

    '''
    CONSTRAINT ${VaultItemHistoryConstraint.createdModifiedRange.constraintName}
    CHECK (
      created_at <= modified_at
    )
    ''',

    '''
    CONSTRAINT ${VaultItemHistoryConstraint.lastUsedAtRange.constraintName}
    CHECK (
      last_used_at IS NULL
      OR last_used_at >= created_at
    )
    ''',

    '''
    CONSTRAINT ${VaultItemHistoryConstraint.historyCreatedAtRange.constraintName}
    CHECK (
      history_created_at >= created_at
    )
    ''',
  ];
}

enum VaultItemHistoryConstraint {
  nameNotBlank('chk_vault_item_history_name_not_blank'),

  categoryNameNotBlank('chk_vault_item_history_category_name_not_blank'),

  categoryColorNotBlank('chk_vault_item_history_category_color_not_blank'),

  categoryIconRefIdNotBlank(
    'chk_vault_item_history_category_icon_ref_id_not_blank',
  ),

  categorySnapshotConsistency(
    'chk_vault_item_history_category_snapshot_consistency',
  ),

  tagsSnapshotJsonNotBlank(
    'chk_vault_item_history_tags_snapshot_json_not_blank',
  ),

  iconRefIdNotBlank('chk_vault_item_history_icon_ref_id_not_blank'),

  usedCountNonNegative('chk_vault_item_history_used_count_non_negative'),

  recentScoreNonNegative('chk_vault_item_history_recent_score_non_negative'),

  createdModifiedRange('chk_vault_item_history_created_modified_range'),

  lastUsedAtRange('chk_vault_item_history_last_used_at_range'),

  historyCreatedAtRange('chk_vault_item_history_history_created_at_range');

  const VaultItemHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum VaultItemHistoryIndex {
  itemId('idx_vault_item_history_item_id'),
  action('idx_vault_item_history_action'),
  type('idx_vault_item_history_type'),
  name('idx_vault_item_history_name'),

  categoryId('idx_vault_item_history_category_id'),
  categoryName('idx_vault_item_history_category_name'),
  categoryType('idx_vault_item_history_category_type'),
  categoryIconRefId('idx_vault_item_history_category_icon_ref_id'),

  iconRefId('idx_vault_item_history_icon_ref_id'),

  isFavorite('idx_vault_item_history_is_favorite'),
  isArchived('idx_vault_item_history_is_archived'),
  isPinned('idx_vault_item_history_is_pinned'),
  isDeleted('idx_vault_item_history_is_deleted'),

  historyCreatedAt('idx_vault_item_history_history_created_at'),
  modifiedAt('idx_vault_item_history_modified_at'),
  lastUsedAt('idx_vault_item_history_last_used_at'),

  itemHistoryCreatedAt('idx_vault_item_history_item_id_history_created_at'),
  itemActionHistoryCreatedAt(
    'idx_vault_item_history_item_id_action_history_created_at',
  ),
  typeHistoryCreatedAt('idx_vault_item_history_type_history_created_at'),
  categoryHistoryCreatedAt(
    'idx_vault_item_history_category_id_history_created_at',
  );

  const VaultItemHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> vaultItemHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.itemId.indexName} ON vault_item_history(item_id);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.action.indexName} ON vault_item_history(action);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.type.indexName} ON vault_item_history(type);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.name.indexName} ON vault_item_history(name);',

  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.categoryId.indexName} ON vault_item_history(category_id);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.categoryName.indexName} ON vault_item_history(category_name);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.categoryType.indexName} ON vault_item_history(category_type);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.categoryIconRefId.indexName} ON vault_item_history(category_icon_ref_id);',

  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.iconRefId.indexName} ON vault_item_history(icon_ref_id);',

  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.isFavorite.indexName} ON vault_item_history(is_favorite);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.isArchived.indexName} ON vault_item_history(is_archived);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.isPinned.indexName} ON vault_item_history(is_pinned);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.isDeleted.indexName} ON vault_item_history(is_deleted);',

  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.historyCreatedAt.indexName} ON vault_item_history(history_created_at);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.modifiedAt.indexName} ON vault_item_history(modified_at);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.lastUsedAt.indexName} ON vault_item_history(last_used_at);',

  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.itemHistoryCreatedAt.indexName} ON vault_item_history(item_id, history_created_at);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.itemActionHistoryCreatedAt.indexName} ON vault_item_history(item_id, action, history_created_at);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.typeHistoryCreatedAt.indexName} ON vault_item_history(type, history_created_at);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.categoryHistoryCreatedAt.indexName} ON vault_item_history(category_id, history_created_at);',
];