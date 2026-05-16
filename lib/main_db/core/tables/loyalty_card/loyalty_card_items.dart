import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

enum LoyaltyBarcodeType {
  code128,
  code39,
  ean13,
  ean8,
  upcA,
  upcE,
  qr,
  pdf417,
  aztec,
  dataMatrix,
  other,
}

@DataClassName('LoyaltyCardItemsData')
class LoyaltyCardItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Название программы лояльности.
  TextColumn get programName => text().withLength(min: 1, max: 255)();

  /// Номер карты.
  ///
  /// Может быть чувствительным значением, поэтому не делаем слишком жёсткий max
  /// и не запрещаем outer whitespace.
  TextColumn get cardNumber => text().nullable()();

  /// Значение штрихкода/QR-кода.
  ///
  /// Может быть пользовательским точным значением, поэтому не запрещаем
  /// outer whitespace.
  TextColumn get barcodeValue => text().nullable()();

  /// Пароль/секрет карты лояльности.
  /// 
  /// Secret!!!, может содержать чувствительную информацию
  TextColumn get password => text().nullable()();

  /// Тип штрихкода/QR-кода.
  TextColumn get barcodeType => textEnum<LoyaltyBarcodeType>().nullable()();

  /// Дополнительный тип штрихкода, если barcodeType = other.
  TextColumn get barcodeTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Эмитент или оператор программы.
  TextColumn get issuer => text().withLength(min: 1, max: 255).nullable()();

  /// Сайт программы.
  TextColumn get website => text().withLength(min: 1, max: 2048).nullable()();

  /// Телефон поддержки.
  TextColumn get phone => text().withLength(min: 1, max: 64).nullable()();

  /// Email поддержки или аккаунта программы.
  TextColumn get email => text().withLength(min: 1, max: 255).nullable()();

  /// Дата начала действия карты.
  DateTimeColumn get validFrom => dateTime().nullable()();

  /// Дата окончания действия карты.
  DateTimeColumn get validTo => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'loyalty_card_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.itemIdNotBlank.constraintName}
    CHECK (
      length(trim(item_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.programNameNotBlank.constraintName}
    CHECK (
      length(trim(program_name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.programNameNoOuterWhitespace.constraintName}
    CHECK (
      program_name = trim(program_name)
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.cardNumberNotBlank.constraintName}
    CHECK (
      card_number IS NULL
      OR length(trim(card_number)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.barcodeValueNotBlank.constraintName}
    CHECK (
      barcode_value IS NULL
      OR length(trim(barcode_value)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.barcodeTypeOtherRequired.constraintName}
    CHECK (
      barcode_type IS NULL
      OR barcode_type != 'other'
      OR (
        barcode_type_other IS NOT NULL
        AND length(trim(barcode_type_other)) > 0
      )
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.barcodeTypeOtherMustBeNull.constraintName}
    CHECK (
      barcode_type = 'other'
      OR barcode_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.barcodeTypeOtherNoOuterWhitespace.constraintName}
    CHECK (
      barcode_type_other IS NULL
      OR barcode_type_other = trim(barcode_type_other)
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.issuerNotBlank.constraintName}
    CHECK (
      issuer IS NULL
      OR length(trim(issuer)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.issuerNoOuterWhitespace.constraintName}
    CHECK (
      issuer IS NULL
      OR issuer = trim(issuer)
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.websiteNotBlank.constraintName}
    CHECK (
      website IS NULL
      OR length(trim(website)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.websiteNoOuterWhitespace.constraintName}
    CHECK (
      website IS NULL
      OR website = trim(website)
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.phoneNotBlank.constraintName}
    CHECK (
      phone IS NULL
      OR length(trim(phone)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.phoneNoOuterWhitespace.constraintName}
    CHECK (
      phone IS NULL
      OR phone = trim(phone)
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.emailNotBlank.constraintName}
    CHECK (
      email IS NULL
      OR length(trim(email)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.emailNoOuterWhitespace.constraintName}
    CHECK (
      email IS NULL
      OR email = trim(email)
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.validDateRange.constraintName}
    CHECK (
      valid_from IS NULL
      OR valid_to IS NULL
      OR valid_from <= valid_to
    )
    ''',
  ];
}

enum LoyaltyCardItemConstraint {
  itemIdNotBlank('chk_loyalty_card_items_item_id_not_blank'),

  programNameNotBlank('chk_loyalty_card_items_program_name_not_blank'),

  programNameNoOuterWhitespace(
    'chk_loyalty_card_items_program_name_no_outer_whitespace',
  ),

  cardNumberNotBlank('chk_loyalty_card_items_card_number_not_blank'),

  barcodeValueNotBlank('chk_loyalty_card_items_barcode_value_not_blank'),

  barcodeTypeOtherRequired(
    'chk_loyalty_card_items_barcode_type_other_required',
  ),

  barcodeTypeOtherMustBeNull(
    'chk_loyalty_card_items_barcode_type_other_must_be_null',
  ),

  barcodeTypeOtherNoOuterWhitespace(
    'chk_loyalty_card_items_barcode_type_other_no_outer_whitespace',
  ),

  issuerNotBlank('chk_loyalty_card_items_issuer_not_blank'),

  issuerNoOuterWhitespace('chk_loyalty_card_items_issuer_no_outer_whitespace'),

  websiteNotBlank('chk_loyalty_card_items_website_not_blank'),

  websiteNoOuterWhitespace(
    'chk_loyalty_card_items_website_no_outer_whitespace',
  ),

  phoneNotBlank('chk_loyalty_card_items_phone_not_blank'),

  phoneNoOuterWhitespace('chk_loyalty_card_items_phone_no_outer_whitespace'),

  emailNotBlank('chk_loyalty_card_items_email_not_blank'),

  emailNoOuterWhitespace('chk_loyalty_card_items_email_no_outer_whitespace'),

  validDateRange('chk_loyalty_card_items_valid_date_range');

  const LoyaltyCardItemConstraint(this.constraintName);

  final String constraintName;
}

enum LoyaltyCardItemIndex {
  programName('idx_loyalty_card_items_program_name'),
  issuer('idx_loyalty_card_items_issuer'),
  barcodeType('idx_loyalty_card_items_barcode_type'),
  validTo('idx_loyalty_card_items_valid_to');

  const LoyaltyCardItemIndex(this.indexName);

  final String indexName;
}

final List<String> loyaltyCardItemsTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${LoyaltyCardItemIndex.programName.indexName}
  ON loyalty_card_items(program_name)
  WHERE program_name IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${LoyaltyCardItemIndex.issuer.indexName}
  ON loyalty_card_items(issuer)
  WHERE issuer IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${LoyaltyCardItemIndex.barcodeType.indexName}
  ON loyalty_card_items(barcode_type)
  WHERE barcode_type IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${LoyaltyCardItemIndex.validTo.indexName}
  ON loyalty_card_items(valid_to)
  WHERE valid_to IS NOT NULL;
  ''',
];

enum LoyaltyCardItemTrigger {
  validateVaultItemTypeOnInsert(
    'trg_loyalty_card_items_validate_vault_item_type_on_insert',
  ),

  validateVaultItemTypeOnUpdate(
    'trg_loyalty_card_items_validate_vault_item_type_on_update',
  ),

  preventItemIdUpdate('trg_loyalty_card_items_prevent_item_id_update');

  const LoyaltyCardItemTrigger(this.triggerName);

  final String triggerName;
}

enum LoyaltyCardItemRaise {
  invalidVaultItemType(
    'loyalty_card_items.item_id must reference vault_items.id with type = loyaltyCard',
  ),

  itemIdImmutable('loyalty_card_items.item_id is immutable');

  const LoyaltyCardItemRaise(this.message);

  final String message;
}

final List<String> loyaltyCardItemsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${LoyaltyCardItemTrigger.validateVaultItemTypeOnInsert.triggerName}
  BEFORE INSERT ON loyalty_card_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'loyaltyCard'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${LoyaltyCardItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${LoyaltyCardItemTrigger.validateVaultItemTypeOnUpdate.triggerName}
  BEFORE UPDATE ON loyalty_card_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'loyaltyCard'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${LoyaltyCardItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${LoyaltyCardItemTrigger.preventItemIdUpdate.triggerName}
  BEFORE UPDATE OF item_id ON loyalty_card_items
  FOR EACH ROW
  WHEN NEW.item_id <> OLD.item_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${LoyaltyCardItemRaise.itemIdImmutable.message}'
    );
  END;
  ''',
];
