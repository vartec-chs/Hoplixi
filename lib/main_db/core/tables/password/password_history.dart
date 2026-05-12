import 'package:drift/drift.dart';

import '../vault_items/vault_snapshots_history.dart';

/// History-таблица для специфичных полей пароля.
///
/// Данные вставляются только триггерами.
/// Секретное поле password может быть NULL,
/// если включён режим истории без сохранения секретов.
@DataClassName('PasswordHistoryData')
class PasswordHistory extends Table {
  /// PK и FK → vault_snapshots_history.id ON DELETE CASCADE.
  TextColumn get historyId =>
      text().references(VaultSnapshotsHistory, #id, onDelete: KeyAction.cascade)();

  /// Логин / username snapshot.
  TextColumn get login => text().withLength(min: 1, max: 255).nullable()();

  /// Email snapshot.
  TextColumn get email => text().withLength(min: 1, max: 320).nullable()();

  /// Пароль snapshot.
  ///
  /// Nullable intentionally:
  /// history may store metadata-only snapshots depending on secret history policy.
  TextColumn get password => text().nullable()();

  /// URL сервиса snapshot.
  TextColumn get url => text().withLength(min: 1, max: 2048).nullable()();

  /// Дата истечения срока действия пароля snapshot.
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// UUID снимка для группировки связанных записей.
  TextColumn get snapshotId => text().nullable()();

  /// Дополнительные метаданные snapshot.
  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'password_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${PasswordHistoryConstraint.loginNotBlank.constraintName}
    CHECK (
      login IS NULL
      OR length(trim(login)) > 0
    )
    ''',

    '''
    CONSTRAINT ${PasswordHistoryConstraint.emailNotBlank.constraintName}
    CHECK (
      email IS NULL
      OR length(trim(email)) > 0
    )
    ''',

    '''
    CONSTRAINT ${PasswordHistoryConstraint.passwordNotBlank.constraintName}
    CHECK (
      password IS NULL
      OR length(trim(password)) > 0
    )
    ''',

    '''
    CONSTRAINT ${PasswordHistoryConstraint.urlNotBlank.constraintName}
    CHECK (
      url IS NULL
      OR length(trim(url)) > 0
    )
    ''',
  ];
}

enum PasswordHistoryConstraint {
  loginNotBlank('chk_password_history_login_not_blank'),

  emailNotBlank('chk_password_history_email_not_blank'),

  passwordNotBlank('chk_password_history_password_not_blank'),

  urlNotBlank('chk_password_history_url_not_blank');

  const PasswordHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum PasswordHistoryIndex {
  snapshotId('idx_password_history_snapshot_id'),
  login('idx_password_history_login'),
  email('idx_password_history_email'),
  url('idx_password_history_url'),
  expiresAt('idx_password_history_expires_at');

  const PasswordHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> passwordHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${PasswordHistoryIndex.snapshotId.indexName} ON password_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS ${PasswordHistoryIndex.login.indexName} ON password_history(login);',
  'CREATE INDEX IF NOT EXISTS ${PasswordHistoryIndex.email.indexName} ON password_history(email);',
  'CREATE INDEX IF NOT EXISTS ${PasswordHistoryIndex.url.indexName} ON password_history(url);',
  'CREATE INDEX IF NOT EXISTS ${PasswordHistoryIndex.expiresAt.indexName} ON password_history(expires_at);',
];
