import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../system/item_category_history.dart';
import 'vault_events_history.dart';
import 'vault_items.dart';

@DataClassName('VaultSnapshotHistoryData')
class VaultSnapshotsHistory extends Table {
  /// UUID snapshot-записи.
  ///
  /// Это главный ID снимка, на который ссылаются связанные history-таблицы:
  /// custom_fields_history, password_history, document_versions и т.д.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// ID исходного vault item.
  ///
  /// FK оставлен намеренно:
  /// при окончательном удалении item его snapshot history тоже удаляется.
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Причина создания snapshot.
  TextColumn get action => textEnum<VaultEventHistoryAction>()();

  /// Тип элемента на момент snapshot.
  TextColumn get type => textEnum<VaultItemType>()();

  /// Имя элемента snapshot.
  TextColumn get name => text().withLength(min: 1, max: 255)();

  /// Описание элемента snapshot.
  TextColumn get description => text().nullable()();

  /// ID категории на момент snapshot.
  ///
  /// Не FK: категория может быть удалена.
  TextColumn get categoryId => text().nullable()();

  /// Snapshot категории, связанный с этой историей item.
  TextColumn get categoryHistoryId => text().nullable().references(
    ItemCategoryHistory,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// ID icon_ref на момент snapshot.
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

  /// Дата последнего использования snapshot.
  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  /// Дата архивации snapshot.
  DateTimeColumn get archivedAt => dateTime().nullable()();

  /// Дата мягкого удаления snapshot.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// EWMA-скор snapshot.
  RealColumn get recentScore => real().nullable()();

  /// Когда создана запись истории.
  DateTimeColumn get historyCreatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'vault_snapshots_history';

  @override
  List<String> get customConstraints => [
    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.idNotBlank.constraintName}
        CHECK (
          length(trim(id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.itemIdNotBlank.constraintName}
        CHECK (
          length(trim(item_id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.nameNotBlank.constraintName}
        CHECK (
          length(trim(name)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.nameNoOuterWhitespace.constraintName}
        CHECK (
          name = trim(name)
        )
        ''',

    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.descriptionNotBlank.constraintName}
        CHECK (
          description IS NULL
          OR length(trim(description)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.categoryIdNotBlank.constraintName}
        CHECK (
          category_id IS NULL
          OR length(trim(category_id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.categoryHistoryRequiresCategoryId.constraintName}
        CHECK (
          category_history_id IS NULL
          OR category_id IS NOT NULL
        )
        ''',

    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.iconRefIdNotBlank.constraintName}
        CHECK (
          icon_ref_id IS NULL
          OR length(trim(icon_ref_id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.usedCountNonNegative.constraintName}
        CHECK (
          used_count >= 0
        )
        ''',

    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.usedCountLastUsedConsistent.constraintName}
        CHECK (
          (
            used_count = 0
            AND last_used_at IS NULL
          )
          OR
          (
            used_count > 0
            AND last_used_at IS NOT NULL
          )
        )
        ''',

    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.recentScoreNonNegative.constraintName}
        CHECK (
          recent_score IS NULL
          OR recent_score >= 0
        )
        ''',

    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.createdModifiedRange.constraintName}
        CHECK (
          created_at <= modified_at
        )
        ''',

    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.lastUsedAtRange.constraintName}
        CHECK (
          last_used_at IS NULL
          OR last_used_at >= created_at
        )
        ''',

    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.archivedAtStateConsistent.constraintName}
        CHECK (
          (
            is_archived = 0
            AND archived_at IS NULL
          )
          OR
          (
            is_archived = 1
            AND archived_at IS NOT NULL
            AND archived_at >= created_at
          )
        )
        ''',

    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.deletedAtStateConsistent.constraintName}
        CHECK (
          (
            is_deleted = 0
            AND deleted_at IS NULL
          )
          OR
          (
            is_deleted = 1
            AND deleted_at IS NOT NULL
            AND deleted_at >= created_at
          )
        )
        ''',

    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.deletedArchivedConflict.constraintName}
        CHECK (
          NOT (
            is_deleted = 1
            AND is_archived = 1
          )
        )
        ''',

    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.deletedPinnedConflict.constraintName}
        CHECK (
          NOT (
            is_deleted = 1
            AND is_pinned = 1
          )
        )
        ''',

    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.deletedFavoriteConflict.constraintName}
        CHECK (
          NOT (
            is_deleted = 1
            AND is_favorite = 1
          )
        )
        ''',

    '''
        CONSTRAINT ${VaultSnapshotHistoryConstraint.historyCreatedAtRange.constraintName}
        CHECK (
          history_created_at >= created_at
        )
        ''',
  ];
}

enum VaultSnapshotHistoryConstraint {
  idNotBlank('chk_vault_snapshots_history_id_not_blank'),

  itemIdNotBlank('chk_vault_snapshots_history_item_id_not_blank'),

  nameNotBlank('chk_vault_snapshots_history_name_not_blank'),

  nameNoOuterWhitespace('chk_vault_snapshots_history_name_no_outer_whitespace'),

  descriptionNotBlank('chk_vault_snapshots_history_description_not_blank'),

  categoryIdNotBlank('chk_vault_snapshots_history_category_id_not_blank'),

  categoryHistoryRequiresCategoryId(
    'chk_vault_snapshots_history_category_history_requires_category_id',
  ),

  iconRefIdNotBlank('chk_vault_snapshots_history_icon_ref_id_not_blank'),

  usedCountNonNegative('chk_vault_snapshots_history_used_count_non_negative'),

  usedCountLastUsedConsistent(
    'chk_vault_snapshots_history_used_count_last_used_consistent',
  ),

  recentScoreNonNegative(
    'chk_vault_snapshots_history_recent_score_non_negative',
  ),

  createdModifiedRange('chk_vault_snapshots_history_created_modified_range'),

  lastUsedAtRange('chk_vault_snapshots_history_last_used_at_range'),

  archivedAtStateConsistent(
    'chk_vault_snapshots_history_archived_at_state_consistent',
  ),

  deletedAtStateConsistent(
    'chk_vault_snapshots_history_deleted_at_state_consistent',
  ),

  deletedArchivedConflict(
    'chk_vault_snapshots_history_deleted_archived_conflict',
  ),

  deletedPinnedConflict('chk_vault_snapshots_history_deleted_pinned_conflict'),

  deletedFavoriteConflict(
    'chk_vault_snapshots_history_deleted_favorite_conflict',
  ),

  historyCreatedAtRange('chk_vault_snapshots_history_history_created_at_range');

  const VaultSnapshotHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum VaultSnapshotHistoryIndex {
  itemHistoryCreatedAt(
    'idx_vault_snapshots_history_item_id_history_created_at',
  ),

  itemActionHistoryCreatedAt(
    'idx_vault_snapshots_history_item_id_action_history_created_at',
  ),

  typeHistoryCreatedAt('idx_vault_snapshots_history_type_history_created_at'),

  actionHistoryCreatedAt(
    'idx_vault_snapshots_history_action_history_created_at',
  ),

  categoryHistoryCreatedAt(
    'idx_vault_snapshots_history_category_id_history_created_at',
  ),

  categoryHistoryId('idx_vault_snapshots_history_category_history_id'),

  deletedHistory('idx_vault_snapshots_history_deleted_history'),

  archivedHistory('idx_vault_snapshots_history_archived_history'),

  historyCreatedAt('idx_vault_snapshots_history_history_created_at');

  const VaultSnapshotHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> vaultSnapshotsHistoryTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${VaultSnapshotHistoryIndex.itemHistoryCreatedAt.indexName}
  ON vault_snapshots_history(item_id, history_created_at DESC);
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultSnapshotHistoryIndex.itemActionHistoryCreatedAt.indexName}
  ON vault_snapshots_history(item_id, action, history_created_at DESC);
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultSnapshotHistoryIndex.typeHistoryCreatedAt.indexName}
  ON vault_snapshots_history(type, history_created_at DESC);
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultSnapshotHistoryIndex.actionHistoryCreatedAt.indexName}
  ON vault_snapshots_history(action, history_created_at DESC);
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultSnapshotHistoryIndex.categoryHistoryCreatedAt.indexName}
  ON vault_snapshots_history(category_id, history_created_at DESC)
  WHERE category_id IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultSnapshotHistoryIndex.categoryHistoryId.indexName}
  ON vault_snapshots_history(category_history_id)
  WHERE category_history_id IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultSnapshotHistoryIndex.deletedHistory.indexName}
  ON vault_snapshots_history(item_id, deleted_at DESC)
  WHERE is_deleted = 1;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultSnapshotHistoryIndex.archivedHistory.indexName}
  ON vault_snapshots_history(item_id, archived_at DESC)
  WHERE is_archived = 1 AND is_deleted = 0;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultSnapshotHistoryIndex.historyCreatedAt.indexName}
  ON vault_snapshots_history(history_created_at DESC);
  ''',
];

enum VaultSnapshotHistoryTrigger {
  preventUpdate('trg_vault_snapshots_history_prevent_update');

  const VaultSnapshotHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum VaultSnapshotHistoryRaise {
  historyIsImmutable('vault_snapshots_history rows are immutable');

  const VaultSnapshotHistoryRaise(this.message);

  final String message;
}

final List<String> vaultSnapshotsHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${VaultSnapshotHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON vault_snapshots_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${VaultSnapshotHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
