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
  TextColumn get product => text().withLength(min: 1, max: 255)();

  /// Лицензионный ключ.
  ///
  /// Секретное значение. Не ограничиваем длину, чтобы не ломать
  /// нестандартные ключи, offline activation blobs и т.п.
  TextColumn get licenseKey => text()();

  /// Тип лицензии: perpetual, subscription, trial и т.д.
  TextColumn get licenseType => textEnum<LicenseType>().nullable()();

  /// Дополнительный тип лицензии, если licenseType = other.
  TextColumn get licenseTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Количество мест/пользователей.
  IntColumn get seats => integer().nullable()();

  /// Максимальное количество активаций.
  IntColumn get maxActivations => integer().nullable()();

  /// Дата активации.
  DateTimeColumn get activatedOn => dateTime().nullable()();

  /// Дата покупки.
  DateTimeColumn get purchaseDate => dateTime().nullable()();

  /// Где куплено: сайт, магазин, реселлер и т.д.
  TextColumn get purchaseFrom =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Номер заказа/чека/инвойса.
  TextColumn get orderId => text().withLength(min: 1, max: 255).nullable()();

  /// Дата окончания действия лицензии.
  DateTimeColumn get expiresAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'license_key_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${LicenseKeyItemConstraint.productNotBlank.constraintName}
    CHECK (
      length(trim(product)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.licenseKeyNotBlank.constraintName}
    CHECK (
      length(trim(license_key)) > 0
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
    CONSTRAINT ${LicenseKeyItemConstraint.seatsPositive.constraintName}
    CHECK (
      seats IS NULL
      OR seats > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.maxActivationsPositive.constraintName}
    CHECK (
      max_activations IS NULL
      OR max_activations > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.purchaseFromNotBlank.constraintName}
    CHECK (
      purchase_from IS NULL
      OR length(trim(purchase_from)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.orderIdNotBlank.constraintName}
    CHECK (
      order_id IS NULL
      OR length(trim(order_id)) > 0
    )
    ''',
    '''
    CONSTRAINT ${LicenseKeyItemConstraint.purchaseActivationRange.constraintName}
    CHECK (
      purchase_date IS NULL
      OR activated_on IS NULL
      OR purchase_date <= activated_on
    )
    ''',

    '''
    CONSTRAINT ${LicenseKeyItemConstraint.purchaseExpiryRange.constraintName}
    CHECK (
      purchase_date IS NULL
      OR expires_at IS NULL
      OR purchase_date <= expires_at
    )
    ''',
  ];
}

enum LicenseKeyItemConstraint {
  productNotBlank('chk_license_key_items_product_not_blank'),

  licenseKeyNotBlank('chk_license_key_items_license_key_not_blank'),

  licenseTypeOtherRequired('chk_license_key_items_license_type_other_required'),

  licenseTypeOtherMustBeNull(
    'chk_license_key_items_license_type_other_must_be_null',
  ),

  seatsPositive('chk_license_key_items_seats_positive'),

  maxActivationsPositive('chk_license_key_items_max_activations_positive'),

  purchaseFromNotBlank('chk_license_key_items_purchase_from_not_blank'),

  orderIdNotBlank('chk_license_key_items_order_id_not_blank'),

  purchaseActivationRange('chk_license_key_items_purchase_activation_range'),

  purchaseExpiryRange('chk_license_key_items_purchase_expiry_range');

  const LicenseKeyItemConstraint(this.constraintName);

  final String constraintName;
}

enum LicenseKeyItemIndex {
  product('idx_license_key_items_product'),
  licenseType('idx_license_key_items_license_type'),
  purchaseDate('idx_license_key_items_purchase_date'),
  expiresAt('idx_license_key_items_expires_at');

  const LicenseKeyItemIndex(this.indexName);

  final String indexName;
}

final List<String> licenseKeyItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${LicenseKeyItemIndex.product.indexName} ON license_key_items(product);',
  'CREATE INDEX IF NOT EXISTS ${LicenseKeyItemIndex.licenseType.indexName} ON license_key_items(license_type);',
  'CREATE INDEX IF NOT EXISTS ${LicenseKeyItemIndex.purchaseDate.indexName} ON license_key_items(purchase_date);',
  'CREATE INDEX IF NOT EXISTS ${LicenseKeyItemIndex.expiresAt.indexName} ON license_key_items(expires_at);',
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
