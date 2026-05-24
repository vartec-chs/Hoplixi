import 'package:drift/drift.dart';

import '../vault_items/vault_snapshots_history.dart';
import 'api_key_items.dart';

@DataClassName('ApiKeyHistoryData')
class ApiKeyHistory extends Table {
  /// PK и FK → vault_snapshots_history.id ON DELETE CASCADE.
  ///
  /// Один snapshot базового vault item имеет максимум одну
  /// snapshot-запись API key.
  TextColumn get historyId => text().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Название сервиса или приложения snapshot.
  TextColumn get service => text().withLength(min: 1, max: 255)();

  /// API key / token snapshot.
  ///
  /// Nullable intentionally:
  /// history may store metadata-only snapshots depending on secret history policy.
  TextColumn get key => text().nullable()();

  /// Тип токена snapshot.
  TextColumn get tokenType => textEnum<ApiKeyTokenType>().nullable()();

  /// Дополнительный тип токена, если tokenType = other.
  TextColumn get tokenTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Окружение snapshot.
  TextColumn get environment => textEnum<ApiKeyEnvironment>().nullable()();

  /// Дополнительное окружение, если environment = other.
  TextColumn get environmentOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Дата истечения срока действия snapshot.
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// Был ли ключ отозван на момент snapshot.
  BoolColumn get revoked => boolean().withDefault(const Constant(false))();

  /// Дата отзыва ключа snapshot.
  DateTimeColumn get revokedAt => dateTime().nullable()();

  /// Период ротации ключа в днях snapshot.
  IntColumn get rotationPeriodDays => integer().nullable()();

  /// Дата последней ротации ключа snapshot.
  DateTimeColumn get lastRotatedAt => dateTime().nullable()();

  /// Список разрешений API-ключа через один пробел.
  ///
  /// Формат:
  /// read write admin
  ///
  /// Без пробелов в начале/конце и без двойных пробелов.
  TextColumn get scopesText => text().nullable()();

  /// Владелец ключа / аккаунт / команда snapshot.
  TextColumn get owner => text().withLength(min: 1, max: 255).nullable()();

  /// Базовый URL сервиса или endpoint snapshot.
  TextColumn get baseUrl => text().withLength(min: 1, max: 2048).nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'api_key_history';

  @override
  List<String> get customConstraints => [
    '''
        CONSTRAINT ${ApiKeyHistoryConstraint.historyIdNotBlank.constraintName}
        CHECK (
          length(trim(history_id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyHistoryConstraint.serviceNotBlank.constraintName}
        CHECK (
          length(trim(service)) > 0
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyHistoryConstraint.serviceNoOuterWhitespace.constraintName}
        CHECK (
          service = trim(service)
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyHistoryConstraint.keyNotBlank.constraintName}
        CHECK (
          key IS NULL
          OR length(trim(key)) > 0
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyHistoryConstraint.keyNoOuterWhitespace.constraintName}
        CHECK (
          key IS NULL
          OR key = trim(key)
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyHistoryConstraint.tokenTypeOtherRequired.constraintName}
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
        CONSTRAINT ${ApiKeyHistoryConstraint.tokenTypeOtherMustBeNull.constraintName}
        CHECK (
          token_type = 'other'
          OR token_type_other IS NULL
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyHistoryConstraint.tokenTypeOtherNoOuterWhitespace.constraintName}
        CHECK (
          token_type_other IS NULL
          OR token_type_other = trim(token_type_other)
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyHistoryConstraint.environmentOtherRequired.constraintName}
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
        CONSTRAINT ${ApiKeyHistoryConstraint.environmentOtherMustBeNull.constraintName}
        CHECK (
          environment = 'other'
          OR environment_other IS NULL
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyHistoryConstraint.environmentOtherNoOuterWhitespace.constraintName}
        CHECK (
          environment_other IS NULL
          OR environment_other = trim(environment_other)
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyHistoryConstraint.revokedAtStateConsistent.constraintName}
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
        CONSTRAINT ${ApiKeyHistoryConstraint.rotationPeriodPositive.constraintName}
        CHECK (
          rotation_period_days IS NULL
          OR rotation_period_days > 0
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyHistoryConstraint.lastRotatedRequiresRotationPeriod.constraintName}
        CHECK (
          last_rotated_at IS NULL
          OR rotation_period_days IS NOT NULL
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyHistoryConstraint.scopesTextNotBlank.constraintName}
        CHECK (
          scopes_text IS NULL
          OR length(trim(scopes_text)) > 0
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyHistoryConstraint.scopesTextNoOuterWhitespace.constraintName}
        CHECK (
          scopes_text IS NULL
          OR scopes_text = trim(scopes_text)
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyHistoryConstraint.scopesTextNoDoubleSpaces.constraintName}
        CHECK (
          scopes_text IS NULL
          OR instr(scopes_text, '  ') = 0
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyHistoryConstraint.ownerNotBlank.constraintName}
        CHECK (
          owner IS NULL
          OR length(trim(owner)) > 0
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyHistoryConstraint.ownerNoOuterWhitespace.constraintName}
        CHECK (
          owner IS NULL
          OR owner = trim(owner)
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyHistoryConstraint.baseUrlNotBlank.constraintName}
        CHECK (
          base_url IS NULL
          OR length(trim(base_url)) > 0
        )
        ''',

    '''
        CONSTRAINT ${ApiKeyHistoryConstraint.baseUrlNoOuterWhitespace.constraintName}
        CHECK (
          base_url IS NULL
          OR base_url = trim(base_url)
        )
        ''',
  ];
}

enum ApiKeyHistoryConstraint {
  historyIdNotBlank('chk_api_key_history_history_id_not_blank'),

  serviceNotBlank('chk_api_key_history_service_not_blank'),

  serviceNoOuterWhitespace('chk_api_key_history_service_no_outer_whitespace'),

  keyNotBlank('chk_api_key_history_key_not_blank'),

  keyNoOuterWhitespace('chk_api_key_history_key_no_outer_whitespace'),

  tokenTypeOtherRequired('chk_api_key_history_token_type_other_required'),

  tokenTypeOtherMustBeNull('chk_api_key_history_token_type_other_must_be_null'),

  tokenTypeOtherNoOuterWhitespace(
    'chk_api_key_history_token_type_other_no_outer_whitespace',
  ),

  environmentOtherRequired('chk_api_key_history_environment_other_required'),

  environmentOtherMustBeNull(
    'chk_api_key_history_environment_other_must_be_null',
  ),

  environmentOtherNoOuterWhitespace(
    'chk_api_key_history_environment_other_no_outer_whitespace',
  ),

  revokedAtStateConsistent('chk_api_key_history_revoked_at_state_consistent'),

  rotationPeriodPositive('chk_api_key_history_rotation_period_positive'),

  lastRotatedRequiresRotationPeriod(
    'chk_api_key_history_last_rotated_requires_rotation_period',
  ),

  scopesTextNotBlank('chk_api_key_history_scopes_text_not_blank'),

  scopesTextNoOuterWhitespace(
    'chk_api_key_history_scopes_text_no_outer_whitespace',
  ),

  scopesTextNoDoubleSpaces('chk_api_key_history_scopes_text_no_double_spaces'),

  ownerNotBlank('chk_api_key_history_owner_not_blank'),

  ownerNoOuterWhitespace('chk_api_key_history_owner_no_outer_whitespace'),

  baseUrlNotBlank('chk_api_key_history_base_url_not_blank'),

  baseUrlNoOuterWhitespace('chk_api_key_history_base_url_no_outer_whitespace');

  const ApiKeyHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum ApiKeyHistoryIndex {
  service('idx_api_key_history_service'),

  tokenType('idx_api_key_history_token_type'),

  environment('idx_api_key_history_environment'),

  expiresAt('idx_api_key_history_expires_at'),

  revokedAt('idx_api_key_history_revoked_at'),

  rotationDue('idx_api_key_history_rotation_due'),

  owner('idx_api_key_history_owner');

  const ApiKeyHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> apiKeyHistoryTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${ApiKeyHistoryIndex.service.indexName}
  ON api_key_history(service);
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${ApiKeyHistoryIndex.tokenType.indexName}
  ON api_key_history(token_type)
  WHERE token_type IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${ApiKeyHistoryIndex.environment.indexName}
  ON api_key_history(environment)
  WHERE environment IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${ApiKeyHistoryIndex.expiresAt.indexName}
  ON api_key_history(expires_at)
  WHERE expires_at IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${ApiKeyHistoryIndex.revokedAt.indexName}
  ON api_key_history(revoked_at)
  WHERE revoked = 1 AND revoked_at IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${ApiKeyHistoryIndex.rotationDue.indexName}
  ON api_key_history(last_rotated_at, rotation_period_days)
  WHERE rotation_period_days IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${ApiKeyHistoryIndex.owner.indexName}
  ON api_key_history(owner)
  WHERE owner IS NOT NULL;
  ''',
];

enum ApiKeyHistoryTrigger {
  validateSnapshotTypeOnInsert(
    'trg_api_key_history_validate_snapshot_type_on_insert',
  ),

  preventUpdate('trg_api_key_history_prevent_update');

  const ApiKeyHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum ApiKeyHistoryRaise {
  invalidSnapshotType(
    'api_key_history.history_id must reference vault_snapshots_history.id with type = apiKey',
  ),

  historyIsImmutable('api_key_history rows are immutable');

  const ApiKeyHistoryRaise(this.message);

  final String message;
}

final List<String> apiKeyHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${ApiKeyHistoryTrigger.validateSnapshotTypeOnInsert.triggerName}
  BEFORE INSERT ON api_key_history
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_snapshots_history
    WHERE id = NEW.history_id
      AND type = 'apiKey'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${ApiKeyHistoryRaise.invalidSnapshotType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${ApiKeyHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON api_key_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${ApiKeyHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
