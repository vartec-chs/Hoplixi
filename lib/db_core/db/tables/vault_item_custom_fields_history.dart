import 'package:drift/drift.dart';
import 'package:hoplixi/db_core/old/models/enums/index.dart';
import 'package:uuid/uuid.dart';

import 'vault_item_history.dart';

/// Таблица истории кастомных полей.
///
/// Каждая запись привязана к [VaultItemHistory] через [historyId].
/// Одна запись истории может содержать **несколько** строк
/// (по одной на каждое кастомное поле vault item на момент действия).
@DataClassName('VaultItemCustomFieldsHistoryData')
class VaultItemCustomFieldsHistory extends Table {
  /// Уникальный идентификатор строки истории (UUID v4)
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// FK → vault_item_history.id ON DELETE CASCADE
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// Оригинальный ID кастомного поля (без FK — поле может быть удалено)
  TextColumn get fieldId => text()();

  /// Название поля (snapshot)
  TextColumn get label => text().withLength(min: 1, max: 255)();

  /// Значение поля (snapshot, nullable)
  TextColumn get value => text().nullable()();

  /// Тип поля (snapshot)
  TextColumn get fieldType =>
      textEnum<CustomFieldType>().withDefault(const Constant('text'))();

  /// Порядок отображения (snapshot)
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'vault_item_custom_fields_history';
}
