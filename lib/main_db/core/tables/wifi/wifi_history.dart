import 'package:drift/drift.dart';

import '../vault_items/vault_item_history.dart';
import 'wifi_items.dart';

/// History-таблица для специфичных полей Wi-Fi.
///
/// Данные вставляются только триггерами.
/// Секретное поле password может быть NULL,
/// если включён режим истории без сохранения секретов.
@DataClassName('WifiHistoryData')
class WifiHistory extends Table {
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// SSID сети snapshot.
  TextColumn get ssid => text().withLength(min: 1, max: 255)();

  /// Пароль Wi-Fi snapshot.
  ///
  /// Nullable intentionally:
  /// history may store metadata-only snapshots depending on secret history policy.
  TextColumn get password => text().nullable()();

  /// Тип защиты сети snapshot.
  TextColumn get security => textEnum<WifiSecurityType>().nullable()();

  /// Дополнительный тип защиты, если security = other.
  TextColumn get securityOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Скрытая сеть snapshot.
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  /// Username для enterprise Wi-Fi snapshot.
  TextColumn get username => text().withLength(min: 1, max: 255).nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'wifi_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${WifiHistoryConstraint.ssidNotBlank.constraintName}
    CHECK (
      length(trim(ssid)) > 0
    )
    ''',

    '''
    CONSTRAINT ${WifiHistoryConstraint.passwordNotBlank.constraintName}
    CHECK (
      password IS NULL
      OR length(trim(password)) > 0
    )
    ''',

    '''
    CONSTRAINT ${WifiHistoryConstraint.securityOtherRequired.constraintName}
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
    CONSTRAINT ${WifiHistoryConstraint.securityOtherMustBeNull.constraintName}
    CHECK (
      security = 'other'
      OR security_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${WifiHistoryConstraint.usernameNotBlank.constraintName}
    CHECK (
      username IS NULL
      OR length(trim(username)) > 0
    )
    ''',
  ];
}

enum WifiHistoryConstraint {
  ssidNotBlank('chk_wifi_history_ssid_not_blank'),

  passwordNotBlank('chk_wifi_history_password_not_blank'),

  securityOtherRequired('chk_wifi_history_security_other_required'),

  securityOtherMustBeNull('chk_wifi_history_security_other_must_be_null'),

  usernameNotBlank('chk_wifi_history_username_not_blank');

  const WifiHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum WifiHistoryIndex {
  ssid('idx_wifi_history_ssid'),
  security('idx_wifi_history_security'),
  hidden('idx_wifi_history_hidden'),
  username('idx_wifi_history_username');

  const WifiHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> wifiHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${WifiHistoryIndex.ssid.indexName} ON wifi_history(ssid);',
  'CREATE INDEX IF NOT EXISTS ${WifiHistoryIndex.security.indexName} ON wifi_history(security);',
  'CREATE INDEX IF NOT EXISTS ${WifiHistoryIndex.hidden.indexName} ON wifi_history(hidden);',
  'CREATE INDEX IF NOT EXISTS ${WifiHistoryIndex.username.indexName} ON wifi_history(username);',
];
