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
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  // Название сервиса или приложения, для которого предназначен этот API-ключ. Это может помочь пользователю быстро идентифицировать назначение ключа.
  TextColumn get service => text().withLength(min: 1, max: 255)();

  // Сам ключ
  TextColumn get key => text()();

  // Тип токена может быть полезен для отображения и фильтрации ключей в UI, а также для предоставления пользователю информации о том, какой тип аутентификации используется этим ключом.
  TextColumn get tokenType => textEnum<ApiKeyTokenType>().nullable()();

  // Дополнительный тип токена, который не входит в предопределенные значения.
  TextColumn get tokenTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  // Может быть полезно для указания, в каком окружении используется этот API-ключ (например, "production", "staging", "development"), что может помочь пользователю быстро идентифицировать назначение ключа.
  TextColumn get environment => textEnum<ApiKeyEnvironment>().nullable()();

  // Дополнительный тип окружения, который не входит в предопределенные значения.
  TextColumn get environmentOther =>
      text().withLength(min: 1, max: 255).nullable()();

  // Дата истечения срока действия ключа. Это может быть полезно для автоматического напоминания пользователю о необходимости обновления ключа и для фильтрации активных/неактивных ключей.
  DateTimeColumn get expiresAt => dateTime().nullable()();

  // Флаг, указывающий, был ли ключ отозван. Это может быть полезно для отображения статуса ключа в UI и для фильтрации активных/неактивных ключей.
  BoolColumn get revoked => boolean().withDefault(const Constant(false))();

  // Период ротации ключа в днях. Может быть полезно для автоматического напоминания о необходимости обновления ключа.
  IntColumn get rotationPeriodDays => integer().nullable()();

  // Дата последней ротации ключа. Может быть полезно для отслеживания, когда ключ был в последний раз обновлен.
  DateTimeColumn get lastRotatedAt => dateTime().nullable()();

  // Список разрешений, связанных с этим API-ключом (например, "read", "write", "admin") JSON array string
  TextColumn get scopes => text().nullable()();

  // Может быть полезно для отображения информации о том, кто создал API-ключ или кому он принадлежит
  TextColumn get owner => text().withLength(min: 1, max: 255).nullable()();

  // Базовый URL или идентификатор сервиса, к которому относится этот API-ключ (например, "GitHub", "AWS", "Stripe")
  TextColumn get baseUrl => text().withLength(min: 1, max: 2048).nullable()();

  // Дополнительные метаданные в виде JSON-строки (например, IP-ограничения, описание использования и т.д.)
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'api_key_items';

  @override
  List<String> get customConstraints => [
    '''
  CONSTRAINT ${ApiKeyItemConstraint.tokenTypeOtherRequired.constraintName}
  CHECK (
    token_type != 'other'
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
  CONSTRAINT ${ApiKeyItemConstraint.environmentOtherRequired.constraintName}
  CHECK (
    environment != 'other'
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
    CONSTRAINT ${ApiKeyItemConstraint.serviceNotBlank.constraintName}
    CHECK (
      length(trim(service)) > 0
    )
  ''',
    '''
  CONSTRAINT ${ApiKeyItemConstraint.rotationPeriodPositive.constraintName}
  CHECK (
    rotation_period_days IS NULL
    OR rotation_period_days > 0
  )
  ''',
  ];
}

enum ApiKeyItemConstraint {
  // Эти ограничения обеспечивают целостность данных, гарантируя, что если тип токена или окружения установлен как "other", то соответствующее поле с дополнительной информацией должно быть заполнено, и наоборот. Также проверяется, что период ротации ключа, если он указан, является положительным числом.
  tokenTypeOtherRequired('chk_api_key_token_type_other_required'),

  // Гарантирует, что если тип токена не "other", то поле token_type_other должно быть NULL, предотвращая наличие противоречивых данных.
  tokenTypeOtherMustBeNull('chk_api_key_token_type_other_must_be_null'),

  // Гарантирует, что если окружение установлено как "other", то поле environment_other должно быть заполнено, обеспечивая целостность данных.
  environmentOtherRequired('chk_api_key_environment_other_required'),

  // Гарантирует, что если окружение не "other", то поле environment_other должно быть NULL, предотвращая наличие противоречивых данных.
  environmentOtherMustBeNull('chk_api_key_environment_other_must_be_null'),

  // Обеспечивает, что поле service не является пустой строкой или строкой, состоящей только из пробелов, что гарантирует наличие полезной информации о том, для какого сервиса предназначен этот API-ключ.
  serviceNotBlank('chk_api_key_service_not_blank'),

  // Обеспечивает, что если период ротации ключа указан, он должен быть положительным числом, что имеет смысл с точки зрения логики ротации ключей.
  rotationPeriodPositive('chk_api_key_rotation_period_positive');

  const ApiKeyItemConstraint(this.constraintName);

  final String constraintName;
}

enum ApiKeyItemIndex {
  service('idx_api_key_items_service'),
  tokenType('idx_api_key_items_token_type'),
  environment('idx_api_key_items_environment'),
  expiresAt('idx_api_key_items_expires_at'),
  revoked('idx_api_key_items_revoked');

  const ApiKeyItemIndex(this.indexName);

  final String indexName;
}

final List<String> apiKeyItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${ApiKeyItemIndex.service.indexName} ON api_key_items(service);',
  'CREATE INDEX IF NOT EXISTS ${ApiKeyItemIndex.tokenType.indexName} ON api_key_items(token_type);',
  'CREATE INDEX IF NOT EXISTS ${ApiKeyItemIndex.environment.indexName} ON api_key_items(environment);',
  'CREATE INDEX IF NOT EXISTS ${ApiKeyItemIndex.expiresAt.indexName} ON api_key_items(expires_at);',
  'CREATE INDEX IF NOT EXISTS ${ApiKeyItemIndex.revoked.indexName} ON api_key_items(revoked);',
];
