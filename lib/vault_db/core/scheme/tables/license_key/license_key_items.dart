import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

enum LicenseType {
  perpetual,
  subscription,
  trial,
  volume,
  oem,
  educational,
  openSource,
  other,
}

@DataClassName('LicenseKeyItemsData')
class LicenseKeyItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Продукт/приложение, к которому относится лицензия.
  TextColumn get productName => text().withLength(min: 1, max: 255)();

  /// Производитель или поставщик продукта.
  TextColumn get vendor => text().withLength(min: 1, max: 255).nullable()();

  /// Лицензионный ключ.
  ///
  /// Secret!!!. Не ограничиваем длину и outer whitespace, чтобы не
  /// ломать нестандартные ключи, offline activation blobs и т.п.
  TextColumn get licenseKey => text()();

  /// Тип лицензии: perpetual, subscription, trial и т.д.
  TextColumn get licenseType => textEnum<LicenseType>().nullable()();

  /// Дополнительный тип лицензии, если licenseType = other.
  TextColumn get licenseTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Email аккаунта, к которому привязана лицензия.
  TextColumn get accountEmail =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Имя аккаунта, к которому привязана лицензия.
  TextColumn get accountUsername =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Email, использованный при покупке.
  TextColumn get purchaseEmail =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Номер заказа/чека/инвойса.
  TextColumn get orderNumber =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Дата покупки.
  DateTimeColumn get purchaseDate => dateTime().nullable()();

  /// Цена покупки.
  RealColumn get purchasePrice => real().nullable()();

  /// Валюта цены покупки.
  TextColumn get currency => text().withLength(min: 1, max: 32).nullable()();

  /// Дата начала действия лицензии.
  DateTimeColumn get validFrom => dateTime().nullable()();

  /// Дата окончания действия лицензии.
  DateTimeColumn get validTo => dateTime().nullable()();

  /// Дата продления.
  DateTimeColumn get renewalDate => dateTime().nullable()();

  /// Количество мест/пользователей.
  IntColumn get seats => integer().nullable()();

  /// Максимальное количество активаций.
  IntColumn get activationLimit => integer().nullable()();

  /// Количество использованных активаций.
  IntColumn get activationsUsed => integer().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'license_key_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${LicenseKeyItemConstraint.itemIdNotBlank.constraintName}
    CHECK (
      length(trim(item_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.licenseKeyNotBlank.constraintName}
    CHECK (
      length(trim(license_key)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.productNameNotBlank.constraintName}
    CHECK (
      length(trim(product_name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.productNameNoOuterWhitespace.constraintName}
    CHECK (
      product_name = trim(product_name)
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.vendorNotBlank.constraintName}
    CHECK (
      vendor IS NULL
      OR length(trim(vendor)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.vendorNoOuterWhitespace.constraintName}
    CHECK (
      vendor IS NULL
      OR vendor = trim(vendor)
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.accountEmailNotBlank.constraintName}
    CHECK (
      account_email IS NULL
      OR length(trim(account_email)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.accountEmailNoOuterWhitespace.constraintName}
    CHECK (
      account_email IS NULL
      OR account_email = trim(account_email)
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.accountUsernameNotBlank.constraintName}
    CHECK (
      account_username IS NULL
      OR length(trim(account_username)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.accountUsernameNoOuterWhitespace.constraintName}
    CHECK (
      account_username IS NULL
      OR account_username = trim(account_username)
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.purchaseEmailNotBlank.constraintName}
    CHECK (
      purchase_email IS NULL
      OR length(trim(purchase_email)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.purchaseEmailNoOuterWhitespace.constraintName}
    CHECK (
      purchase_email IS NULL
      OR purchase_email = trim(purchase_email)
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.orderNumberNotBlank.constraintName}
    CHECK (
      order_number IS NULL
      OR length(trim(order_number)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.orderNumberNoOuterWhitespace.constraintName}
    CHECK (
      order_number IS NULL
      OR order_number = trim(order_number)
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.licenseTypeOtherRequired.constraintName}
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
    CONSTRAINT ${LicenseKeyItemConstraint.licenseTypeOtherMustBeNull.constraintName}
    CHECK (
      license_type = 'other'
      OR license_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.licenseTypeOtherNoOuterWhitespace.constraintName}
    CHECK (
      license_type_other IS NULL
      OR license_type_other = trim(license_type_other)
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.seatsPositive.constraintName}
    CHECK (
      seats IS NULL
      OR seats > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.activationLimitPositive.constraintName}
    CHECK (
      activation_limit IS NULL
      OR activation_limit > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.activationsUsedNonNegative.constraintName}
    CHECK (
      activations_used IS NULL
      OR activations_used >= 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.activationsUsedWithinLimit.constraintName}
    CHECK (
      activation_limit IS NULL
      OR activations_used IS NULL
      OR activations_used <= activation_limit
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.purchasePriceNonNegative.constraintName}
    CHECK (
      purchase_price IS NULL
      OR purchase_price >= 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.currencyNotBlank.constraintName}
    CHECK (
      currency IS NULL
      OR length(trim(currency)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.currencyNoOuterWhitespace.constraintName}
    CHECK (
      currency IS NULL
      OR currency = trim(currency)
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.validDateRange.constraintName}
    CHECK (
      valid_from IS NULL
      OR valid_to IS NULL
      OR valid_from <= valid_to
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.purchaseDateBeforeValidTo.constraintName}
    CHECK (
      purchase_date IS NULL
      OR valid_to IS NULL
      OR purchase_date <= valid_to
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.renewalDateAfterPurchaseDate.constraintName}
    CHECK (
      renewal_date IS NULL
      OR purchase_date IS NULL
      OR renewal_date >= purchase_date
    )
    ''',
  ];
}

enum LicenseKeyItemConstraint {
  itemIdNotBlank('chk_license_key_items_item_id_not_blank'),

  licenseKeyNotBlank('chk_license_key_items_license_key_not_blank'),

  productNameNotBlank('chk_license_key_items_product_name_not_blank'),

  productNameNoOuterWhitespace(
    'chk_license_key_items_product_name_no_outer_whitespace',
  ),

  vendorNotBlank('chk_license_key_items_vendor_not_blank'),

  vendorNoOuterWhitespace('chk_license_key_items_vendor_no_outer_whitespace'),

  accountEmailNotBlank('chk_license_key_items_account_email_not_blank'),

  accountEmailNoOuterWhitespace(
    'chk_license_key_items_account_email_no_outer_whitespace',
  ),

  accountUsernameNotBlank('chk_license_key_items_account_username_not_blank'),

  accountUsernameNoOuterWhitespace(
    'chk_license_key_items_account_username_no_outer_whitespace',
  ),

  purchaseEmailNotBlank('chk_license_key_items_purchase_email_not_blank'),

  purchaseEmailNoOuterWhitespace(
    'chk_license_key_items_purchase_email_no_outer_whitespace',
  ),

  orderNumberNotBlank('chk_license_key_items_order_number_not_blank'),

  orderNumberNoOuterWhitespace(
    'chk_license_key_items_order_number_no_outer_whitespace',
  ),

  licenseTypeOtherRequired('chk_license_key_items_license_type_other_required'),

  licenseTypeOtherMustBeNull(
    'chk_license_key_items_license_type_other_must_be_null',
  ),

  licenseTypeOtherNoOuterWhitespace(
    'chk_license_key_items_license_type_other_no_outer_whitespace',
  ),

  seatsPositive('chk_license_key_items_seats_positive'),

  activationLimitPositive('chk_license_key_items_activation_limit_positive'),

  activationsUsedNonNegative(
    'chk_license_key_items_activations_used_non_negative',
  ),

  activationsUsedWithinLimit(
    'chk_license_key_items_activations_used_within_limit',
  ),

  purchasePriceNonNegative('chk_license_key_items_purchase_price_non_negative'),

  currencyNotBlank('chk_license_key_items_currency_not_blank'),

  currencyNoOuterWhitespace(
    'chk_license_key_items_currency_no_outer_whitespace',
  ),

  validDateRange('chk_license_key_items_valid_date_range'),

  purchaseDateBeforeValidTo(
    'chk_license_key_items_purchase_date_before_valid_to',
  ),

  renewalDateAfterPurchaseDate(
    'chk_license_key_items_renewal_date_after_purchase_date',
  );

  const LicenseKeyItemConstraint(this.constraintName);

  final String constraintName;
}

enum LicenseKeyItemIndex {
  productName('idx_license_key_items_product_name'),
  vendor('idx_license_key_items_vendor'),
  licenseType('idx_license_key_items_license_type'),
  validTo('idx_license_key_items_valid_to'),
  renewalDate('idx_license_key_items_renewal_date'),
  accountEmail('idx_license_key_items_account_email');

  const LicenseKeyItemIndex(this.indexName);

  final String indexName;
}

final List<String> licenseKeyItemsTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${LicenseKeyItemIndex.productName.indexName}
  ON license_key_items(product_name)
  WHERE product_name IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${LicenseKeyItemIndex.vendor.indexName}
  ON license_key_items(vendor)
  WHERE vendor IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${LicenseKeyItemIndex.licenseType.indexName}
  ON license_key_items(license_type)
  WHERE license_type IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${LicenseKeyItemIndex.validTo.indexName}
  ON license_key_items(valid_to)
  WHERE valid_to IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${LicenseKeyItemIndex.renewalDate.indexName}
  ON license_key_items(renewal_date)
  WHERE renewal_date IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${LicenseKeyItemIndex.accountEmail.indexName}
  ON license_key_items(account_email)
  WHERE account_email IS NOT NULL;
  ''',
];

enum LicenseKeyItemTrigger {
  validateVaultItemTypeOnInsert(
    'trg_license_key_items_validate_vault_item_type_on_insert',
  ),

  validateVaultItemTypeOnUpdate(
    'trg_license_key_items_validate_vault_item_type_on_update',
  ),

  preventItemIdUpdate('trg_license_key_items_prevent_item_id_update');

  const LicenseKeyItemTrigger(this.triggerName);

  final String triggerName;
}

enum LicenseKeyItemRaise {
  invalidVaultItemType(
    'license_key_items.item_id must reference vault_items.id with type = licenseKey',
  ),

  itemIdImmutable('license_key_items.item_id is immutable');

  const LicenseKeyItemRaise(this.message);

  final String message;
}

final List<String> licenseKeyItemsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${LicenseKeyItemTrigger.validateVaultItemTypeOnInsert.triggerName}
  BEFORE INSERT ON license_key_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'licenseKey'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${LicenseKeyItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${LicenseKeyItemTrigger.validateVaultItemTypeOnUpdate.triggerName}
  BEFORE UPDATE ON license_key_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'licenseKey'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${LicenseKeyItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${LicenseKeyItemTrigger.preventItemIdUpdate.triggerName}
  BEFORE UPDATE OF item_id ON license_key_items
  FOR EACH ROW
  WHEN NEW.item_id <> OLD.item_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${LicenseKeyItemRaise.itemIdImmutable.message}'
    );
  END;
  ''',
];
