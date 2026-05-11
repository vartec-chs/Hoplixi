import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../categories.dart';
import '../icon_refs.dart';

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

  RealColumn get recentScore => real().nullable()();

  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'vault_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${VaultItemConstraint.nameNotBlank.constraintName}
    CHECK (
      length(trim(name)) > 0
    )
    ''',
    '''
    CONSTRAINT ${VaultItemConstraint.usedCountNonNegative.constraintName}
    CHECK (
      used_count >= 0
    )
    ''',
    '''
    CONSTRAINT ${VaultItemConstraint.recentScoreNonNegative.constraintName}
    CHECK (
      recent_score IS NULL
      OR recent_score >= 0
    )
    ''',
  ];
}

enum VaultItemConstraint {
  nameNotBlank('chk_vault_items_name_not_blank'),

  usedCountNonNegative('chk_vault_items_used_count_non_negative'),

  recentScoreNonNegative('chk_vault_items_recent_score_non_negative');

  const VaultItemConstraint(this.constraintName);

  final String constraintName;
}

enum VaultItemIndex {
  type('idx_vault_items_type'),
  name('idx_vault_items_name'),
  categoryId('idx_vault_items_category_id'),
  iconRefId('idx_vault_items_icon_ref_id'),

  createdAt('idx_vault_items_created_at'),
  modifiedAt('idx_vault_items_modified_at'),
  lastUsedAt('idx_vault_items_last_used_at'),
  recentScore('idx_vault_items_recent_score'),

  typeDeletedArchived('idx_vault_items_type_deleted_archived'),
  activeByType('idx_vault_items_active_by_type'),
  activeRecent('idx_vault_items_active_recent'),
  favoriteActive('idx_vault_items_favorite_active'),
  pinnedActive('idx_vault_items_pinned_active');

  const VaultItemIndex(this.indexName);

  final String indexName;
}

final List<String> vaultItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${VaultItemIndex.type.indexName} ON vault_items(type);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemIndex.name.indexName} ON vault_items(name);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemIndex.categoryId.indexName} ON vault_items(category_id);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemIndex.iconRefId.indexName} ON vault_items(icon_ref_id);',

  'CREATE INDEX IF NOT EXISTS ${VaultItemIndex.createdAt.indexName} ON vault_items(created_at);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemIndex.modifiedAt.indexName} ON vault_items(modified_at);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemIndex.lastUsedAt.indexName} ON vault_items(last_used_at);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemIndex.recentScore.indexName} ON vault_items(recent_score);',

  'CREATE INDEX IF NOT EXISTS ${VaultItemIndex.typeDeletedArchived.indexName} ON vault_items(type, is_deleted, is_archived);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemIndex.activeByType.indexName} ON vault_items(type, is_deleted, is_archived, is_pinned);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemIndex.activeRecent.indexName} ON vault_items(is_deleted, is_archived, recent_score, last_used_at);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemIndex.favoriteActive.indexName} ON vault_items(is_favorite, is_deleted, is_archived);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemIndex.pinnedActive.indexName} ON vault_items(is_pinned, is_deleted, is_archived);',
];
