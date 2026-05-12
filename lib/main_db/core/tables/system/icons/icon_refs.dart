import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'custom_icons.dart';

enum IconSourceType { builtin, pack, custom }

@DataClassName('IconRefsData')
class IconRefs extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  TextColumn get iconSourceType => textEnum<IconSourceType>()();

  /// ID пака иконок, если iconType = pack.
  ///
  /// Если есть таблица IconPacks, лучше сделать FK:
  /// text().nullable().references(IconPacks, #id, onDelete: KeyAction.restrict)();
  TextColumn get iconPackId => text().withLength(min: 1, max: 255).nullable()();

  /// Ключ/значение иконки.
  ///
  /// builtin: key встроенной иконки
  /// pack: key иконки внутри пака
  TextColumn get iconValue => text().withLength(min: 1, max: 255).nullable()();

  /// Пользовательская иконка из custom_icons.
  TextColumn get customIconId => text().nullable().references(
    CustomIcons,
    #id,
    onDelete: KeyAction.restrict,
  )();

  /// Цвет иконки в формате AARRGGBB.
  TextColumn get color => text().withLength(min: 8, max: 8).nullable()();

  /// Цвет фона в формате AARRGGBB.
  TextColumn get backgroundColor =>
      text().withLength(min: 8, max: 8).nullable()();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'icon_refs';

  @override
  List<String> get customConstraints => [
    '''
        CONSTRAINT ${IconRefConstraint.validIconSource.constraintName}
        CHECK (
          (
            icon_source_type = 'builtin'
            AND icon_pack_id IS NULL
            AND icon_value IS NOT NULL
            AND length(trim(icon_value)) > 0
            AND custom_icon_id IS NULL
          )
          OR
          (
            icon_source_type = 'pack'
            AND icon_pack_id IS NOT NULL
            AND length(trim(icon_pack_id)) > 0
            AND icon_value IS NOT NULL
            AND length(trim(icon_value)) > 0
            AND custom_icon_id IS NULL
          )
          OR
          (
            icon_source_type = 'custom'
            AND icon_pack_id IS NULL
            AND icon_value IS NULL
            AND custom_icon_id IS NOT NULL
          )
        )
        ''',

    '''
        CONSTRAINT ${IconRefConstraint.colorArgbHex.constraintName}
        CHECK (
          color IS NULL
          OR color GLOB '[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'
        )
        ''',
    '''
        CONSTRAINT ${IconRefConstraint.backgroundColorArgbHex.constraintName}
        CHECK (
          background_color IS NULL
          OR background_color GLOB '[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'
        )
        ''',
  ];
}

enum IconRefConstraint {
  validIconSource('chk_icon_refs_valid_icon_source'),

  colorArgbHex('chk_icon_refs_color_argb_hex'),

  backgroundColorArgbHex('chk_icon_refs_background_color_argb_hex');

  const IconRefConstraint(this.constraintName);

  final String constraintName;
}

enum IconRefIndex {
  iconSourceType('idx_icon_refs_icon_source_type'),
  iconPackId('idx_icon_refs_icon_pack_id'),
  customIconId('idx_icon_refs_custom_icon_id'),
  iconValue('idx_icon_refs_icon_value'),

  uniqueBuiltin('uq_icon_refs_builtin'),
  uniquePack('uq_icon_refs_pack'),
  uniqueCustom('uq_icon_refs_custom');

  const IconRefIndex(this.indexName);

  final String indexName;
}

final List<String> iconRefsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${IconRefIndex.iconSourceType.indexName} ON icon_refs(icon_source_type);',
  'CREATE INDEX IF NOT EXISTS ${IconRefIndex.iconPackId.indexName} ON icon_refs(icon_pack_id);',
  'CREATE INDEX IF NOT EXISTS ${IconRefIndex.customIconId.indexName} ON icon_refs(custom_icon_id);',
  'CREATE INDEX IF NOT EXISTS ${IconRefIndex.iconValue.indexName} ON icon_refs(icon_value);',
  '''
  CREATE UNIQUE INDEX IF NOT EXISTS ${IconRefIndex.uniqueBuiltin.indexName}
  ON icon_refs(
    icon_value,
    COALESCE(color, ''),
    COALESCE(background_color, '')
  )
  WHERE icon_source_type = 'builtin';
  ''',

  '''
  CREATE UNIQUE INDEX IF NOT EXISTS ${IconRefIndex.uniquePack.indexName}
  ON icon_refs(
    icon_pack_id,
    icon_value,
    COALESCE(color, ''),
    COALESCE(background_color, '')
  )
  WHERE icon_source_type = 'pack';
  ''',

  '''
  CREATE UNIQUE INDEX IF NOT EXISTS ${IconRefIndex.uniqueCustom.indexName}
  ON icon_refs(
    custom_icon_id,
    COALESCE(color, ''),
    COALESCE(background_color, '')
  )
  WHERE icon_source_type = 'custom';
  ''',
];

///ПРАВИЛО
///
//если icon_ref полностью совпадает по sourceType/iconPackId/iconKey/customIconId/color/backgroundColor
//→ переиспользовать существующий icon_ref
//если отличается хотя бы цвет
//→ создать новый icon_ref
