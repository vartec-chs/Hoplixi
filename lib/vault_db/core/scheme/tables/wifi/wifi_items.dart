import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

enum WifiSecurityType {
  open,
  wep,
  wpa,
  wpa2,
  wpa3,
  wpaEnterprise,
  wpa2Enterprise,
  wpa3Enterprise,
  other,
}

enum WifiEncryptionType { none, wep, tkip, aes, ccmp, gcmp, other }

@DataClassName('WifiItemsData')
class WifiItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// SSID сети.
  TextColumn get ssid => text().withLength(min: 1, max: 255)();

  /// Пароль Wi-Fi.
  ///
  /// Secret!!!. Nullable для open/enterprise-сетей или если пароль неизвестен.
  TextColumn get password => text().nullable()();

  /// Тип защиты сети.
  TextColumn get securityType => textEnum<WifiSecurityType>().nullable()();

  /// Дополнительный тип защиты, если securityType = other.
  TextColumn get securityTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Тип шифрования.
  TextColumn get encryption => textEnum<WifiEncryptionType>().nullable()();

  /// Дополнительный тип шифрования, если encryption = other.
  TextColumn get encryptionOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Скрытая сеть.
  BoolColumn get hiddenSsid => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'wifi_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${WifiItemConstraint.itemIdNotBlank.constraintName}
    CHECK (
      length(trim(item_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${WifiItemConstraint.ssidNotBlank.constraintName}
    CHECK (
      length(trim(ssid)) > 0
    )
    ''',

    '''
    CONSTRAINT ${WifiItemConstraint.passwordNotBlank.constraintName}
    CHECK (
      password IS NULL
      OR length(trim(password)) > 0
    )
    ''',

    '''
    CONSTRAINT ${WifiItemConstraint.securityTypeOtherRequired.constraintName}
    CHECK (
      security_type IS NULL
      OR security_type != 'other'
      OR (
        security_type_other IS NOT NULL
        AND length(trim(security_type_other)) > 0
      )
    )
    ''',

    '''
    CONSTRAINT ${WifiItemConstraint.securityTypeOtherMustBeNull.constraintName}
    CHECK (
      security_type = 'other'
      OR security_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${WifiItemConstraint.securityTypeOtherNoOuterWhitespace.constraintName}
    CHECK (
      security_type_other IS NULL
      OR security_type_other = trim(security_type_other)
    )
    ''',

    '''
    CONSTRAINT ${WifiItemConstraint.encryptionOtherRequired.constraintName}
    CHECK (
      encryption IS NULL
      OR encryption != 'other'
      OR (
        encryption_other IS NOT NULL
        AND length(trim(encryption_other)) > 0
      )
    )
    ''',

    '''
    CONSTRAINT ${WifiItemConstraint.encryptionOtherMustBeNull.constraintName}
    CHECK (
      encryption = 'other'
      OR encryption_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${WifiItemConstraint.encryptionOtherNoOuterWhitespace.constraintName}
    CHECK (
      encryption_other IS NULL
      OR encryption_other = trim(encryption_other)
    )
    ''',

    '''
    CONSTRAINT ${WifiItemConstraint.passwordSecurityConsistency.constraintName}
    CHECK (
      security_type IS NULL
      OR (
        security_type = 'open'
        AND password IS NULL
      )
      OR security_type IN (
        'wpaEnterprise',
        'wpa2Enterprise',
        'wpa3Enterprise',
        'other'
      )
      OR (
        security_type IN ('wep', 'wpa', 'wpa2', 'wpa3')
        AND password IS NOT NULL
      )
    )
    ''',
  ];
}

enum WifiItemConstraint {
  itemIdNotBlank('chk_wifi_items_item_id_not_blank'),

  ssidNotBlank('chk_wifi_items_ssid_not_blank'),

  passwordNotBlank('chk_wifi_items_password_not_blank'),

  securityTypeOtherRequired('chk_wifi_items_security_type_other_required'),

  securityTypeOtherMustBeNull(
    'chk_wifi_items_security_type_other_must_be_null',
  ),

  securityTypeOtherNoOuterWhitespace(
    'chk_wifi_items_security_type_other_no_outer_whitespace',
  ),

  encryptionOtherRequired('chk_wifi_items_encryption_other_required'),

  encryptionOtherMustBeNull('chk_wifi_items_encryption_other_must_be_null'),

  encryptionOtherNoOuterWhitespace(
    'chk_wifi_items_encryption_other_no_outer_whitespace',
  ),

  passwordSecurityConsistency('chk_wifi_items_password_security_consistency');

  const WifiItemConstraint(this.constraintName);

  final String constraintName;
}

enum WifiItemIndex {
  ssid('idx_wifi_items_ssid'),
  securityType('idx_wifi_items_security_type'),
  encryption('idx_wifi_items_encryption');

  const WifiItemIndex(this.indexName);

  final String indexName;
}

final List<String> wifiItemsTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${WifiItemIndex.ssid.indexName}
  ON wifi_items(ssid)
  WHERE ssid IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${WifiItemIndex.securityType.indexName}
  ON wifi_items(security_type)
  WHERE security_type IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${WifiItemIndex.encryption.indexName}
  ON wifi_items(encryption)
  WHERE encryption IS NOT NULL;
  ''',
];

enum WifiItemTrigger {
  validateVaultItemTypeOnInsert(
    'trg_wifi_items_validate_vault_item_type_on_insert',
  ),

  validateVaultItemTypeOnUpdate(
    'trg_wifi_items_validate_vault_item_type_on_update',
  ),

  preventItemIdUpdate('trg_wifi_items_prevent_item_id_update');

  const WifiItemTrigger(this.triggerName);

  final String triggerName;
}

enum WifiItemRaise {
  invalidVaultItemType(
    'wifi_items.item_id must reference vault_items.id with type = wifi',
  ),

  itemIdImmutable('wifi_items.item_id is immutable');

  const WifiItemRaise(this.message);

  final String message;
}

final List<String> wifiItemsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${WifiItemTrigger.validateVaultItemTypeOnInsert.triggerName}
  BEFORE INSERT ON wifi_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'wifi'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${WifiItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${WifiItemTrigger.validateVaultItemTypeOnUpdate.triggerName}
  BEFORE UPDATE ON wifi_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'wifi'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${WifiItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${WifiItemTrigger.preventItemIdUpdate.triggerName}
  BEFORE UPDATE OF item_id ON wifi_items
  FOR EACH ROW
  WHEN NEW.item_id <> OLD.item_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${WifiItemRaise.itemIdImmutable.message}'
    );
  END;
  ''',
];
