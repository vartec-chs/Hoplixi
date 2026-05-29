import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../icons/icon_refs.dart';

@DataClassName('CategoriesData')
class Categories extends Table {
  /// UUID v4.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Название категории.
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Ссылка на иконку категории.
  TextColumn get iconRefId => text().nullable().references(
    IconRefs,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Цвет категории в формате RGB.
  IntColumn get color => integer().withDefault(const Constant(0xFFFFFF))();

  /// Родительская категория.
  TextColumn get parentId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
  )();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'categories';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${CategoryConstraint.idNotBlank.constraintName}
    CHECK (
      length(trim(id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CategoryConstraint.nameNotBlank.constraintName}
    CHECK (
      length(trim(name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CategoryConstraint.nameNoOuterWhitespace.constraintName}
    CHECK (
      name = trim(name)
    )
    ''',

    '''
    CONSTRAINT ${CategoryConstraint.parentIdNotBlank.constraintName}
    CHECK (
      parent_id IS NULL
      OR length(trim(parent_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CategoryConstraint.colorRange.constraintName}
    CHECK (
      color BETWEEN 0 AND 16777215
    )
    ''',

    '''
    CONSTRAINT ${CategoryConstraint.iconRefIdNotBlank.constraintName}
    CHECK (
      icon_ref_id IS NULL
      OR length(trim(icon_ref_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CategoryConstraint.modifiedAtAfterCreatedAt.constraintName}
    CHECK (
      modified_at >= created_at
    )
    ''',

    '''
    CONSTRAINT ${CategoryConstraint.noSelfParent.constraintName}
    CHECK (
      parent_id IS NULL
      OR parent_id != id
    )
    ''',
  ];
}

enum CategoryConstraint {
  idNotBlank('chk_categories_id_not_blank'),

  nameNotBlank('chk_categories_name_not_blank'),

  nameNoOuterWhitespace('chk_categories_name_no_outer_whitespace'),

  parentIdNotBlank('chk_categories_parent_id_not_blank'),

  colorRange('chk_categories_color_range'),

  iconRefIdNotBlank('chk_categories_icon_ref_id_not_blank'),

  modifiedAtAfterCreatedAt('chk_categories_modified_at_after_created_at'),

  noSelfParent('chk_categories_no_self_parent');

  const CategoryConstraint(this.constraintName);

  final String constraintName;
}

enum CategoryIndex {
  name('idx_categories_name'),
  parentId('idx_categories_parent_id'),
  iconRefId('idx_categories_icon_ref_id'),
  createdAt('idx_categories_created_at'),
  modifiedAt('idx_categories_modified_at'),
  rootUniqueName('uq_categories_root_name'),
  childUniqueName('uq_categories_child_name_parent');

  const CategoryIndex(this.indexName);

  final String indexName;
}

final List<String> categoriesTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${CategoryIndex.name.indexName} ON categories(name);',
  '''
  CREATE INDEX IF NOT EXISTS ${CategoryIndex.parentId.indexName}
  ON categories(parent_id)
  WHERE parent_id IS NOT NULL;
  ''',
  'CREATE INDEX IF NOT EXISTS ${CategoryIndex.iconRefId.indexName} ON categories(icon_ref_id);',
  'CREATE INDEX IF NOT EXISTS ${CategoryIndex.createdAt.indexName} ON categories(created_at);',
  'CREATE INDEX IF NOT EXISTS ${CategoryIndex.modifiedAt.indexName} ON categories(modified_at);',

  // Уникальность root-категорий: parent_id IS NULL.
  'CREATE UNIQUE INDEX IF NOT EXISTS ${CategoryIndex.rootUniqueName.indexName} '
      'ON categories(name) WHERE parent_id IS NULL;',

  // Уникальность дочерних категорий внутри одного parent_id.
  'CREATE UNIQUE INDEX IF NOT EXISTS ${CategoryIndex.childUniqueName.indexName} '
      'ON categories(parent_id, name) WHERE parent_id IS NOT NULL;',
];

enum CategoryTrigger {
  preventCreatedAtUpdate('trg_categories_prevent_created_at_update'),

  preventParentCycleOnInsert('trg_categories_prevent_parent_cycle_on_insert'),

  preventParentCycleOnUpdate('trg_categories_prevent_parent_cycle_on_update');

  const CategoryTrigger(this.triggerName);

  final String triggerName;
}

enum CategoryRaise {
  createdAtImmutable('categories.created_at is immutable'),

  parentCycleDetected('categories.parent_id creates a cycle');

  const CategoryRaise(this.message);

  final String message;
}

final List<String> categoriesTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${CategoryTrigger.preventCreatedAtUpdate.triggerName}
  BEFORE UPDATE OF created_at ON categories
  FOR EACH ROW
  WHEN NEW.created_at <> OLD.created_at
  BEGIN
    SELECT RAISE(
      ABORT,
      '${CategoryRaise.createdAtImmutable.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${CategoryTrigger.preventParentCycleOnInsert.triggerName}
  BEFORE INSERT ON categories
  FOR EACH ROW
  WHEN NEW.parent_id IS NOT NULL
    AND EXISTS (
      WITH RECURSIVE ancestor_ids(id) AS (
        SELECT NEW.parent_id
        UNION ALL
        SELECT c.parent_id
        FROM categories c
        JOIN ancestor_ids a ON c.id = a.id
        WHERE c.parent_id IS NOT NULL
      )
      SELECT 1
      FROM ancestor_ids
      WHERE id = NEW.id
    )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${CategoryRaise.parentCycleDetected.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${CategoryTrigger.preventParentCycleOnUpdate.triggerName}
  BEFORE UPDATE OF parent_id ON categories
  FOR EACH ROW
  WHEN NEW.parent_id IS NOT NULL
    AND EXISTS (
      WITH RECURSIVE ancestor_ids(id) AS (
        SELECT NEW.parent_id
        UNION ALL
        SELECT c.parent_id
        FROM categories c
        JOIN ancestor_ids a ON c.id = a.id
        WHERE c.parent_id IS NOT NULL
      )
      SELECT 1
      FROM ancestor_ids
      WHERE id = NEW.id
    )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${CategoryRaise.parentCycleDetected.message}'
    );
  END;
  ''',
];
