import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

enum CardType { debit, credit, prepaid, virtual, other }

enum CardNetwork {
  visa,
  mastercard,
  amex,
  discover,
  dinersclub,
  jcb,
  unionpay,
  mir,
  maestro,
  other,
}

/// Type-specific таблица для банковских карт.
///
/// Содержит только поля, специфичные для банковской карты.
/// Общие поля: name, description, categoryId, iconRefId, favorite/archive и т.д.
/// хранятся в vault_items.
@DataClassName('BankCardItemsData')
class BankCardItems extends Table {
  /// PK и FK → vault_items.id ON DELETE CASCADE
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Имя владельца карты.
  ///
  /// Nullable, потому что не у всех виртуальных/предоплаченных карт
  /// пользователь может знать или хотеть указывать владельца.
  TextColumn get cardholderName =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Номер карты.
  ///
  /// Хранится как секретное значение внутри зашифрованной БД.
  /// Не ограничиваем max length, чтобы не ломать нестандартные форматы.
  TextColumn get cardNumber => text()();

  /// Тип карты: debit, credit, prepaid, virtual, other.
  TextColumn get cardType => textEnum<CardType>().nullable()();

  /// Дополнительный тип карты, если cardType = other.
  TextColumn get cardTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Платёжная сеть: Visa, Mastercard, Amex и т.д.
  TextColumn get cardNetwork => textEnum<CardNetwork>().nullable()();

  /// Дополнительная платёжная сеть, если cardNetwork = other.
  TextColumn get cardNetworkOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Месяц истечения срока действия карты: MM.
  TextColumn get expiryMonth => text().withLength(min: 2, max: 2).nullable()();

  /// Год истечения срока действия карты: YYYY.
  TextColumn get expiryYear => text().withLength(min: 4, max: 4).nullable()();

  /// CVV/CVC.
  ///
  /// Секретное значение. Может быть NULL, если пользователь не хочет хранить CVV.
  TextColumn get cvv => text().nullable()();

  /// Название банка.
  TextColumn get bankName => text().withLength(min: 1, max: 255).nullable()();

  /// Номер счёта.
  TextColumn get accountNumber =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Routing number / sort code / bank code.
  TextColumn get routingNumber =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Дополнительные метаданные в JSON-формате.
  ///
  /// Например: страна выпуска, валюта, лимит, BIN-информация,
  /// кастомные банковские параметры.
  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'bank_card_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${BankCardItemConstraint.cardholderNameNotBlank.constraintName}
    CHECK (
      cardholder_name IS NULL
      OR length(trim(cardholder_name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${BankCardItemConstraint.cardNumberNotBlank.constraintName}
    CHECK (
      length(trim(card_number)) > 0
    )
    ''',

    '''
    CONSTRAINT ${BankCardItemConstraint.cardTypeOtherRequired.constraintName}
    CHECK (
      card_type IS NULL
      OR card_type != 'other'
      OR (
        card_type_other IS NOT NULL
        AND length(trim(card_type_other)) > 0
      )
    )
    ''',

    '''
    CONSTRAINT ${BankCardItemConstraint.cardTypeOtherMustBeNull.constraintName}
    CHECK (
      card_type = 'other'
      OR card_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${BankCardItemConstraint.cardNetworkOtherRequired.constraintName}
    CHECK (
      card_network IS NULL
      OR card_network != 'other'
      OR (
        card_network_other IS NOT NULL
        AND length(trim(card_network_other)) > 0
      )
    )
    ''',

    '''
    CONSTRAINT ${BankCardItemConstraint.cardNetworkOtherMustBeNull.constraintName}
    CHECK (
      card_network = 'other'
      OR card_network_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${BankCardItemConstraint.expiryMonthValid.constraintName}
    CHECK (
      expiry_month IS NULL
      OR (
        expiry_month GLOB '[0-9][0-9]'
        AND CAST(expiry_month AS INTEGER) BETWEEN 1 AND 12
      )
    )
    ''',

    '''
    CONSTRAINT ${BankCardItemConstraint.expiryYearValid.constraintName}
    CHECK (
      expiry_year IS NULL
      OR expiry_year GLOB '[0-9][0-9][0-9][0-9]'
    )
    ''',

    '''
    CONSTRAINT ${BankCardItemConstraint.expiryMonthYearBothNullOrBothSet.constraintName}
    CHECK (
      (expiry_month IS NULL AND expiry_year IS NULL)
      OR
      (expiry_month IS NOT NULL AND expiry_year IS NOT NULL)
    )
    ''',

    '''
    CONSTRAINT ${BankCardItemConstraint.bankNameNotBlank.constraintName}
    CHECK (
      bank_name IS NULL
      OR length(trim(bank_name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${BankCardItemConstraint.accountNumberNotBlank.constraintName}
    CHECK (
      account_number IS NULL
      OR length(trim(account_number)) > 0
    )
    ''',

    '''
    CONSTRAINT ${BankCardItemConstraint.routingNumberNotBlank.constraintName}
    CHECK (
      routing_number IS NULL
      OR length(trim(routing_number)) > 0
    )
    ''',
  ];
}

enum BankCardItemConstraint {
  cardholderNameNotBlank('chk_bank_card_cardholder_name_not_blank'),

  cardNumberNotBlank('chk_bank_card_card_number_not_blank'),

  cardTypeOtherRequired('chk_bank_card_card_type_other_required'),

  cardTypeOtherMustBeNull('chk_bank_card_card_type_other_must_be_null'),

  cardNetworkOtherRequired('chk_bank_card_card_network_other_required'),

  cardNetworkOtherMustBeNull('chk_bank_card_card_network_other_must_be_null'),

  expiryMonthValid('chk_bank_card_expiry_month_valid'),

  expiryYearValid('chk_bank_card_expiry_year_valid'),

  expiryMonthYearBothNullOrBothSet(
    'chk_bank_card_expiry_month_year_both_null_or_both_set',
  ),

  bankNameNotBlank('chk_bank_card_bank_name_not_blank'),

  accountNumberNotBlank('chk_bank_card_account_number_not_blank'),

  routingNumberNotBlank('chk_bank_card_routing_number_not_blank');

  const BankCardItemConstraint(this.constraintName);

  final String constraintName;
}

enum BankCardItemIndex {
  cardType('idx_bank_card_items_card_type'),
  cardNetwork('idx_bank_card_items_card_network'),
  expiryYearMonth('idx_bank_card_items_expiry_year_month'),
  bankName('idx_bank_card_items_bank_name');

  const BankCardItemIndex(this.indexName);

  final String indexName;
}

final List<String> bankCardItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${BankCardItemIndex.cardType.indexName} ON bank_card_items(card_type);',
  'CREATE INDEX IF NOT EXISTS ${BankCardItemIndex.cardNetwork.indexName} ON bank_card_items(card_network);',
  'CREATE INDEX IF NOT EXISTS ${BankCardItemIndex.expiryYearMonth.indexName} ON bank_card_items(expiry_year, expiry_month);',
  'CREATE INDEX IF NOT EXISTS ${BankCardItemIndex.bankName.indexName} ON bank_card_items(bank_name);',
];
