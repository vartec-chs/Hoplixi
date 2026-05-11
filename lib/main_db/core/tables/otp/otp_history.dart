import 'package:drift/drift.dart';

import 'otp_items.dart';
import '../vault_items/vault_item_history.dart';

/// History-таблица для специфичных полей OTP.
///
/// Данные вставляются только триггерами.
/// Секретное поле secret может быть NULL, если включён режим истории
/// без сохранения секретов.
@DataClassName('OtpHistoryData')
class OtpHistory extends Table {
  /// PK и FK → vault_item_history.id ON DELETE CASCADE.
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// Связь с password item snapshot.
  ///
  /// Не FK специально: history должна хранить снимок значения,
  /// даже если связанный vault item позже удалён.
  TextColumn get passwordItemId => text().nullable()();

  /// Тип OTP snapshot: TOTP или HOTP.
  TextColumn get type =>
      textEnum<OtpType>().withDefault(const Constant('totp'))();

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
  IntColumn get period => integer().withDefault(const Constant(30))();

  /// Счётчик HOTP snapshot.
  IntColumn get counter => integer().nullable()();

  /// Дополнительные метаданные snapshot.
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'otp_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${OtpHistoryConstraint.typeCounterConsistency.constraintName}
    CHECK (
      (type = 'hotp' AND counter IS NOT NULL)
      OR
      (type = 'totp' AND counter IS NULL)
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
    CONSTRAINT ${OtpHistoryConstraint.accountNameNotBlank.constraintName}
    CHECK (
      account_name IS NULL
      OR length(trim(account_name)) > 0
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
      digits BETWEEN 6 AND 10
    )
    ''',

    '''
    CONSTRAINT ${OtpHistoryConstraint.periodPositive.constraintName}
    CHECK (
      period > 0
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
  typeCounterConsistency(
    'chk_otp_history_type_counter_consistency',
  ),

  issuerNotBlank(
    'chk_otp_history_issuer_not_blank',
  ),

  accountNameNotBlank(
    'chk_otp_history_account_name_not_blank',
  ),

  secretNotEmpty(
    'chk_otp_history_secret_not_empty',
  ),

  digitsValid(
    'chk_otp_history_digits_valid',
  ),

  periodPositive(
    'chk_otp_history_period_positive',
  ),

  counterNonNegative(
    'chk_otp_history_counter_non_negative',
  );

  const OtpHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum OtpHistoryIndex {
  passwordItemId('idx_otp_history_password_item_id'),
  type('idx_otp_history_type'),
  issuer('idx_otp_history_issuer'),
  accountName('idx_otp_history_account_name'),
  algorithm('idx_otp_history_algorithm');

  const OtpHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> otpHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${OtpHistoryIndex.passwordItemId.indexName} ON otp_history(password_item_id);',
  'CREATE INDEX IF NOT EXISTS ${OtpHistoryIndex.type.indexName} ON otp_history(type);',
  'CREATE INDEX IF NOT EXISTS ${OtpHistoryIndex.issuer.indexName} ON otp_history(issuer);',
  'CREATE INDEX IF NOT EXISTS ${OtpHistoryIndex.accountName.indexName} ON otp_history(account_name);',
  'CREATE INDEX IF NOT EXISTS ${OtpHistoryIndex.algorithm.indexName} ON otp_history(algorithm);',
];