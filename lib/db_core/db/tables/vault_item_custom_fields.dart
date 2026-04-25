import 'package:drift/drift.dart';
import 'package:hoplixi/db_core/old/models/enums/index.dart';
import 'package:uuid/uuid.dart';

import 'vault_items.dart';

/// Таблица кастомных полей для элементов хранилища.
///
/// Позволяет пользователям добавлять произвольные поля
/// к любому vault item. Поля упорядочены по [sortOrder].
/// Чувствительные значения (тип [CustomFieldType.concealed])
/// хранятся в зашифрованном виде в [value].
@DataClassName('VaultItemCustomFieldsData')
class VaultItemCustomFields extends Table {
  /// Уникальный идентификатор кастомного поля (UUID v4)
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// FK → vault_items.id ON DELETE CASCADE
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Отображаемое название поля (например: «PIN», «Recovery URL»)
  TextColumn get label => text().withLength(min: 1, max: 255)();

  /// Значение поля. Для [CustomFieldType.concealed] хранится зашифрованным.
  TextColumn get value => text().nullable()();

  /// Тип поля: text | concealed | url | email | phone | date
  TextColumn get fieldType =>
      textEnum<CustomFieldType>().withDefault(const Constant('text'))();

  /// Порядок отображения поля (0-based, ascending)
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'vault_item_custom_fields';
}
