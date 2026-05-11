import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

enum LoyaltyBarcodeType {
  qr,
  code128,
  code39,
  ean13,
  ean8,
  upcA,
  upcE,
  aztec,
  pdf417,
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
  /// Может быть чувствительным значением, поэтому не делаем слишком жёсткий max.
  TextColumn get cardNumber => text().nullable()();

  /// Имя владельца карты.
  TextColumn get holderName => text().withLength(min: 1, max: 255).nullable()();

  /// Значение штрихкода/QR-кода.
  TextColumn get barcodeValue => text().nullable()();

  /// Тип штрихкода/QR-кода.
  TextColumn get barcodeType => textEnum<LoyaltyBarcodeType>().nullable()();

  /// Дополнительный тип штрихкода, если barcodeType = other.
  TextColumn get barcodeTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Пароль/PIN от личного кабинета или карты.
  ///
  /// Секретное значение.
  TextColumn get password => text().nullable()();

  /// Уровень программы: Silver, Gold, Premium и т.д.
  TextColumn get tier => text().withLength(min: 1, max: 255).nullable()();

  /// Дата окончания действия карты.
  DateTimeColumn get expiryDate => dateTime().nullable()();

  /// Сайт программы.
  TextColumn get website => text().withLength(min: 1, max: 2048).nullable()();

  /// Телефон поддержки.
  TextColumn get phoneNumber => text().withLength(min: 1, max: 64).nullable()();

  /// Дополнительные метаданные в JSON-формате.
  ///
  /// Например: storeName, country, appLogin, membershipId,
  /// termsUrl, lastPointsUpdateAt.
  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'loyalty_card_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.programNameNotBlank.constraintName}
    CHECK (
      length(trim(program_name)) > 0
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
    CONSTRAINT ${LoyaltyCardItemConstraint.holderNameNotBlank.constraintName}
    CHECK (
      holder_name IS NULL
      OR length(trim(holder_name)) > 0
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
    CONSTRAINT ${LoyaltyCardItemConstraint.passwordNotBlank.constraintName}
    CHECK (
      password IS NULL
      OR length(trim(password)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardItemConstraint.tierNotBlank.constraintName}
    CHECK (
      tier IS NULL
      OR length(trim(tier)) > 0
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
    CONSTRAINT ${LoyaltyCardItemConstraint.phoneNumberNotBlank.constraintName}
    CHECK (
      phone_number IS NULL
      OR length(trim(phone_number)) > 0
    )
    ''',
  ];
}

enum LoyaltyCardItemConstraint {
  programNameNotBlank('chk_loyalty_card_items_program_name_not_blank'),

  cardNumberNotBlank('chk_loyalty_card_items_card_number_not_blank'),

  holderNameNotBlank('chk_loyalty_card_items_holder_name_not_blank'),

  barcodeValueNotBlank('chk_loyalty_card_items_barcode_value_not_blank'),

  barcodeTypeOtherRequired(
    'chk_loyalty_card_items_barcode_type_other_required',
  ),

  barcodeTypeOtherMustBeNull(
    'chk_loyalty_card_items_barcode_type_other_must_be_null',
  ),

  passwordNotBlank('chk_loyalty_card_items_password_not_blank'),

  tierNotBlank('chk_loyalty_card_items_tier_not_blank'),

  websiteNotBlank('chk_loyalty_card_items_website_not_blank'),

  phoneNumberNotBlank('chk_loyalty_card_items_phone_number_not_blank');

  const LoyaltyCardItemConstraint(this.constraintName);

  final String constraintName;
}

enum LoyaltyCardItemIndex {
  programName('idx_loyalty_card_items_program_name'),
  barcodeType('idx_loyalty_card_items_barcode_type'),
  expiryDate('idx_loyalty_card_items_expiry_date'),
  tier('idx_loyalty_card_items_tier');

  const LoyaltyCardItemIndex(this.indexName);

  final String indexName;
}

final List<String> loyaltyCardItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${LoyaltyCardItemIndex.programName.indexName} ON loyalty_card_items(program_name);',
  'CREATE INDEX IF NOT EXISTS ${LoyaltyCardItemIndex.barcodeType.indexName} ON loyalty_card_items(barcode_type);',
  'CREATE INDEX IF NOT EXISTS ${LoyaltyCardItemIndex.expiryDate.indexName} ON loyalty_card_items(expiry_date);',
  'CREATE INDEX IF NOT EXISTS ${LoyaltyCardItemIndex.tier.indexName} ON loyalty_card_items(tier);',
];
