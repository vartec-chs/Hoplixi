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
  TextColumn get historyId => text().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Логин snapshot.
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

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'password_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${PasswordHistoryConstraint.historyIdNotBlank.constraintName}
    CHECK (
      length(trim(history_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${PasswordHistoryConstraint.loginNotBlank.constraintName}
    CHECK (
      login IS NULL
      OR length(trim(login)) > 0
    )
    ''',

    '''
    CONSTRAINT ${PasswordHistoryConstraint.loginNoOuterWhitespace.constraintName}
    CHECK (
      login IS NULL
      OR login = trim(login)
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
    CONSTRAINT ${PasswordHistoryConstraint.emailNoOuterWhitespace.constraintName}
    CHECK (
      email IS NULL
      OR email = trim(email)
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

    '''
    CONSTRAINT ${PasswordHistoryConstraint.urlNoOuterWhitespace.constraintName}
    CHECK (
      url IS NULL
      OR url = trim(url)
    )
    ''',
  ];
}

enum PasswordHistoryConstraint {
  historyIdNotBlank('chk_password_history_history_id_not_blank'),

  loginNotBlank('chk_password_history_login_not_blank'),

  loginNoOuterWhitespace('chk_password_history_login_no_outer_whitespace'),

  emailNotBlank('chk_password_history_email_not_blank'),

  emailNoOuterWhitespace('chk_password_history_email_no_outer_whitespace'),

  passwordNotBlank('chk_password_history_password_not_blank'),

  urlNotBlank('chk_password_history_url_not_blank'),

  urlNoOuterWhitespace('chk_password_history_url_no_outer_whitespace');

  const PasswordHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum PasswordHistoryIndex {
  login('idx_password_history_login'),
  email('idx_password_history_email'),
  url('idx_password_history_url'),
  expiresAt('idx_password_history_expires_at');

  const PasswordHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> passwordHistoryTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${PasswordHistoryIndex.login.indexName}
  ON password_history(login)
  WHERE login IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${PasswordHistoryIndex.email.indexName}
  ON password_history(email)
  WHERE email IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${PasswordHistoryIndex.url.indexName}
  ON password_history(url)
  WHERE url IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${PasswordHistoryIndex.expiresAt.indexName}
  ON password_history(expires_at)
  WHERE expires_at IS NOT NULL;
  ''',
];

enum PasswordHistoryTrigger {
  validateSnapshotTypeOnInsert(
    'trg_password_history_validate_snapshot_type_on_insert',
  ),

  preventUpdate('trg_password_history_prevent_update');

  const PasswordHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum PasswordHistoryRaise {
  invalidSnapshotType(
    'password_history.history_id must reference vault_snapshots_history.id with type = password',
  ),

  historyIsImmutable('password_history rows are immutable');

  const PasswordHistoryRaise(this.message);

  final String message;
}

final List<String> passwordHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${PasswordHistoryTrigger.validateSnapshotTypeOnInsert.triggerName}
  BEFORE INSERT ON password_history
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_snapshots_history
    WHERE id = NEW.history_id
      AND type = 'password'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${PasswordHistoryRaise.invalidSnapshotType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${PasswordHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON password_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${PasswordHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
