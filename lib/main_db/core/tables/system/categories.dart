import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'icons/icon_refs.dart';

enum CategoryType {
  note,
  password,
  totp,
  bankCard,
  file,
  document,
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
  mixed,
}

@DataClassName('CategoriesData')
class Categories extends Table {
  /// UUID v4.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Название категории.
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Описание категории.
  TextColumn get description => text().nullable()();

  /// Ссылка на иконку категории.
  TextColumn get iconRefId => text().nullable().references(
    IconRefs,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Цвет категории в формате AARRGGBB.
  TextColumn get color => text()
      .withLength(min: 8, max: 8)
      .withDefault(const Constant('FFFFFFFF'))();

  /// Тип категории: password, note, mixed и т.д.
  TextColumn get type => textEnum<CategoryType>()();

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
  List<Set<Column>> get uniqueKeys => [
    {name, type},
  ];

  @override
  String get tableName => 'categories';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${CategoryConstraint.nameNotBlank.constraintName}
    CHECK (
      length(trim(name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CategoryConstraint.descriptionNotBlank.constraintName}
    CHECK (
      description IS NULL
      OR length(trim(description)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CategoryConstraint.colorArgbHex.constraintName}
    CHECK (
      color GLOB '[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'
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
  nameNotBlank('chk_categories_name_not_blank'),

  descriptionNotBlank('chk_categories_description_not_blank'),

  colorArgbHex('chk_categories_color_argb_hex'),

  noSelfParent('chk_categories_no_self_parent');

  const CategoryConstraint(this.constraintName);

  final String constraintName;
}

enum CategoryIndex {
  name('idx_categories_name'),
  type('idx_categories_type'),
  parentId('idx_categories_parent_id'),
  iconRefId('idx_categories_icon_ref_id'),
  createdAt('idx_categories_created_at'),
  modifiedAt('idx_categories_modified_at'),
  typeParent('idx_categories_type_parent_id'),
  parentName('idx_categories_parent_id_name'),
  rootUniqueNameType('uq_categories_root_name_type'),
  childUniqueNameTypeParent('uq_categories_child_name_type_parent');

  const CategoryIndex(this.indexName);

  final String indexName;
}

final List<String> categoriesTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${CategoryIndex.name.indexName} ON categories(name);',
  'CREATE INDEX IF NOT EXISTS ${CategoryIndex.type.indexName} ON categories(type);',
  'CREATE INDEX IF NOT EXISTS ${CategoryIndex.parentId.indexName} ON categories(parent_id);',
  'CREATE INDEX IF NOT EXISTS ${CategoryIndex.iconRefId.indexName} ON categories(icon_ref_id);',
  'CREATE INDEX IF NOT EXISTS ${CategoryIndex.createdAt.indexName} ON categories(created_at);',
  'CREATE INDEX IF NOT EXISTS ${CategoryIndex.modifiedAt.indexName} ON categories(modified_at);',
  'CREATE INDEX IF NOT EXISTS ${CategoryIndex.typeParent.indexName} ON categories(type, parent_id);',
  'CREATE INDEX IF NOT EXISTS ${CategoryIndex.parentName.indexName} ON categories(parent_id, name);',

  // Уникальность root-категорий: parent_id IS NULL.
  'CREATE UNIQUE INDEX IF NOT EXISTS ${CategoryIndex.rootUniqueNameType.indexName} '
      'ON categories(name, type) WHERE parent_id IS NULL;',

  // Уникальность дочерних категорий внутри одного parent_id.
  'CREATE UNIQUE INDEX IF NOT EXISTS ${CategoryIndex.childUniqueNameTypeParent.indexName} '
      'ON categories(parent_id, name, type) WHERE parent_id IS NOT NULL;',
];
