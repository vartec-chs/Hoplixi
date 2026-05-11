import 'package:drift/drift.dart';

import 'api_key_items.dart';
import '../vault_items/vault_item_history.dart';

@DataClassName('ApiKeyHistoryData')
class ApiKeyHistory extends Table {
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  TextColumn get service => text().withLength(min: 1, max: 255)();

  /// Nullable intentionally:
  /// history may store metadata-only snapshots depending on secret history policy.
  TextColumn get key => text().nullable()();

  TextColumn get tokenType => textEnum<ApiKeyTokenType>().nullable()();

  TextColumn get tokenTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  TextColumn get environment => textEnum<ApiKeyEnvironment>().nullable()();

  TextColumn get environmentOther =>
      text().withLength(min: 1, max: 255).nullable()();

  DateTimeColumn get expiresAt => dateTime().nullable()();

  BoolColumn get revoked => boolean().withDefault(const Constant(false))();

  IntColumn get rotationPeriodDays => integer().nullable()();

  DateTimeColumn get lastRotatedAt => dateTime().nullable()();

  /// JSON array string snapshot.
  TextColumn get scopes => text().nullable()();

  TextColumn get owner => text().withLength(min: 1, max: 255).nullable()();

  TextColumn get baseUrl => text().withLength(min: 1, max: 2048).nullable()();

  /// JSON object string snapshot.
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'api_key_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${ApiKeyHistoryConstraint.tokenTypeOtherRequired.constraintName}
    CHECK (
      token_type != 'other'
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
    CONSTRAINT ${ApiKeyHistoryConstraint.environmentOtherRequired.constraintName}
    CHECK (
      environment != 'other'
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
    CONSTRAINT ${ApiKeyHistoryConstraint.serviceNotBlank.constraintName}
    CHECK (
      length(trim(service)) > 0
    )
    ''',
    '''
    CONSTRAINT ${ApiKeyHistoryConstraint.rotationPeriodPositive.constraintName}
    CHECK (
      rotation_period_days IS NULL
      OR rotation_period_days > 0
    )
    ''',
  ];
}

enum ApiKeyHistoryConstraint {
  tokenTypeOtherRequired('chk_api_key_history_token_type_other_required'),
  tokenTypeOtherMustBeNull('chk_api_key_history_token_type_other_must_be_null'),
  environmentOtherRequired('chk_api_key_history_environment_other_required'),
  environmentOtherMustBeNull(
    'chk_api_key_history_environment_other_must_be_null',
  ),
  serviceNotBlank('chk_api_key_history_service_not_blank'),
  rotationPeriodPositive('chk_api_key_history_rotation_period_positive');

  const ApiKeyHistoryConstraint(this.constraintName);

  final String constraintName;
}

const List<String> apiKeyHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS idx_api_key_history_service ON api_key_history(service);',
  'CREATE INDEX IF NOT EXISTS idx_api_key_history_token_type ON api_key_history(token_type);',
  'CREATE INDEX IF NOT EXISTS idx_api_key_history_environment ON api_key_history(environment);',
  'CREATE INDEX IF NOT EXISTS idx_api_key_history_expires_at ON api_key_history(expires_at);',
  'CREATE INDEX IF NOT EXISTS idx_api_key_history_revoked ON api_key_history(revoked);',
];
