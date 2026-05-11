import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

/// Type-specific таблица для паролей.
///
/// Содержит только поля, специфичные для пароля.
/// Общие поля: name, description, categoryId, isFavorite и т.д.
/// хранятся в vault_items.
@DataClassName('PasswordItemsData')
class PasswordItems extends Table {
  /// PK и FK → vault_items.id ON DELETE CASCADE.
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Логин / username.
  TextColumn get login => text().withLength(min: 1, max: 255).nullable()();

  /// Email.
  TextColumn get email => text().withLength(min: 1, max: 320).nullable()();

  /// Пароль.
  ///
  /// Секретное значение. Не ограничиваем длину:
  /// пользователь может хранить passphrase, token, recovery string и т.д.
  TextColumn get password => text()();

  /// URL сервиса.
  TextColumn get url => text().withLength(min: 1, max: 2048).nullable()();

  /// Дата истечения срока действия пароля.
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// Дополнительные метаданные в JSON-формате.
  ///
  /// Например: passwordStrength, breachCheckAt, importedFrom,
  /// passwordGeneratorProfile, oldUrlAliases.
  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'password_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${PasswordItemConstraint.loginNotBlank.constraintName}
    CHECK (
      login IS NULL
      OR length(trim(login)) > 0
    )
    ''',

    '''
    CONSTRAINT ${PasswordItemConstraint.emailNotBlank.constraintName}
    CHECK (
      email IS NULL
      OR length(trim(email)) > 0
    )
    ''',

    '''
    CONSTRAINT ${PasswordItemConstraint.passwordNotBlank.constraintName}
    CHECK (
      length(trim(password)) > 0
    )
    ''',

    '''
    CONSTRAINT ${PasswordItemConstraint.urlNotBlank.constraintName}
    CHECK (
      url IS NULL
      OR length(trim(url)) > 0
    )
    ''',
  ];
}

enum PasswordItemConstraint {
  loginNotBlank('chk_password_items_login_not_blank'),

  emailNotBlank('chk_password_items_email_not_blank'),

  passwordNotBlank('chk_password_items_password_not_blank'),

  urlNotBlank('chk_password_items_url_not_blank');

  const PasswordItemConstraint(this.constraintName);

  final String constraintName;
}

enum PasswordItemIndex {
  login('idx_password_items_login'),
  email('idx_password_items_email'),
  url('idx_password_items_url'),
  expiresAt('idx_password_items_expires_at');

  const PasswordItemIndex(this.indexName);

  final String indexName;
}

final List<String> passwordItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${PasswordItemIndex.login.indexName} ON password_items(login);',
  'CREATE INDEX IF NOT EXISTS ${PasswordItemIndex.email.indexName} ON password_items(email);',
  'CREATE INDEX IF NOT EXISTS ${PasswordItemIndex.url.indexName} ON password_items(url);',
  'CREATE INDEX IF NOT EXISTS ${PasswordItemIndex.expiresAt.indexName} ON password_items(expires_at);',
];
