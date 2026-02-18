import 'package:drift/drift.dart';

import 'vault_items.dart';

/// Type-specific таблица для паролей.
///
/// Содержит ТОЛЬКО поля, специфичные для пароля.
/// Общие поля (name, categoryId, isFavorite и т.д.)
/// хранятся в vault_items.
@DataClassName('PasswordItemsData')
class PasswordItems extends Table {
  /// PK и FK → vault_items.id ON DELETE CASCADE
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Логин (username)
  TextColumn get login => text().nullable()();

  /// Email
  TextColumn get email => text().nullable()();

  /// Зашифрованный пароль
  TextColumn get password => text()();

  /// URL сервиса
  TextColumn get url => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'password_items';

  @override
  List<String> get customConstraints => [
    'CHECK (login IS NOT NULL OR email IS NOT NULL)',
  ];
}
