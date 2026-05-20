import 'package:drift/drift.dart';

import '../vault_items/vault_snapshots_history.dart';
import 'otp_items.dart';

/// History-таблица для специфичных полей OTP.
///
/// Данные вставляются только триггерами.
/// Секретное поле secret может быть NULL, если включён режим истории
/// без сохранения секретов.
@DataClassName('OtpHistoryData')
class OtpHistory extends Table {
  /// PK и FK → vault_snapshots_history.id ON DELETE CASCADE.
  TextColumn get historyId => text().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Тип OTP snapshot: OTP или HOTP.
  TextColumn get type =>
      textEnum<OtpType>().withDefault(const Constant('otp'))();

  /// Издатель snapshot.
  TextColumn get issuer => text().withLength(min: 1, max: 255).nullable()();

  /// Имя аккаунта snapshot.
  TextColumn get accountName =>
      text().withLength(min: 1, max: 255).nullable()();

  /// OTP secret snapshot in canonical decoded raw bytes form.
  ///
  /// Nullable intentionally:
  /// history may store metadata-only snapshots depending on secret history policy.
  BlobColumn get secret => blob().nullable()();

  /// Алгоритм HMAC snapshot.
  TextColumn get algorithm =>
      textEnum<OtpHashAlgorithm>().withDefault(const Constant('SHA1'))();

  /// Количество цифр snapshot.
  IntColumn get digits => integer().withDefault(const Constant(6))();

  /// Период обновления snapshot.
  IntColumn get period =>
      integer().nullable().withDefault(const Constant(30))();

  /// Счётчик HOTP snapshot.
  IntColumn get counter => integer().nullable()();
  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'otp_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${OtpHistoryConstraint.historyIdNotBlank.constraintName}
    CHECK (
      length(trim(history_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${OtpHistoryConstraint.typeConfigConsistency.constraintName}
    CHECK (
      (
        type = 'otp'
        AND period IS NOT NULL
        AND counter IS NULL
      )
      OR
      (
        type = 'hotp'
        AND period IS NULL
        AND counter IS NOT NULL
      )
    )
    ''',

    '''
    CONSTRAINT ${OtpHistoryConstraint.issuerNotBlank.constraintName}
    CHECK (
      issuer IS NULL
      OR length(trim(issuer)) > 0
    )
    ''',

    '''
    CONSTRAINT ${OtpHistoryConstraint.issuerNoOuterWhitespace.constraintName}
    CHECK (
      issuer IS NULL
      OR issuer = trim(issuer)
    )
    ''',

    '''
    CONSTRAINT ${OtpHistoryConstraint.accountNameNotBlank.constraintName}
    CHECK (
      account_name IS NULL
      OR length(trim(account_name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${OtpHistoryConstraint.accountNameNoOuterWhitespace.constraintName}
    CHECK (
      account_name IS NULL
      OR account_name = trim(account_name)
    )
    ''',

    '''
    CONSTRAINT ${OtpHistoryConstraint.secretNotEmpty.constraintName}
    CHECK (
      secret IS NULL
      OR length(secret) > 0
    )
    ''',

    '''
    CONSTRAINT ${OtpHistoryConstraint.digitsValid.constraintName}
    CHECK (
      digits IN (6, 7, 8)
    )
    ''',

    '''
    CONSTRAINT ${OtpHistoryConstraint.periodPositive.constraintName}
    CHECK (
      period IS NULL
      OR period > 0
    )
    ''',

    '''
    CONSTRAINT ${OtpHistoryConstraint.counterNonNegative.constraintName}
    CHECK (
      counter IS NULL
      OR counter >= 0
    )
    ''',
  ];
}

enum OtpHistoryConstraint {
  historyIdNotBlank('chk_otp_history_history_id_not_blank'),

  typeConfigConsistency('chk_otp_history_type_config_consistency'),

  issuerNotBlank('chk_otp_history_issuer_not_blank'),

  issuerNoOuterWhitespace('chk_otp_history_issuer_no_outer_whitespace'),

  accountNameNotBlank('chk_otp_history_account_name_not_blank'),

  accountNameNoOuterWhitespace(
    'chk_otp_history_account_name_no_outer_whitespace',
  ),

  secretNotEmpty('chk_otp_history_secret_not_empty'),

  digitsValid('chk_otp_history_digits_valid'),

  periodPositive('chk_otp_history_period_positive'),

  counterNonNegative('chk_otp_history_counter_non_negative');

  const OtpHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum OtpHistoryIndex {
  type('idx_otp_history_type'),
  issuer('idx_otp_history_issuer'),
  accountName('idx_otp_history_account_name');

  const OtpHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> otpHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${OtpHistoryIndex.type.indexName} ON otp_history(type);',
  '''
  CREATE INDEX IF NOT EXISTS ${OtpHistoryIndex.issuer.indexName}
  ON otp_history(issuer)
  WHERE issuer IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${OtpHistoryIndex.accountName.indexName}
  ON otp_history(account_name)
  WHERE account_name IS NOT NULL;
  ''',
];

enum OtpHistoryTrigger {
  validateSnapshotTypeOnInsert(
    'trg_otp_history_validate_snapshot_type_on_insert',
  ),

  preventUpdate('trg_otp_history_prevent_update');

  const OtpHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum OtpHistoryRaise {
  invalidSnapshotType(
    'otp_history.history_id must reference vault_snapshots_history.id with type = otp',
  ),

  historyIsImmutable('otp_history rows are immutable');

  const OtpHistoryRaise(this.message);

  final String message;
}

final List<String> otpHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${OtpHistoryTrigger.validateSnapshotTypeOnInsert.triggerName}
  BEFORE INSERT ON otp_history
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_snapshots_history
    WHERE id = NEW.history_id
      AND type = 'otp'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${OtpHistoryRaise.invalidSnapshotType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${OtpHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON otp_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${OtpHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
