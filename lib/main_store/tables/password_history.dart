import 'package:drift/drift.dart';

import 'vault_item_history.dart';

/// History-таблица для специфичных полей пароля.
///
/// Каждая запись привязана к vault_item_history
/// через FK historyId → vault_item_history.id.
@DataClassName('PasswordHistoryData')
class PasswordHistory extends Table {
  /// PK и FK → vault_item_history.id ON DELETE CASCADE
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// Логин (snapshot)
  TextColumn get login => text().nullable()();

  /// Email (snapshot)
  TextColumn get email => text().nullable()();

  /// Пароль (snapshot, nullable для приватности)
  TextColumn get password => text().nullable()();

  /// URL (snapshot)
  TextColumn get url => text().nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'password_history';
}
