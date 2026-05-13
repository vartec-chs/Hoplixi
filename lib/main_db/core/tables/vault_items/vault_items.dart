import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../system/categories.dart';
import '../system/icons/icon_refs.dart';

enum VaultItemType {
  password,
  otp,
  note,
  bankCard,
  document,
  file,
  contact,
  apiKey,
  sshKey,
  certificate,
  cryptoWallet,
  wifi,
  identity,
  licenseKey,
  recoveryCodes,
  loyaltyCard,
}

@DataClassName('VaultItemsData')
class VaultItems extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  TextColumn get type => textEnum<VaultItemType>()();

  TextColumn get name => text().withLength(min: 1, max: 255)();

  TextColumn get description => text().nullable()();

  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get iconRefId => text().nullable().references(
    IconRefs,
    #id,
    onDelete: KeyAction.setNull,
  )();

  IntColumn get usedCount => integer().withDefault(const Constant(0))();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  DateTimeColumn get archivedAt => dateTime().nullable()();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  RealColumn get recentScore => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'vault_items';

  @override
  List<String> get customConstraints => [
    '''
        CONSTRAINT ${VaultItemConstraint.idNotBlank.constraintName}
        CHECK (
          length(trim(id)) > 0
        )
        ''',
    '''
        CONSTRAINT ${VaultItemConstraint.nameNotBlank.constraintName}
        CHECK (
          length(trim(name)) > 0
        )
        ''',
    '''
        CONSTRAINT ${VaultItemConstraint.nameNoOuterWhitespace.constraintName}
        CHECK (
          name = trim(name)
        )
        ''',
    '''
        CONSTRAINT ${VaultItemConstraint.descriptionNotBlank.constraintName}
        CHECK (
          description IS NULL
          OR length(trim(description)) > 0
        )
        ''',
    '''
        CONSTRAINT ${VaultItemConstraint.categoryIdNotBlank.constraintName}
        CHECK (
          category_id IS NULL
          OR length(trim(category_id)) > 0
        )
        ''',
    '''
        CONSTRAINT ${VaultItemConstraint.iconRefIdNotBlank.constraintName}
        CHECK (
          icon_ref_id IS NULL
          OR length(trim(icon_ref_id)) > 0
        )
        ''',
    '''
        CONSTRAINT ${VaultItemConstraint.usedCountNonNegative.constraintName}
        CHECK (
          used_count >= 0
        )
        ''',
    '''
        CONSTRAINT ${VaultItemConstraint.usedCountLastUsedConsistent.constraintName}
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
        CONSTRAINT ${VaultItemConstraint.recentScoreNonNegative.constraintName}
        CHECK (
          recent_score IS NULL
          OR recent_score >= 0
        )
        ''',
    '''
        CONSTRAINT ${VaultItemConstraint.modifiedAtAfterCreatedAt.constraintName}
        CHECK (
          modified_at >= created_at
        )
        ''',
    '''
        CONSTRAINT ${VaultItemConstraint.lastUsedAtAfterCreatedAt.constraintName}
        CHECK (
          last_used_at IS NULL
          OR last_used_at >= created_at
        )
        ''',
    '''
        CONSTRAINT ${VaultItemConstraint.archivedAtStateConsistent.constraintName}
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
        CONSTRAINT ${VaultItemConstraint.deletedAtStateConsistent.constraintName}
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
        CONSTRAINT ${VaultItemConstraint.deletedArchivedConflict.constraintName}
        CHECK (
          NOT (
            is_deleted = 1
            AND is_archived = 1
          )
        )
        ''',
    '''
        CONSTRAINT ${VaultItemConstraint.deletedPinnedConflict.constraintName}
        CHECK (
          NOT (
            is_deleted = 1
            AND is_pinned = 1
          )
        )
        ''',
    '''
        CONSTRAINT ${VaultItemConstraint.deletedFavoriteConflict.constraintName}
        CHECK (
          NOT (
            is_deleted = 1
            AND is_favorite = 1
          )
        )
        ''',
  ];
}

enum VaultItemConstraint {
  idNotBlank('chk_vault_items_id_not_blank'),

  nameNotBlank('chk_vault_items_name_not_blank'),

  nameNoOuterWhitespace('chk_vault_items_name_no_outer_whitespace'),

  descriptionNotBlank('chk_vault_items_description_not_blank'),

  categoryIdNotBlank('chk_vault_items_category_id_not_blank'),

  iconRefIdNotBlank('chk_vault_items_icon_ref_id_not_blank'),

  usedCountNonNegative('chk_vault_items_used_count_non_negative'),

  usedCountLastUsedConsistent(
    'chk_vault_items_used_count_last_used_consistent',
  ),

  recentScoreNonNegative('chk_vault_items_recent_score_non_negative'),

  modifiedAtAfterCreatedAt('chk_vault_items_modified_at_after_created_at'),

  lastUsedAtAfterCreatedAt('chk_vault_items_last_used_at_after_created_at'),

  archivedAtStateConsistent('chk_vault_items_archived_at_state_consistent'),

  deletedAtStateConsistent('chk_vault_items_deleted_at_state_consistent'),

  deletedArchivedConflict('chk_vault_items_deleted_archived_conflict'),

  deletedPinnedConflict('chk_vault_items_deleted_pinned_conflict'),

  deletedFavoriteConflict('chk_vault_items_deleted_favorite_conflict');

  const VaultItemConstraint(this.constraintName);

  final String constraintName;
}

enum VaultItemIndex {
  name('idx_vault_items_name'),

  categoryId('idx_vault_items_category_id'),

  iconRefId('idx_vault_items_icon_ref_id'),

  createdAt('idx_vault_items_created_at'),

  modifiedAt('idx_vault_items_modified_at'),

  deletedAt('idx_vault_items_deleted_at'),

  archivedAt('idx_vault_items_archived_at'),

  activeByType('idx_vault_items_active_by_type'),

  activeRecent('idx_vault_items_active_recent'),

  activeFavorite('idx_vault_items_active_favorite'),

  activePinned('idx_vault_items_active_pinned'),

  deletedItems('idx_vault_items_deleted_items'),

  archivedItems('idx_vault_items_archived_items');

  const VaultItemIndex(this.indexName);

  final String indexName;
}

final List<String> vaultItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${VaultItemIndex.name.indexName} '
      'ON vault_items(name);',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemIndex.categoryId.indexName}
  ON vault_items(category_id)
  WHERE category_id IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemIndex.iconRefId.indexName}
  ON vault_items(icon_ref_id)
  WHERE icon_ref_id IS NOT NULL;
  ''',

  'CREATE INDEX IF NOT EXISTS ${VaultItemIndex.createdAt.indexName} '
      'ON vault_items(created_at);',

  'CREATE INDEX IF NOT EXISTS ${VaultItemIndex.modifiedAt.indexName} '
      'ON vault_items(modified_at);',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemIndex.deletedAt.indexName}
  ON vault_items(deleted_at)
  WHERE is_deleted = 1 AND deleted_at IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemIndex.archivedAt.indexName}
  ON vault_items(archived_at)
  WHERE is_archived = 1 AND is_deleted = 0 AND archived_at IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemIndex.activeByType.indexName}
  ON vault_items(type, is_pinned, modified_at DESC)
  WHERE is_deleted = 0 AND is_archived = 0;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemIndex.activeRecent.indexName}
  ON vault_items(recent_score DESC, last_used_at DESC, modified_at DESC)
  WHERE is_deleted = 0 AND is_archived = 0;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemIndex.activeFavorite.indexName}
  ON vault_items(type, modified_at DESC)
  WHERE is_favorite = 1 AND is_deleted = 0 AND is_archived = 0;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemIndex.activePinned.indexName}
  ON vault_items(type, modified_at DESC)
  WHERE is_pinned = 1 AND is_deleted = 0 AND is_archived = 0;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemIndex.deletedItems.indexName}
  ON vault_items(deleted_at DESC)
  WHERE is_deleted = 1 AND deleted_at IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemIndex.archivedItems.indexName}
  ON vault_items(archived_at DESC)
  WHERE is_archived = 1 AND is_deleted = 0 AND archived_at IS NOT NULL;
  ''',
];

enum VaultItemTrigger {
  preventCreatedAtUpdate('trg_vault_items_prevent_created_at_update'),

  preventTypeUpdate('trg_vault_items_prevent_type_update');

  const VaultItemTrigger(this.triggerName);

  final String triggerName;
}

enum VaultItemRaise {
  createdAtImmutable('vault_items.created_at is immutable'),

  typeImmutable('vault_items.type is immutable');

  const VaultItemRaise(this.message);

  final String message;
}

final List<String> vaultItemsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${VaultItemTrigger.preventCreatedAtUpdate.triggerName}
  BEFORE UPDATE OF created_at ON vault_items
  FOR EACH ROW
  WHEN NEW.created_at <> OLD.created_at
  BEGIN
    SELECT RAISE(
      ABORT,
      '${VaultItemRaise.createdAtImmutable.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${VaultItemTrigger.preventTypeUpdate.triggerName}
  BEFORE UPDATE OF type ON vault_items
  FOR EACH ROW
  WHEN NEW.type <> OLD.type
  BEGIN
    SELECT RAISE(
      ABORT,
      '${VaultItemRaise.typeImmutable.message}'
    );
  END;
  ''',
];
