import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

enum ApiKeyEnvironment {
  development,
  staging,
  production,
  testing,
  local,
  other,
}

enum ApiKeyTokenType { apiKey, bearer, jwt, pat, webhook, other }

@DataClassName('ApiKeyItemsData')
class ApiKeyItems extends Table {
  /// PK и FK → vault_items.id ON DELETE CASCADE.
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Название сервиса или приложения.
  TextColumn get service => text().withLength(min: 1, max: 255)();

  /// Сам API key / token.
  ///
  /// Секретное значение внутри зашифрованной БД.
  TextColumn get key => text()();

  /// Тип токена.
  TextColumn get tokenType => textEnum<ApiKeyTokenType>().nullable()();

  /// Дополнительный тип токена, если tokenType = other.
  TextColumn get tokenTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Окружение, где используется ключ.
  TextColumn get environment => textEnum<ApiKeyEnvironment>().nullable()();

  /// Дополнительное окружение, если environment = other.
  TextColumn get environmentOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Дата истечения срока действия ключа.
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// Флаг отозванного ключа.
  BoolColumn get revoked => boolean().withDefault(const Constant(false))();

  /// Дата отзыва ключа.
  DateTimeColumn get revokedAt => dateTime().nullable()();

  /// Период ротации ключа в днях.
  IntColumn get rotationPeriodDays => integer().nullable()();

  /// Дата последней ротации ключа.
  DateTimeColumn get lastRotatedAt => dateTime().nullable()();

  /// Владелец ключа / аккаунт / команда.
  TextColumn get owner => text().withLength(min: 1, max: 255).nullable()();

  /// Базовый URL сервиса или endpoint.
  TextColumn get baseUrl => text().withLength(min: 1, max: 2048).nullable()();

  /// Список разрешений API-ключа через один пробел.
  ///
  /// Формат:
  /// - scopes разделяются одним пробелом;
  /// - без пробелов в начале и конце;
  /// - без двойных пробелов;
  /// - уникальность scopes проверяется в приложении.
  ///
  /// Пример:
  /// read write admin
  TextColumn get scopesText => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'api_key_items';

  @override
  List<String> get customConstraints => [
    '''
        CONSTRAINT ${ApiKeyItemConstraint.itemIdNotBlank.constraintName}
        CHECK (
          length(trim(item_id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyItemConstraint.serviceNotBlank.constraintName}
        CHECK (
          length(trim(service)) > 0
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyItemConstraint.serviceNoOuterWhitespace.constraintName}
        CHECK (
          service = trim(service)
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyItemConstraint.keyNotBlank.constraintName}
        CHECK (
          length(trim(key)) > 0
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyItemConstraint.keyNoOuterWhitespace.constraintName}
        CHECK (
          key = trim(key)
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyItemConstraint.tokenTypeOtherRequired.constraintName}
        CHECK (
          token_type IS NULL
          OR token_type != 'other'
          OR (
            token_type_other IS NOT NULL
            AND length(trim(token_type_other)) > 0
          )
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyItemConstraint.tokenTypeOtherMustBeNull.constraintName}
        CHECK (
          token_type = 'other'
          OR token_type_other IS NULL
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyItemConstraint.tokenTypeOtherNoOuterWhitespace.constraintName}
        CHECK (
          token_type_other IS NULL
          OR token_type_other = trim(token_type_other)
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyItemConstraint.environmentOtherRequired.constraintName}
        CHECK (
          environment IS NULL
          OR environment != 'other'
          OR (
            environment_other IS NOT NULL
            AND length(trim(environment_other)) > 0
          )
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyItemConstraint.environmentOtherMustBeNull.constraintName}
        CHECK (
          environment = 'other'
          OR environment_other IS NULL
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyItemConstraint.environmentOtherNoOuterWhitespace.constraintName}
        CHECK (
          environment_other IS NULL
          OR environment_other = trim(environment_other)
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyItemConstraint.revokedAtStateConsistent.constraintName}
        CHECK (
          (
            revoked = 0
            AND revoked_at IS NULL
          )
          OR
          (
            revoked = 1
            AND revoked_at IS NOT NULL
          )
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyItemConstraint.rotationPeriodPositive.constraintName}
        CHECK (
          rotation_period_days IS NULL
          OR rotation_period_days > 0
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyItemConstraint.lastRotatedRequiresRotationPeriod.constraintName}
        CHECK (
          last_rotated_at IS NULL
          OR rotation_period_days IS NOT NULL
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyItemConstraint.ownerNotBlank.constraintName}
        CHECK (
          owner IS NULL
          OR length(trim(owner)) > 0
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyItemConstraint.ownerNoOuterWhitespace.constraintName}
        CHECK (
          owner IS NULL
          OR owner = trim(owner)
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyItemConstraint.baseUrlNotBlank.constraintName}
        CHECK (
          base_url IS NULL
          OR length(trim(base_url)) > 0
        )
        ''',

    '''
    CONSTRAINT ${ApiKeyItemConstraint.scopesTextNotBlank.constraintName}
    CHECK (
      scopes_text IS NULL
      OR length(trim(scopes_text)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ApiKeyItemConstraint.scopesTextNoOuterWhitespace.constraintName}
    CHECK (
      scopes_text IS NULL
      OR scopes_text = trim(scopes_text)
    )
    ''',

    '''
    CONSTRAINT ${ApiKeyItemConstraint.scopesTextNoDoubleSpaces.constraintName}
    CHECK (
      scopes_text IS NULL
      OR instr(scopes_text, '  ') = 0
    )
    ''',

    '''
        CONSTRAINT ${ApiKeyItemConstraint.baseUrlNoOuterWhitespace.constraintName}
        CHECK (
          base_url IS NULL
          OR base_url = trim(base_url)
        )
        ''',
  ];
}

enum ApiKeyItemConstraint {
  itemIdNotBlank('chk_api_key_items_item_id_not_blank'),

  serviceNotBlank('chk_api_key_items_service_not_blank'),

  serviceNoOuterWhitespace('chk_api_key_items_service_no_outer_whitespace'),

  keyNotBlank('chk_api_key_items_key_not_blank'),

  scopesTextNotBlank('chk_api_key_items_scopes_text_not_blank'),

  scopesTextNoOuterWhitespace(
    'chk_api_key_items_scopes_text_no_outer_whitespace',
  ),

  scopesTextNoDoubleSpaces('chk_api_key_items_scopes_text_no_double_spaces'),

  keyNoOuterWhitespace('chk_api_key_items_key_no_outer_whitespace'),

  tokenTypeOtherRequired('chk_api_key_items_token_type_other_required'),

  tokenTypeOtherMustBeNull('chk_api_key_items_token_type_other_must_be_null'),

  tokenTypeOtherNoOuterWhitespace(
    'chk_api_key_items_token_type_other_no_outer_whitespace',
  ),

  environmentOtherRequired('chk_api_key_items_environment_other_required'),

  environmentOtherMustBeNull(
    'chk_api_key_items_environment_other_must_be_null',
  ),

  environmentOtherNoOuterWhitespace(
    'chk_api_key_items_environment_other_no_outer_whitespace',
  ),

  revokedAtStateConsistent('chk_api_key_items_revoked_at_state_consistent'),

  rotationPeriodPositive('chk_api_key_items_rotation_period_positive'),

  lastRotatedRequiresRotationPeriod(
    'chk_api_key_items_last_rotated_requires_rotation_period',
  ),

  ownerNotBlank('chk_api_key_items_owner_not_blank'),

  ownerNoOuterWhitespace('chk_api_key_items_owner_no_outer_whitespace'),

  baseUrlNotBlank('chk_api_key_items_base_url_not_blank'),

  baseUrlNoOuterWhitespace('chk_api_key_items_base_url_no_outer_whitespace');

  const ApiKeyItemConstraint(this.constraintName);

  final String constraintName;
}

enum ApiKeyItemIndex {
  service('idx_api_key_items_service'),

  tokenType('idx_api_key_items_token_type'),

  environment('idx_api_key_items_environment'),

  expiresAt('idx_api_key_items_expires_at'),

  revokedAt('idx_api_key_items_revoked_at'),

  rotationDue('idx_api_key_items_rotation_due'),

  owner('idx_api_key_items_owner');

  const ApiKeyItemIndex(this.indexName);

  final String indexName;
}

final List<String> apiKeyItemsTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${ApiKeyItemIndex.service.indexName}
  ON api_key_items(service);
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${ApiKeyItemIndex.tokenType.indexName}
  ON api_key_items(token_type)
  WHERE token_type IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${ApiKeyItemIndex.environment.indexName}
  ON api_key_items(environment)
  WHERE environment IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${ApiKeyItemIndex.expiresAt.indexName}
  ON api_key_items(expires_at)
  WHERE expires_at IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${ApiKeyItemIndex.revokedAt.indexName}
  ON api_key_items(revoked_at)
  WHERE revoked = 1 AND revoked_at IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${ApiKeyItemIndex.rotationDue.indexName}
  ON api_key_items(last_rotated_at, rotation_period_days)
  WHERE rotation_period_days IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${ApiKeyItemIndex.owner.indexName}
  ON api_key_items(owner)
  WHERE owner IS NOT NULL;
  ''',
];

enum ApiKeyItemTrigger {
  validateVaultItemTypeOnInsert(
    'trg_api_key_items_validate_vault_item_type_on_insert',
  ),

  validateVaultItemTypeOnUpdate(
    'trg_api_key_items_validate_vault_item_type_on_update',
  ),

  preventItemIdUpdate('trg_api_key_items_prevent_item_id_update');

  const ApiKeyItemTrigger(this.triggerName);

  final String triggerName;
}

enum ApiKeyItemRaise {
  invalidVaultItemType(
    'api_key_items.item_id must reference vault_items.id with type = apiKey',
  ),

  itemIdImmutable('api_key_items.item_id is immutable');

  const ApiKeyItemRaise(this.message);

  final String message;
}

final List<String> apiKeyItemsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${ApiKeyItemTrigger.validateVaultItemTypeOnInsert.triggerName}
  BEFORE INSERT ON api_key_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'apiKey'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${ApiKeyItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${ApiKeyItemTrigger.validateVaultItemTypeOnUpdate.triggerName}
  BEFORE UPDATE ON api_key_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'apiKey'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${ApiKeyItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${ApiKeyItemTrigger.preventItemIdUpdate.triggerName}
  BEFORE UPDATE OF item_id ON api_key_items
  FOR EACH ROW
  WHEN NEW.item_id <> OLD.item_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${ApiKeyItemRaise.itemIdImmutable.message}'
    );
  END;
  ''',
];
