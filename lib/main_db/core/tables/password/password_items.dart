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

  /// Логин.
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

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'password_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${PasswordItemConstraint.itemIdNotBlank.constraintName}
    CHECK (
      length(trim(item_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${PasswordItemConstraint.loginNotBlank.constraintName}
    CHECK (
      login IS NULL
      OR length(trim(login)) > 0
    )
    ''',

    '''
    CONSTRAINT ${PasswordItemConstraint.loginNoOuterWhitespace.constraintName}
    CHECK (
      login IS NULL
      OR login = trim(login)
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
    CONSTRAINT ${PasswordItemConstraint.emailNoOuterWhitespace.constraintName}
    CHECK (
      email IS NULL
      OR email = trim(email)
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

    '''
    CONSTRAINT ${PasswordItemConstraint.urlNoOuterWhitespace.constraintName}
    CHECK (
      url IS NULL
      OR url = trim(url)
    )
    ''',
  ];
}

enum PasswordItemConstraint {
  itemIdNotBlank('chk_password_items_item_id_not_blank'),

  loginNotBlank('chk_password_items_login_not_blank'),

  loginNoOuterWhitespace('chk_password_items_login_no_outer_whitespace'),

  emailNotBlank('chk_password_items_email_not_blank'),

  emailNoOuterWhitespace('chk_password_items_email_no_outer_whitespace'),

  passwordNotBlank('chk_password_items_password_not_blank'),

  urlNotBlank('chk_password_items_url_not_blank'),

  urlNoOuterWhitespace('chk_password_items_url_no_outer_whitespace');

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
  '''
  CREATE INDEX IF NOT EXISTS ${PasswordItemIndex.login.indexName}
  ON password_items(login)
  WHERE login IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${PasswordItemIndex.email.indexName}
  ON password_items(email)
  WHERE email IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${PasswordItemIndex.url.indexName}
  ON password_items(url)
  WHERE url IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${PasswordItemIndex.expiresAt.indexName}
  ON password_items(expires_at)
  WHERE expires_at IS NOT NULL;
  ''',
];

enum PasswordItemTrigger {
  validateVaultItemTypeOnInsert(
    'trg_password_items_validate_vault_item_type_on_insert',
  ),

  validateVaultItemTypeOnUpdate(
    'trg_password_items_validate_vault_item_type_on_update',
  ),

  preventItemIdUpdate('trg_password_items_prevent_item_id_update');

  const PasswordItemTrigger(this.triggerName);

  final String triggerName;
}

enum PasswordItemRaise {
  invalidVaultItemType(
    'password_items.item_id must reference vault_items.id with type = password',
  ),

  itemIdImmutable('password_items.item_id is immutable');

  const PasswordItemRaise(this.message);

  final String message;
}

final List<String> passwordItemsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${PasswordItemTrigger.validateVaultItemTypeOnInsert.triggerName}
  BEFORE INSERT ON password_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'password'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${PasswordItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${PasswordItemTrigger.validateVaultItemTypeOnUpdate.triggerName}
  BEFORE UPDATE ON password_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'password'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${PasswordItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${PasswordItemTrigger.preventItemIdUpdate.triggerName}
  BEFORE UPDATE OF item_id ON password_items
  FOR EACH ROW
  WHEN NEW.item_id <> OLD.item_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${PasswordItemRaise.itemIdImmutable.message}'
    );
  END;
  ''',
];
