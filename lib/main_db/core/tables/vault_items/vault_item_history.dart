import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

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

  /// ID категории snapshot.
  ///
  /// Не FK специально: история должна хранить снимок значения,
  /// даже если категория позже удалена.
  TextColumn get categoryId => text().nullable()();

  /// ID icon_ref snapshot.
  ///
  /// Не FK специально: история должна хранить снимок значения,
  /// даже если icon_ref позже удалён.
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
  ];
}

enum VaultItemHistoryConstraint {
  nameNotBlank('chk_vault_item_history_name_not_blank'),

  usedCountNonNegative('chk_vault_item_history_used_count_non_negative'),

  recentScoreNonNegative('chk_vault_item_history_recent_score_non_negative'),

  createdModifiedRange('chk_vault_item_history_created_modified_range');

  const VaultItemHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum VaultItemHistoryIndex {
  itemId('idx_vault_item_history_item_id'),
  action('idx_vault_item_history_action'),
  type('idx_vault_item_history_type'),
  name('idx_vault_item_history_name'),
  categoryId('idx_vault_item_history_category_id'),
  iconRefId('idx_vault_item_history_icon_ref_id'),
  historyCreatedAt('idx_vault_item_history_history_created_at'),
  modifiedAt('idx_vault_item_history_modified_at'),
  lastUsedAt('idx_vault_item_history_last_used_at'),
  itemHistoryCreatedAt('idx_vault_item_history_item_id_history_created_at');

  const VaultItemHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> vaultItemHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.itemId.indexName} ON vault_item_history(item_id);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.action.indexName} ON vault_item_history(action);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.type.indexName} ON vault_item_history(type);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.name.indexName} ON vault_item_history(name);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.categoryId.indexName} ON vault_item_history(category_id);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.iconRefId.indexName} ON vault_item_history(icon_ref_id);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.historyCreatedAt.indexName} ON vault_item_history(history_created_at);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.modifiedAt.indexName} ON vault_item_history(modified_at);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.lastUsedAt.indexName} ON vault_item_history(last_used_at);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemHistoryIndex.itemHistoryCreatedAt.indexName} ON vault_item_history(item_id, history_created_at);',
];
