import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:uuid/uuid.dart';

import 'categories.dart';

/// Базовая таблица для всех элементов хранилища.
///
/// Содержит ТОЛЬКО общие поля, присутствующие у всех
/// типов сущностей. Специфичные поля хранятся
/// в type-specific таблицах (password_items, otp_items и т.д.)
/// с FK → vault_items.id ON DELETE CASCADE.
@DataClassName('VaultItemsData')
class VaultItems extends Table {
  /// Уникальный идентификатор элемента (UUID v4)
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Тип элемента (password, otp, note, bankCard и т.д.)
  TextColumn get type => textEnum<VaultItemType>()();

  /// Отображаемое имя элемента
  TextColumn get name => text().withLength(min: 1, max: 255)();

  /// Описание элемента
  TextColumn get description => text().nullable()();

  /// Ссылка на категорию
  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Ссылка на связанную заметку
  TextColumn get noteId => text().nullable()();

  /// Количество использований
  IntColumn get usedCount => integer().withDefault(const Constant(0))();

  /// Флаг избранного
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// Флаг архивации
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// Флаг закрепления
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  /// Флаг мягкого удаления
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// Дата создания
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  /// Дата последнего изменения
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  /// EWMA-скор для сортировки по недавности
  RealColumn get recentScore => real().nullable()();

  /// Дата последнего использования
  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'vault_items';
}
