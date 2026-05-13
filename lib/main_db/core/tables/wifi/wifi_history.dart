import 'package:drift/drift.dart';

import '../vault_items/vault_snapshots_history.dart';
import 'wifi_items.dart';

/// History-таблица для специфичных полей Wi-Fi.
///
/// Данные вставляются только триггерами.
/// Секретное поле password может быть NULL,
/// если включён режим истории без сохранения секретов.
@DataClassName('WifiHistoryData')
class WifiHistory extends Table {
  TextColumn get historyId => text().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// SSID сети snapshot.
  TextColumn get ssid => text().withLength(min: 1, max: 255)();

  /// Пароль Wi-Fi snapshot.
  ///
  /// Nullable intentionally:
  /// history may store metadata-only snapshots depending on secret history policy.
  TextColumn get password => text().nullable()();

  /// Тип защиты сети snapshot.
  TextColumn get securityType => textEnum<WifiSecurityType>().nullable()();

  /// Дополнительный тип защиты, если securityType = other.
  TextColumn get securityTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Тип шифрования snapshot.
  TextColumn get encryption => textEnum<WifiEncryptionType>().nullable()();

  /// Дополнительный тип шифрования, если encryption = other.
  TextColumn get encryptionOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Скрытая сеть snapshot.
  BoolColumn get hiddenSsid => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'wifi_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${WifiHistoryConstraint.historyIdNotBlank.constraintName}
    CHECK (
      length(trim(history_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${WifiHistoryConstraint.ssidNotBlank.constraintName}
    CHECK (
      ssid IS NULL
      OR length(trim(ssid)) > 0
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
    CONSTRAINT ${WifiHistoryConstraint.securityTypeOtherRequired.constraintName}
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
    CONSTRAINT ${WifiHistoryConstraint.securityTypeOtherMustBeNull.constraintName}
    CHECK (
      security_type = 'other'
      OR security_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${WifiHistoryConstraint.securityTypeOtherNoOuterWhitespace.constraintName}
    CHECK (
      security_type_other IS NULL
      OR security_type_other = trim(security_type_other)
    )
    ''',

    '''
    CONSTRAINT ${WifiHistoryConstraint.encryptionOtherRequired.constraintName}
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
    CONSTRAINT ${WifiHistoryConstraint.encryptionOtherMustBeNull.constraintName}
    CHECK (
      encryption = 'other'
      OR encryption_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${WifiHistoryConstraint.encryptionOtherNoOuterWhitespace.constraintName}
    CHECK (
      encryption_other IS NULL
      OR encryption_other = trim(encryption_other)
    )
    ''',

    '''
    CONSTRAINT ${WifiHistoryConstraint.passwordSecurityConsistency.constraintName}
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

enum WifiHistoryConstraint {
  historyIdNotBlank('chk_wifi_history_history_id_not_blank'),

  ssidNotBlank('chk_wifi_history_ssid_not_blank'),

  passwordNotBlank('chk_wifi_history_password_not_blank'),

  securityTypeOtherRequired('chk_wifi_history_security_type_other_required'),

  securityTypeOtherMustBeNull(
    'chk_wifi_history_security_type_other_must_be_null',
  ),

  securityTypeOtherNoOuterWhitespace(
    'chk_wifi_history_security_type_other_no_outer_whitespace',
  ),

  encryptionOtherRequired('chk_wifi_history_encryption_other_required'),

  encryptionOtherMustBeNull('chk_wifi_history_encryption_other_must_be_null'),

  encryptionOtherNoOuterWhitespace(
    'chk_wifi_history_encryption_other_no_outer_whitespace',
  ),

  passwordSecurityConsistency('chk_wifi_history_password_security_consistency');

  const WifiHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum WifiHistoryIndex {
  ssid('idx_wifi_history_ssid'),
  securityType('idx_wifi_history_security_type'),
  encryption('idx_wifi_history_encryption');

  const WifiHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> wifiHistoryTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${WifiHistoryIndex.ssid.indexName}
  ON wifi_history(ssid)
  WHERE ssid IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${WifiHistoryIndex.securityType.indexName}
  ON wifi_history(security_type)
  WHERE security_type IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${WifiHistoryIndex.encryption.indexName}
  ON wifi_history(encryption)
  WHERE encryption IS NOT NULL;
  ''',
];

enum WifiHistoryTrigger {
  validateSnapshotTypeOnInsert(
    'trg_wifi_history_validate_snapshot_type_on_insert',
  ),

  preventUpdate('trg_wifi_history_prevent_update');

  const WifiHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum WifiHistoryRaise {
  invalidSnapshotType(
    'wifi_history.history_id must reference vault_snapshots_history.id with type = wifi',
  ),

  historyIsImmutable('wifi_history rows are immutable');

  const WifiHistoryRaise(this.message);

  final String message;
}

final List<String> wifiHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${WifiHistoryTrigger.validateSnapshotTypeOnInsert.triggerName}
  BEFORE INSERT ON wifi_history
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_snapshots_history
    WHERE id = NEW.history_id
      AND type = 'wifi'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${WifiHistoryRaise.invalidSnapshotType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${WifiHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON wifi_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${WifiHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
