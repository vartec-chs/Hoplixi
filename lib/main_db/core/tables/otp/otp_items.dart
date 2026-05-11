import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

enum OtpType { totp, hotp }

enum OtpHashAlgorithm { SHA1, SHA256, SHA512 }

@DataClassName('OtpItemsData')
class OtpItems extends Table {
  @ReferenceName('otpItem')
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  @ReferenceName('linkedPasswordItem')
  TextColumn get passwordItemId => text()
      .references(VaultItems, #id, onDelete: KeyAction.setNull)
      .nullable()();

  TextColumn get type =>
      textEnum<OtpType>().withDefault(const Constant('totp'))();

  TextColumn get issuer => text().withLength(min: 1, max: 255).nullable()();

  TextColumn get accountName =>
      text().withLength(min: 1, max: 255).nullable()();

  /// OTP secret in canonical decoded raw bytes form.
  BlobColumn get secret => blob()();

  TextColumn get algorithm =>
      textEnum<OtpHashAlgorithm>().withDefault(const Constant('SHA1'))();

  IntColumn get digits => integer().withDefault(const Constant(6))();

  IntColumn get period => integer().withDefault(const Constant(30))();

  IntColumn get counter => integer().nullable()();

  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'otp_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${OtpItemConstraint.typeCounterConsistency.constraintName}
    CHECK (
      (type = 'hotp' AND counter IS NOT NULL)
      OR
      (type = 'totp' AND counter IS NULL)
    )
    ''',

    '''
    CONSTRAINT ${OtpItemConstraint.issuerNotBlank.constraintName}
    CHECK (
      issuer IS NULL
      OR length(trim(issuer)) > 0
    )
    ''',

    '''
    CONSTRAINT ${OtpItemConstraint.accountNameNotBlank.constraintName}
    CHECK (
      account_name IS NULL
      OR length(trim(account_name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${OtpItemConstraint.secretNotEmpty.constraintName}
    CHECK (
      length(secret) > 0
    )
    ''',

    '''
    CONSTRAINT ${OtpItemConstraint.digitsValid.constraintName}
    CHECK (
      digits BETWEEN 6 AND 10
    )
    ''',

    '''
    CONSTRAINT ${OtpItemConstraint.periodPositive.constraintName}
    CHECK (
      period > 0
    )
    ''',

    '''
    CONSTRAINT ${OtpItemConstraint.counterNonNegative.constraintName}
    CHECK (
      counter IS NULL
      OR counter >= 0
    )
    ''',
  ];
}

enum OtpItemConstraint {
  typeCounterConsistency('chk_otp_items_type_counter_consistency'),

  issuerNotBlank('chk_otp_items_issuer_not_blank'),

  accountNameNotBlank('chk_otp_items_account_name_not_blank'),

  secretNotEmpty('chk_otp_items_secret_not_empty'),

  digitsValid('chk_otp_items_digits_valid'),

  periodPositive('chk_otp_items_period_positive'),

  counterNonNegative('chk_otp_items_counter_non_negative');

  const OtpItemConstraint(this.constraintName);

  final String constraintName;
}

enum OtpItemIndex {
  passwordItemId('idx_otp_items_password_item_id'),
  type('idx_otp_items_type'),
  issuer('idx_otp_items_issuer'),
  accountName('idx_otp_items_account_name'),
  algorithm('idx_otp_items_algorithm');

  const OtpItemIndex(this.indexName);

  final String indexName;
}

final List<String> otpItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${OtpItemIndex.passwordItemId.indexName} ON otp_items(password_item_id);',
  'CREATE INDEX IF NOT EXISTS ${OtpItemIndex.type.indexName} ON otp_items(type);',
  'CREATE INDEX IF NOT EXISTS ${OtpItemIndex.issuer.indexName} ON otp_items(issuer);',
  'CREATE INDEX IF NOT EXISTS ${OtpItemIndex.accountName.indexName} ON otp_items(account_name);',
  'CREATE INDEX IF NOT EXISTS ${OtpItemIndex.algorithm.indexName} ON otp_items(algorithm);',
];