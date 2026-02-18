import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:uuid/uuid.dart';

/// Базовая таблица истории изменений элементов хранилища.
///
/// Содержит общие поля, которые были у vault_items
/// на момент действия (snapshot). Специфичные поля
/// хранятся в type-specific history-таблицах
/// (password_history, otp_history и т.д.)
/// с FK → vault_item_history.id ON DELETE CASCADE.
@DataClassName('VaultItemHistoryData')
class VaultItemHistory extends Table {
  /// Уникальный идентификатор записи истории (UUID v4)
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// ID оригинального элемента (без FK — элемент может
  /// быть удалён)
  TextColumn get itemId => text()();

  /// Тип элемента
  TextColumn get type => textEnum<VaultItemType>()();

  /// Имя элемента на момент действия
  TextColumn get name => text().withLength(min: 1, max: 255)();

  /// Описание элемента на момент действия
  TextColumn get description => text().nullable()();

  /// ID категории на момент действия
  TextColumn get categoryId => text().nullable()();

  /// Имя категории на момент действия
  TextColumn get categoryName => text().nullable()();

  /// Действие (created / modified / deleted)
  TextColumn get action => textEnum<ActionInHistory>()();

  /// Количество использований на момент действия
  IntColumn get usedCount => integer().withDefault(const Constant(0))();

  /// Флаг избранного
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// Флаг архивации
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// Флаг закрепления
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  /// Флаг мягкого удаления
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// EWMA-скор (snapshot)
  RealColumn get recentScore => real().nullable()();

  /// Дата последнего использования (snapshot)
  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  /// Оригинальная дата создания элемента
  DateTimeColumn get originalCreatedAt => dateTime().nullable()();

  /// Оригинальная дата модификации элемента
  DateTimeColumn get originalModifiedAt => dateTime().nullable()();

  /// Когда было выполнено действие
  DateTimeColumn get actionAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'vault_item_history';
}
