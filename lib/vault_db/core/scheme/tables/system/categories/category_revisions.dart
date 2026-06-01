import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'categories.dart';

@DataClassName('CategoryRevisionData')
class CategoryRevisions extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get categoryOriginalId => text()();

  TextColumn get name => text().withLength(min: 1, max: 100)();

  TextColumn get iconRefId => text().nullable()();

  IntColumn get color => integer()();

  TextColumn get parentOriginalId => text().nullable()();

  DateTimeColumn get categoryCreatedAt => dateTime()();

  DateTimeColumn get categoryModifiedAt => dateTime()();

  DateTimeColumn get snapshotCreatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'category_revisions';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${CategoryRevisionConstraint.idNotBlank.constraintName}
    CHECK (
      length(trim(id)) > 0
    )
    ''',
    '''
    CONSTRAINT ${CategoryRevisionConstraint.originalCategoryIdNotBlank.constraintName}
    CHECK (
      length(trim(category_original_id)) > 0
    )
    ''',
    '''
    CONSTRAINT ${CategoryRevisionConstraint.nameNotBlank.constraintName}
    CHECK (
      length(trim(name)) > 0
    )
    ''',
    '''
    CONSTRAINT ${CategoryRevisionConstraint.nameNoOuterWhitespace.constraintName}
    CHECK (
      name = trim(name)
    )
    ''',
    '''
    CONSTRAINT ${CategoryRevisionConstraint.iconRefIdNotBlank.constraintName}
    CHECK (
      icon_ref_id IS NULL
      OR length(trim(icon_ref_id)) > 0
    )
    ''',
    '''
    CONSTRAINT ${CategoryRevisionConstraint.colorRange.constraintName}
    CHECK (
      color BETWEEN 0 AND 16777215
    )
    ''',
    '''
    CONSTRAINT ${CategoryRevisionConstraint.parentOriginalIdNotBlank.constraintName}
    CHECK (
      parent_original_id IS NULL
      OR length(trim(parent_original_id)) > 0
    )
    ''',
    '''
    CONSTRAINT ${CategoryRevisionConstraint.categoryModifiedAtRange.constraintName}
    CHECK (
      category_modified_at >= category_created_at
    )
    ''',
  ];
}

enum CategoryRevisionConstraint {
  idNotBlank('chk_category_revisions_id_not_blank'),
  originalCategoryIdNotBlank(
    'chk_category_revisions_category_original_id_not_blank',
  ),
  nameNotBlank('chk_category_revisions_name_not_blank'),
  nameNoOuterWhitespace('chk_category_revisions_name_no_outer_whitespace'),
  iconRefIdNotBlank('chk_category_revisions_icon_ref_id_not_blank'),
  colorRange('chk_category_revisions_color_range'),
  parentOriginalIdNotBlank(
    'chk_category_revisions_parent_original_id_not_blank',
  ),
  categoryModifiedAtRange('chk_category_revisions_category_modified_at_range');

  const CategoryRevisionConstraint(this.constraintName);

  final String constraintName;
}

enum CategoryRevisionIndex {
  categoryId('idx_category_revisions_category_id'),
  categoryOriginalId('idx_category_revisions_category_original_id'),
  snapshotCreatedAt('idx_category_revisions_snapshot_created_at');

  const CategoryRevisionIndex(this.indexName);

  final String indexName;
}

final List<String> categoryRevisionsTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${CategoryRevisionIndex.categoryId.indexName}
  ON category_revisions(category_id)
  WHERE category_id IS NOT NULL;
  ''',
  'CREATE INDEX IF NOT EXISTS ${CategoryRevisionIndex.categoryOriginalId.indexName} ON category_revisions(category_original_id);',
  'CREATE INDEX IF NOT EXISTS ${CategoryRevisionIndex.snapshotCreatedAt.indexName} ON category_revisions(snapshot_created_at);',
];

enum CategoryRevisionTrigger {
  preventUpdate('trg_category_revisions_prevent_update');

  const CategoryRevisionTrigger(this.triggerName);

  final String triggerName;
}

enum CategoryRevisionRaise {
  historyIsImmutable('category_revisions rows are immutable');

  const CategoryRevisionRaise(this.message);

  final String message;
}

final List<String> categoryRevisionsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${CategoryRevisionTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON category_revisions
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${CategoryRevisionRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
