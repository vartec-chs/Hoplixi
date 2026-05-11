import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

enum WifiSecurityType {
  open,
  wep,
  wpa,
  wpa2,
  wpa3,
  wpaEnterprise,
  other,
}

@DataClassName('WifiItemsData')
class WifiItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// SSID сети.
  TextColumn get ssid => text().withLength(min: 1, max: 255)();

  /// Пароль Wi-Fi.
  ///
  /// Nullable для open/enterprise-сетей или если пароль неизвестен.
  TextColumn get password => text().nullable()();

  /// Тип защиты сети.
  TextColumn get security => textEnum<WifiSecurityType>().nullable()();

  /// Дополнительный тип защиты, если security = other.
  TextColumn get securityOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Скрытая сеть.
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  /// Username для enterprise Wi-Fi.
  ///
  /// Остальные enterprise-параметры лучше добавить отдельными колонками позже,
  /// если появится полноценная поддержка WPA Enterprise.
  TextColumn get username => text().withLength(min: 1, max: 255).nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'wifi_items';

  @override
  List<String> get customConstraints => [
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
    CONSTRAINT ${WifiItemConstraint.securityOtherRequired.constraintName}
    CHECK (
      security IS NULL
      OR security != 'other'
      OR (
        security_other IS NOT NULL
        AND length(trim(security_other)) > 0
      )
    )
    ''',
    '''
    CONSTRAINT ${WifiItemConstraint.securityOtherMustBeNull.constraintName}
    CHECK (
      security = 'other'
      OR security_other IS NULL
    )
    ''',
    '''
    CONSTRAINT ${WifiItemConstraint.usernameNotBlank.constraintName}
    CHECK (
      username IS NULL
      OR length(trim(username)) > 0
    )
    ''',
  ];
}

enum WifiItemConstraint {
  ssidNotBlank(
    'chk_wifi_items_ssid_not_blank',
  ),

  passwordNotBlank(
    'chk_wifi_items_password_not_blank',
  ),

  securityOtherRequired(
    'chk_wifi_items_security_other_required',
  ),

  securityOtherMustBeNull(
    'chk_wifi_items_security_other_must_be_null',
  ),

  usernameNotBlank(
    'chk_wifi_items_username_not_blank',
  );

  const WifiItemConstraint(this.constraintName);

  final String constraintName;
}

enum WifiItemIndex {
  ssid('idx_wifi_items_ssid'),
  security('idx_wifi_items_security'),
  hidden('idx_wifi_items_hidden'),
  username('idx_wifi_items_username');

  const WifiItemIndex(this.indexName);

  final String indexName;
}

final List<String> wifiItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${WifiItemIndex.ssid.indexName} ON wifi_items(ssid);',
  'CREATE INDEX IF NOT EXISTS ${WifiItemIndex.security.indexName} ON wifi_items(security);',
  'CREATE INDEX IF NOT EXISTS ${WifiItemIndex.hidden.indexName} ON wifi_items(hidden);',
  'CREATE INDEX IF NOT EXISTS ${WifiItemIndex.username.indexName} ON wifi_items(username);',
];