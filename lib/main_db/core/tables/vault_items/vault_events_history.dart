import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'vault_items.dart';
import 'vault_snapshots_history.dart';

enum VaultEventHistoryAction {
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

  used,

  movedToCategory,
  categoryRemoved,

  iconChanged,
  iconRemoved,

  customFieldAdded,
  customFieldUpdated,
  customFieldDeleted,
  customFieldReordered,
}

enum VaultHistoryActorType {
  user,
  system,
  autoCleanup,
  import,
  sync,
  restore,
  extension,
  unknown,
}

@DataClassName('VaultEventHistoryData')
class VaultEventsHistory extends Table {
  /// UUID event-записи.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// ID исходного vault item.
  ///
  /// FK оставлен намеренно:
  /// при окончательном удалении item его event history тоже удаляется.
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Тип действия.
  TextColumn get action => textEnum<VaultEventHistoryAction>()();

  /// Тип элемента на момент события.
  TextColumn get type => textEnum<VaultItemType>()();

  /// Имя элемента на момент события для audit-ленты.
  ///
  /// Nullable intentionally:
  /// для некоторых технических событий можно хранить event без имени.
  TextColumn get name => text().withLength(min: 1, max: 255).nullable()();

  /// Описание события или дополнительный человекочитаемый контекст.
  TextColumn get description => text().nullable()();

  /// ID категории на момент события.
  ///
  /// Не FK: категория могла быть удалена.
  TextColumn get categoryId => text().nullable()();

  /// ID icon_ref на момент события.
  ///
  /// Не FK: icon_ref мог быть удалён.
  TextColumn get iconRefId => text().nullable()();

  /// Snapshot history, если событие связано с restorable snapshot.
  ///
  /// ON DELETE SET NULL:
  /// event может остаться даже после purge snapshot-данных.
  TextColumn get snapshotHistoryId => text().nullable().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Источник события.
  TextColumn get actorType =>
      textEnum<VaultHistoryActorType>().withDefault(const Constant('user'))();

  /// Когда создана запись event history.
  DateTimeColumn get eventCreatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'vault_events_history';

  @override
  List<String> get customConstraints => [
    '''
        CONSTRAINT ${VaultEventHistoryConstraint.idNotBlank.constraintName}
        CHECK (
          length(trim(id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultEventHistoryConstraint.itemIdNotBlank.constraintName}
        CHECK (
          length(trim(item_id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultEventHistoryConstraint.nameNotBlank.constraintName}
        CHECK (
          name IS NULL
          OR length(trim(name)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultEventHistoryConstraint.nameNoOuterWhitespace.constraintName}
        CHECK (
          name IS NULL
          OR name = trim(name)
        )
        ''',

    '''
        CONSTRAINT ${VaultEventHistoryConstraint.descriptionNotBlank.constraintName}
        CHECK (
          description IS NULL
          OR length(trim(description)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultEventHistoryConstraint.categoryIdNotBlank.constraintName}
        CHECK (
          category_id IS NULL
          OR length(trim(category_id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultEventHistoryConstraint.iconRefIdNotBlank.constraintName}
        CHECK (
          icon_ref_id IS NULL
          OR length(trim(icon_ref_id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultEventHistoryConstraint.snapshotHistoryIdNotBlank.constraintName}
        CHECK (
          snapshot_history_id IS NULL
          OR length(trim(snapshot_history_id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultEventHistoryConstraint.snapshotRequiredForRestorableActions.constraintName}
        CHECK (
          action NOT IN (
            'created',
            'updated',
            'archived',
            'restored',
            'deleted',
            'recovered',
            'movedToCategory',
            'categoryRemoved',
            'iconChanged',
            'iconRemoved',
            'customFieldAdded',
            'customFieldUpdated',
            'customFieldDeleted',
            'customFieldReordered'
          )
          OR snapshot_history_id IS NOT NULL
        )
        ''',
  ];
}

enum VaultEventHistoryConstraint {
  idNotBlank('chk_vault_events_history_id_not_blank'),

  itemIdNotBlank('chk_vault_events_history_item_id_not_blank'),

  nameNotBlank('chk_vault_events_history_name_not_blank'),

  nameNoOuterWhitespace('chk_vault_events_history_name_no_outer_whitespace'),

  descriptionNotBlank('chk_vault_events_history_description_not_blank'),

  categoryIdNotBlank('chk_vault_events_history_category_id_not_blank'),

  iconRefIdNotBlank('chk_vault_events_history_icon_ref_id_not_blank'),

  snapshotHistoryIdNotBlank(
    'chk_vault_events_history_snapshot_history_id_not_blank',
  ),

  snapshotRequiredForRestorableActions(
    'chk_vault_events_history_snapshot_required_for_restorable_actions',
  );

  const VaultEventHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum VaultEventHistoryIndex {
  itemEventCreatedAt('idx_vault_events_history_item_id_event_created_at'),

  itemActionEventCreatedAt(
    'idx_vault_events_history_item_id_action_event_created_at',
  ),

  actionEventCreatedAt('idx_vault_events_history_action_event_created_at'),

  typeEventCreatedAt('idx_vault_events_history_type_event_created_at'),

  categoryEventCreatedAt(
    'idx_vault_events_history_category_id_event_created_at',
  ),

  snapshotHistoryId('idx_vault_events_history_snapshot_history_id'),

  actorTypeEventCreatedAt(
    'idx_vault_events_history_actor_type_event_created_at',
  ),

  eventCreatedAt('idx_vault_events_history_event_created_at');

  const VaultEventHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> vaultEventsHistoryTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${VaultEventHistoryIndex.itemEventCreatedAt.indexName}
  ON vault_events_history(item_id, event_created_at DESC);
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultEventHistoryIndex.itemActionEventCreatedAt.indexName}
  ON vault_events_history(item_id, action, event_created_at DESC);
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultEventHistoryIndex.actionEventCreatedAt.indexName}
  ON vault_events_history(action, event_created_at DESC);
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultEventHistoryIndex.typeEventCreatedAt.indexName}
  ON vault_events_history(type, event_created_at DESC);
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultEventHistoryIndex.categoryEventCreatedAt.indexName}
  ON vault_events_history(category_id, event_created_at DESC)
  WHERE category_id IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultEventHistoryIndex.snapshotHistoryId.indexName}
  ON vault_events_history(snapshot_history_id)
  WHERE snapshot_history_id IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultEventHistoryIndex.actorTypeEventCreatedAt.indexName}
  ON vault_events_history(actor_type, event_created_at DESC);
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultEventHistoryIndex.eventCreatedAt.indexName}
  ON vault_events_history(event_created_at DESC);
  ''',
];

enum VaultEventHistoryTrigger {
  preventUpdate('trg_vault_events_history_prevent_update');

  const VaultEventHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum VaultEventHistoryRaise {
  historyIsImmutable('vault_events_history rows are immutable');

  const VaultEventHistoryRaise(this.message);

  final String message;
}

final List<String> vaultEventsHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${VaultEventHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON vault_events_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${VaultEventHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
