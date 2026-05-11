import 'package:drift/drift.dart';

import '../vault_items/vault_item_history.dart';
import 'license_key_items.dart';

/// History-таблица для специфичных полей лицензионного ключа.
///
/// Данные вставляются только триггерами.
/// Секретное поле licenseKey может быть NULL,
/// если включён режим истории без сохранения секретов.
@DataClassName('LicenseKeyHistoryData')
class LicenseKeyHistory extends Table {
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// Продукт/приложение snapshot.
  TextColumn get product => text().withLength(min: 1, max: 255)();

  /// Лицензионный ключ snapshot.
  ///
  /// Nullable intentionally:
  /// history may store metadata-only snapshots depending on secret history policy.
  TextColumn get licenseKey => text().nullable()();

  /// Тип лицензии snapshot.
  TextColumn get licenseType => textEnum<LicenseType>().nullable()();

  /// Дополнительный тип лицензии, если licenseType = other.
  TextColumn get licenseTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Количество мест/пользователей snapshot.
  IntColumn get seats => integer().nullable()();

  /// Максимальное количество активаций snapshot.
  IntColumn get maxActivations => integer().nullable()();

  /// Дата активации snapshot.
  DateTimeColumn get activatedOn => dateTime().nullable()();

  /// Дата покупки snapshot.
  DateTimeColumn get purchaseDate => dateTime().nullable()();

  /// Где куплено snapshot.
  TextColumn get purchaseFrom =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Номер заказа/чека/инвойса snapshot.
  TextColumn get orderId => text().withLength(min: 1, max: 255).nullable()();

  /// Дата окончания действия лицензии snapshot.
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// Контакт поддержки snapshot.
  TextColumn get supportContact =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Дополнительные метаданные snapshot.
  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'license_key_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.productNotBlank.constraintName}
    CHECK (
      length(trim(product)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.licenseKeyNotBlank.constraintName}
    CHECK (
      license_key IS NULL
      OR length(trim(license_key)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.licenseTypeOtherRequired.constraintName}
    CHECK (
      license_type IS NULL
      OR license_type != 'other'
      OR (
        license_type_other IS NOT NULL
        AND length(trim(license_type_other)) > 0
      )
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.licenseTypeOtherMustBeNull.constraintName}
    CHECK (
      license_type = 'other'
      OR license_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.seatsPositive.constraintName}
    CHECK (
      seats IS NULL
      OR seats > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.maxActivationsPositive.constraintName}
    CHECK (
      max_activations IS NULL
      OR max_activations > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.purchaseFromNotBlank.constraintName}
    CHECK (
      purchase_from IS NULL
      OR length(trim(purchase_from)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.orderIdNotBlank.constraintName}
    CHECK (
      order_id IS NULL
      OR length(trim(order_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.supportContactNotBlank.constraintName}
    CHECK (
      support_contact IS NULL
      OR length(trim(support_contact)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.purchaseActivationRange.constraintName}
    CHECK (
      purchase_date IS NULL
      OR activated_on IS NULL
      OR purchase_date <= activated_on
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.purchaseExpiryRange.constraintName}
    CHECK (
      purchase_date IS NULL
      OR expires_at IS NULL
      OR purchase_date <= expires_at
    )
    ''',
  ];
}

enum LicenseKeyHistoryConstraint {
  productNotBlank('chk_license_key_history_product_not_blank'),

  licenseKeyNotBlank('chk_license_key_history_license_key_not_blank'),

  licenseTypeOtherRequired(
    'chk_license_key_history_license_type_other_required',
  ),

  licenseTypeOtherMustBeNull(
    'chk_license_key_history_license_type_other_must_be_null',
  ),

  seatsPositive('chk_license_key_history_seats_positive'),

  maxActivationsPositive('chk_license_key_history_max_activations_positive'),

  purchaseFromNotBlank('chk_license_key_history_purchase_from_not_blank'),

  orderIdNotBlank('chk_license_key_history_order_id_not_blank'),

  supportContactNotBlank('chk_license_key_history_support_contact_not_blank'),

  purchaseActivationRange('chk_license_key_history_purchase_activation_range'),

  purchaseExpiryRange('chk_license_key_history_purchase_expiry_range');

  const LicenseKeyHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum LicenseKeyHistoryIndex {
  product('idx_license_key_history_product'),
  licenseType('idx_license_key_history_license_type'),
  purchaseDate('idx_license_key_history_purchase_date'),
  expiresAt('idx_license_key_history_expires_at');

  const LicenseKeyHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> licenseKeyHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${LicenseKeyHistoryIndex.product.indexName} ON license_key_history(product);',
  'CREATE INDEX IF NOT EXISTS ${LicenseKeyHistoryIndex.licenseType.indexName} ON license_key_history(license_type);',
  'CREATE INDEX IF NOT EXISTS ${LicenseKeyHistoryIndex.purchaseDate.indexName} ON license_key_history(purchase_date);',
  'CREATE INDEX IF NOT EXISTS ${LicenseKeyHistoryIndex.expiresAt.indexName} ON license_key_history(expires_at);',
];
