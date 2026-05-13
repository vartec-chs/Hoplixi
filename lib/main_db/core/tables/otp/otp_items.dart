import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

enum OtpType { otp, hotp }

enum OtpHashAlgorithm { SHA1, SHA256, SHA512 }

@DataClassName('OtpItemsData')
class OtpItems extends Table {
  @ReferenceName('otpItem')
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  TextColumn get type =>
      textEnum<OtpType>().withDefault(const Constant('otp'))();

  TextColumn get issuer => text().withLength(min: 1, max: 255).nullable()();

  TextColumn get accountName =>
      text().withLength(min: 1, max: 255).nullable()();

  /// OTP secret in canonical decoded raw bytes form.
  BlobColumn get secret => blob()();

  TextColumn get algorithm =>
      textEnum<OtpHashAlgorithm>().withDefault(const Constant('SHA1'))();

  IntColumn get digits => integer().withDefault(const Constant(6))();

  IntColumn get period =>
      integer().nullable().withDefault(const Constant(30))();

  IntColumn get counter => integer().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'otp_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${OtpItemConstraint.itemIdNotBlank.constraintName}
    CHECK (
      length(trim(item_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${OtpItemConstraint.typeConfigConsistency.constraintName}
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
    CONSTRAINT ${OtpItemConstraint.issuerNotBlank.constraintName}
    CHECK (
      issuer IS NULL
      OR length(trim(issuer)) > 0
    )
    ''',

    '''
    CONSTRAINT ${OtpItemConstraint.issuerNoOuterWhitespace.constraintName}
    CHECK (
      issuer IS NULL
      OR issuer = trim(issuer)
    )
    ''',

    '''
    CONSTRAINT ${OtpItemConstraint.accountNameNoOuterWhitespace.constraintName}
    CHECK (
      account_name IS NULL
      OR account_name = trim(account_name)
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
      digits IN (6, 7, 8)
    )
    ''',

    '''
    CONSTRAINT ${OtpItemConstraint.periodPositive.constraintName}
    CHECK (
      period IS NULL
      OR period > 0
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
  itemIdNotBlank('chk_otp_items_item_id_not_blank'),

  typeConfigConsistency('chk_otp_items_type_config_consistency'),

  issuerNotBlank('chk_otp_items_issuer_not_blank'),

  issuerNoOuterWhitespace('chk_otp_items_issuer_no_outer_whitespace'),

  accountNameNotBlank('chk_otp_items_account_name_not_blank'),

  accountNameNoOuterWhitespace(
    'chk_otp_items_account_name_no_outer_whitespace',
  ),

  secretNotEmpty('chk_otp_items_secret_not_empty'),

  digitsValid('chk_otp_items_digits_valid'),

  periodPositive('chk_otp_items_period_positive'),

  counterNonNegative('chk_otp_items_counter_non_negative');

  const OtpItemConstraint(this.constraintName);

  final String constraintName;
}

enum OtpItemIndex {
  type('idx_otp_items_type'),
  issuer('idx_otp_items_issuer'),
  accountName('idx_otp_items_account_name');

  const OtpItemIndex(this.indexName);

  final String indexName;
}

final List<String> otpItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${OtpItemIndex.type.indexName} ON otp_items(type);',
  '''
  CREATE INDEX IF NOT EXISTS ${OtpItemIndex.issuer.indexName}
  ON otp_items(issuer)
  WHERE issuer IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${OtpItemIndex.accountName.indexName}
  ON otp_items(account_name)
  WHERE account_name IS NOT NULL;
  ''',
];

enum OtpItemTrigger {
  validateVaultItemTypeOnInsert(
    'trg_otp_items_validate_vault_item_type_on_insert',
  ),

  validateVaultItemTypeOnUpdate(
    'trg_otp_items_validate_vault_item_type_on_update',
  ),

  preventItemIdUpdate('trg_otp_items_prevent_item_id_update');

  const OtpItemTrigger(this.triggerName);

  final String triggerName;
}

enum OtpItemRaise {
  invalidVaultItemType(
    'otp_items.item_id must reference vault_items.id with type = otp',
  ),

  itemIdImmutable('otp_items.item_id is immutable');

  const OtpItemRaise(this.message);

  final String message;
}

final List<String> otpItemsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${OtpItemTrigger.validateVaultItemTypeOnInsert.triggerName}
  BEFORE INSERT ON otp_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'otp'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${OtpItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${OtpItemTrigger.validateVaultItemTypeOnUpdate.triggerName}
  BEFORE UPDATE ON otp_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'otp'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${OtpItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${OtpItemTrigger.preventItemIdUpdate.triggerName}
  BEFORE UPDATE OF item_id ON otp_items
  FOR EACH ROW
  WHEN NEW.item_id <> OLD.item_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${OtpItemRaise.itemIdImmutable.message}'
    );
  END;
  ''',
];
