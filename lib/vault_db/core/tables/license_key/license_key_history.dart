import 'package:drift/drift.dart';

import '../vault_items/vault_snapshots_history.dart';
import 'license_key_items.dart';

/// History-таблица для специфичных полей лицензионного ключа.
///
/// Данные вставляются только триггерами.
/// Секретное поле licenseKey может быть NULL,
/// если включён режим истории без сохранения секретов.
@DataClassName('LicenseKeyHistoryData')
class LicenseKeyHistory extends Table {
  TextColumn get historyId => text().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Продукт/приложение snapshot.
  TextColumn get productName => text().withLength(min: 1, max: 255)();

  /// Производитель или поставщик продукта snapshot.
  TextColumn get vendor => text().withLength(min: 1, max: 255).nullable()();

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

  /// Email аккаунта, к которому привязана лицензия snapshot.
  TextColumn get accountEmail =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Имя аккаунта, к которому привязана лицензия snapshot.
  TextColumn get accountUsername =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Email, использованный при покупке snapshot.
  TextColumn get purchaseEmail =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Номер заказа/чека/инвойса snapshot.
  TextColumn get orderNumber =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Дата покупки snapshot.
  DateTimeColumn get purchaseDate => dateTime().nullable()();

  /// Цена покупки snapshot.
  RealColumn get purchasePrice => real().nullable()();

  /// Валюта цены покупки snapshot.
  TextColumn get currency => text().withLength(min: 1, max: 32).nullable()();

  /// Дата начала действия лицензии snapshot.
  DateTimeColumn get validFrom => dateTime().nullable()();

  /// Дата окончания действия лицензии snapshot.
  DateTimeColumn get validTo => dateTime().nullable()();

  /// Дата продления snapshot.
  DateTimeColumn get renewalDate => dateTime().nullable()();

  /// Количество мест/пользователей snapshot.
  IntColumn get seats => integer().nullable()();

  /// Максимальное количество активаций snapshot.
  IntColumn get activationLimit => integer().nullable()();

  /// Количество использованных активаций snapshot.
  IntColumn get activationsUsed => integer().nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'license_key_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.historyIdNotBlank.constraintName}
    CHECK (
      length(trim(history_id)) > 0
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
    CONSTRAINT ${LicenseKeyHistoryConstraint.productNameNotBlank.constraintName}
    CHECK (
      length(trim(product_name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.productNameNoOuterWhitespace.constraintName}
    CHECK (
      product_name = trim(product_name)
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.vendorNotBlank.constraintName}
    CHECK (
      vendor IS NULL
      OR length(trim(vendor)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.vendorNoOuterWhitespace.constraintName}
    CHECK (
      vendor IS NULL
      OR vendor = trim(vendor)
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.accountEmailNotBlank.constraintName}
    CHECK (
      account_email IS NULL
      OR length(trim(account_email)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.accountEmailNoOuterWhitespace.constraintName}
    CHECK (
      account_email IS NULL
      OR account_email = trim(account_email)
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.accountUsernameNotBlank.constraintName}
    CHECK (
      account_username IS NULL
      OR length(trim(account_username)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.accountUsernameNoOuterWhitespace.constraintName}
    CHECK (
      account_username IS NULL
      OR account_username = trim(account_username)
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.purchaseEmailNotBlank.constraintName}
    CHECK (
      purchase_email IS NULL
      OR length(trim(purchase_email)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.purchaseEmailNoOuterWhitespace.constraintName}
    CHECK (
      purchase_email IS NULL
      OR purchase_email = trim(purchase_email)
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.orderNumberNotBlank.constraintName}
    CHECK (
      order_number IS NULL
      OR length(trim(order_number)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.orderNumberNoOuterWhitespace.constraintName}
    CHECK (
      order_number IS NULL
      OR order_number = trim(order_number)
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
    CONSTRAINT ${LicenseKeyHistoryConstraint.licenseTypeOtherNoOuterWhitespace.constraintName}
    CHECK (
      license_type_other IS NULL
      OR license_type_other = trim(license_type_other)
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
    CONSTRAINT ${LicenseKeyHistoryConstraint.activationLimitPositive.constraintName}
    CHECK (
      activation_limit IS NULL
      OR activation_limit > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.activationsUsedNonNegative.constraintName}
    CHECK (
      activations_used IS NULL
      OR activations_used >= 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.activationsUsedWithinLimit.constraintName}
    CHECK (
      activation_limit IS NULL
      OR activations_used IS NULL
      OR activations_used <= activation_limit
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.purchasePriceNonNegative.constraintName}
    CHECK (
      purchase_price IS NULL
      OR purchase_price >= 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.currencyNotBlank.constraintName}
    CHECK (
      currency IS NULL
      OR length(trim(currency)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.currencyNoOuterWhitespace.constraintName}
    CHECK (
      currency IS NULL
      OR currency = trim(currency)
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.validDateRange.constraintName}
    CHECK (
      valid_from IS NULL
      OR valid_to IS NULL
      OR valid_from <= valid_to
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.purchaseDateBeforeValidTo.constraintName}
    CHECK (
      purchase_date IS NULL
      OR valid_to IS NULL
      OR purchase_date <= valid_to
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyHistoryConstraint.renewalDateAfterPurchaseDate.constraintName}
    CHECK (
      renewal_date IS NULL
      OR purchase_date IS NULL
      OR renewal_date >= purchase_date
    )
    ''',
  ];
}

enum LicenseKeyHistoryConstraint {
  historyIdNotBlank('chk_license_key_history_history_id_not_blank'),

  licenseKeyNotBlank('chk_license_key_history_license_key_not_blank'),

  productNameNotBlank('chk_license_key_history_product_name_not_blank'),

  productNameNoOuterWhitespace(
    'chk_license_key_history_product_name_no_outer_whitespace',
  ),

  vendorNotBlank('chk_license_key_history_vendor_not_blank'),

  vendorNoOuterWhitespace('chk_license_key_history_vendor_no_outer_whitespace'),

  accountEmailNotBlank('chk_license_key_history_account_email_not_blank'),

  accountEmailNoOuterWhitespace(
    'chk_license_key_history_account_email_no_outer_whitespace',
  ),

  accountUsernameNotBlank('chk_license_key_history_account_username_not_blank'),

  accountUsernameNoOuterWhitespace(
    'chk_license_key_history_account_username_no_outer_whitespace',
  ),

  purchaseEmailNotBlank('chk_license_key_history_purchase_email_not_blank'),

  purchaseEmailNoOuterWhitespace(
    'chk_license_key_history_purchase_email_no_outer_whitespace',
  ),

  orderNumberNotBlank('chk_license_key_history_order_number_not_blank'),

  orderNumberNoOuterWhitespace(
    'chk_license_key_history_order_number_no_outer_whitespace',
  ),

  licenseTypeOtherRequired(
    'chk_license_key_history_license_type_other_required',
  ),

  licenseTypeOtherMustBeNull(
    'chk_license_key_history_license_type_other_must_be_null',
  ),

  licenseTypeOtherNoOuterWhitespace(
    'chk_license_key_history_license_type_other_no_outer_whitespace',
  ),

  seatsPositive('chk_license_key_history_seats_positive'),

  activationLimitPositive('chk_license_key_history_activation_limit_positive'),

  activationsUsedNonNegative(
    'chk_license_key_history_activations_used_non_negative',
  ),

  activationsUsedWithinLimit(
    'chk_license_key_history_activations_used_within_limit',
  ),

  purchasePriceNonNegative(
    'chk_license_key_history_purchase_price_non_negative',
  ),

  currencyNotBlank('chk_license_key_history_currency_not_blank'),

  currencyNoOuterWhitespace(
    'chk_license_key_history_currency_no_outer_whitespace',
  ),

  validDateRange('chk_license_key_history_valid_date_range'),

  purchaseDateBeforeValidTo(
    'chk_license_key_history_purchase_date_before_valid_to',
  ),

  renewalDateAfterPurchaseDate(
    'chk_license_key_history_renewal_date_after_purchase_date',
  );

  const LicenseKeyHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum LicenseKeyHistoryIndex {
  productName('idx_license_key_history_product_name'),
  vendor('idx_license_key_history_vendor'),
  licenseType('idx_license_key_history_license_type'),
  validTo('idx_license_key_history_valid_to'),
  renewalDate('idx_license_key_history_renewal_date'),
  accountEmail('idx_license_key_history_account_email');

  const LicenseKeyHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> licenseKeyHistoryTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${LicenseKeyHistoryIndex.productName.indexName}
  ON license_key_history(product_name)
  WHERE product_name IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${LicenseKeyHistoryIndex.vendor.indexName}
  ON license_key_history(vendor)
  WHERE vendor IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${LicenseKeyHistoryIndex.licenseType.indexName}
  ON license_key_history(license_type)
  WHERE license_type IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${LicenseKeyHistoryIndex.validTo.indexName}
  ON license_key_history(valid_to)
  WHERE valid_to IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${LicenseKeyHistoryIndex.renewalDate.indexName}
  ON license_key_history(renewal_date)
  WHERE renewal_date IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${LicenseKeyHistoryIndex.accountEmail.indexName}
  ON license_key_history(account_email)
  WHERE account_email IS NOT NULL;
  ''',
];

enum LicenseKeyHistoryTrigger {
  validateSnapshotTypeOnInsert(
    'trg_license_key_history_validate_snapshot_type_on_insert',
  ),

  preventUpdate('trg_license_key_history_prevent_update');

  const LicenseKeyHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum LicenseKeyHistoryRaise {
  invalidSnapshotType(
    'license_key_history.history_id must reference vault_snapshots_history.id with type = licenseKey',
  ),

  historyIsImmutable('license_key_history rows are immutable');

  const LicenseKeyHistoryRaise(this.message);

  final String message;
}

final List<String> licenseKeyHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${LicenseKeyHistoryTrigger.validateSnapshotTypeOnInsert.triggerName}
  BEFORE INSERT ON license_key_history
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_snapshots_history
    WHERE id = NEW.history_id
      AND type = 'licenseKey'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${LicenseKeyHistoryRaise.invalidSnapshotType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${LicenseKeyHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON license_key_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${LicenseKeyHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
