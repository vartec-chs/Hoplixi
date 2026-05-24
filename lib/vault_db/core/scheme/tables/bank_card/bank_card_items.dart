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
  /// PK и FK → vault_items.id ON DELETE CASCADE.
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Имя владельца карты.
  TextColumn get cardholderName =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Номер карты.
  ///
  /// Секретное значение внутри зашифрованной БД.
  /// Не ограничиваем жёстко длину, чтобы не ломать нестандартные форматы.
  TextColumn get cardNumber => text()();

  /// Тип карты.
  TextColumn get cardType => textEnum<CardType>().nullable()();

  /// Дополнительный тип карты, если cardType = other.
  TextColumn get cardTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Платёжная сеть.
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
  /// Secret!!!.
  TextColumn get cvv => text().nullable()();

  /// Название банка.
  TextColumn get bankName => text().withLength(min: 1, max: 255).nullable()();

  /// Номер счёта.
  TextColumn get accountNumber =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Routing number / sort code / bank code.
  TextColumn get routingNumber =>
      text().withLength(min: 1, max: 255).nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'bank_card_items';

  @override
  List<String> get customConstraints => [
    '''
        CONSTRAINT ${BankCardItemConstraint.itemIdNotBlank.constraintName}
        CHECK (
          length(trim(item_id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${BankCardItemConstraint.cardholderNameNotBlank.constraintName}
        CHECK (
          cardholder_name IS NULL
          OR length(trim(cardholder_name)) > 0
        )
        ''',

    '''
        CONSTRAINT ${BankCardItemConstraint.cardholderNameNoOuterWhitespace.constraintName}
        CHECK (
          cardholder_name IS NULL
          OR cardholder_name = trim(cardholder_name)
        )
        ''',

    '''
        CONSTRAINT ${BankCardItemConstraint.cardNumberNotBlank.constraintName}
        CHECK (
          length(trim(card_number)) > 0
        )
        ''',

    '''
        CONSTRAINT ${BankCardItemConstraint.cardNumberNoOuterWhitespace.constraintName}
        CHECK (
          card_number = trim(card_number)
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
        CONSTRAINT ${BankCardItemConstraint.cardTypeOtherNoOuterWhitespace.constraintName}
        CHECK (
          card_type_other IS NULL
          OR card_type_other = trim(card_type_other)
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
        CONSTRAINT ${BankCardItemConstraint.cardNetworkOtherNoOuterWhitespace.constraintName}
        CHECK (
          card_network_other IS NULL
          OR card_network_other = trim(card_network_other)
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
          (
            expiry_month IS NULL
            AND expiry_year IS NULL
          )
          OR
          (
            expiry_month IS NOT NULL
            AND expiry_year IS NOT NULL
          )
        )
        ''',

    '''
        CONSTRAINT ${BankCardItemConstraint.cvvNotBlank.constraintName}
        CHECK (
          cvv IS NULL
          OR length(trim(cvv)) > 0
        )
        ''',

    '''
        CONSTRAINT ${BankCardItemConstraint.cvvNoOuterWhitespace.constraintName}
        CHECK (
          cvv IS NULL
          OR cvv = trim(cvv)
        )
        ''',

    '''
        CONSTRAINT ${BankCardItemConstraint.cvvLengthValid.constraintName}
        CHECK (
          cvv IS NULL
          OR length(cvv) BETWEEN 3 AND 8
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
        CONSTRAINT ${BankCardItemConstraint.bankNameNoOuterWhitespace.constraintName}
        CHECK (
          bank_name IS NULL
          OR bank_name = trim(bank_name)
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
        CONSTRAINT ${BankCardItemConstraint.accountNumberNoOuterWhitespace.constraintName}
        CHECK (
          account_number IS NULL
          OR account_number = trim(account_number)
        )
        ''',

    '''
        CONSTRAINT ${BankCardItemConstraint.routingNumberNotBlank.constraintName}
        CHECK (
          routing_number IS NULL
          OR length(trim(routing_number)) > 0
        )
        ''',

    '''
        CONSTRAINT ${BankCardItemConstraint.routingNumberNoOuterWhitespace.constraintName}
        CHECK (
          routing_number IS NULL
          OR routing_number = trim(routing_number)
        )
        ''',
  ];
}

enum BankCardItemConstraint {
  itemIdNotBlank('chk_bank_card_items_item_id_not_blank'),

  cardholderNameNotBlank('chk_bank_card_items_cardholder_name_not_blank'),

  cardholderNameNoOuterWhitespace(
    'chk_bank_card_items_cardholder_name_no_outer_whitespace',
  ),

  cardNumberNotBlank('chk_bank_card_items_card_number_not_blank'),

  cardNumberNoOuterWhitespace(
    'chk_bank_card_items_card_number_no_outer_whitespace',
  ),

  cardTypeOtherRequired('chk_bank_card_items_card_type_other_required'),

  cardTypeOtherMustBeNull('chk_bank_card_items_card_type_other_must_be_null'),

  cardTypeOtherNoOuterWhitespace(
    'chk_bank_card_items_card_type_other_no_outer_whitespace',
  ),

  cardNetworkOtherRequired('chk_bank_card_items_card_network_other_required'),

  cardNetworkOtherMustBeNull(
    'chk_bank_card_items_card_network_other_must_be_null',
  ),

  cardNetworkOtherNoOuterWhitespace(
    'chk_bank_card_items_card_network_other_no_outer_whitespace',
  ),

  expiryMonthValid('chk_bank_card_items_expiry_month_valid'),

  expiryYearValid('chk_bank_card_items_expiry_year_valid'),

  expiryMonthYearBothNullOrBothSet(
    'chk_bank_card_items_expiry_month_year_both_null_or_both_set',
  ),

  cvvNotBlank('chk_bank_card_items_cvv_not_blank'),

  cvvNoOuterWhitespace('chk_bank_card_items_cvv_no_outer_whitespace'),

  cvvLengthValid('chk_bank_card_items_cvv_length_valid'),

  bankNameNotBlank('chk_bank_card_items_bank_name_not_blank'),

  bankNameNoOuterWhitespace(
    'chk_bank_card_items_bank_name_no_outer_whitespace',
  ),

  accountNumberNotBlank('chk_bank_card_items_account_number_not_blank'),

  accountNumberNoOuterWhitespace(
    'chk_bank_card_items_account_number_no_outer_whitespace',
  ),

  routingNumberNotBlank('chk_bank_card_items_routing_number_not_blank'),

  routingNumberNoOuterWhitespace(
    'chk_bank_card_items_routing_number_no_outer_whitespace',
  );

  const BankCardItemConstraint(this.constraintName);

  final String constraintName;
}

enum BankCardItemIndex {
  cardType('idx_bank_card_items_card_type'),

  cardNetwork('idx_bank_card_items_card_network'),

  expiryYearMonth('idx_bank_card_items_expiry_year_month'),

  bankName('idx_bank_card_items_bank_name'),

  expiringCards('idx_bank_card_items_expiring_cards');

  const BankCardItemIndex(this.indexName);

  final String indexName;
}

final List<String> bankCardItemsTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${BankCardItemIndex.cardType.indexName}
  ON bank_card_items(card_type)
  WHERE card_type IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${BankCardItemIndex.cardNetwork.indexName}
  ON bank_card_items(card_network)
  WHERE card_network IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${BankCardItemIndex.expiryYearMonth.indexName}
  ON bank_card_items(expiry_year, expiry_month)
  WHERE expiry_year IS NOT NULL AND expiry_month IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${BankCardItemIndex.bankName.indexName}
  ON bank_card_items(bank_name)
  WHERE bank_name IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${BankCardItemIndex.expiringCards.indexName}
  ON bank_card_items(expiry_year, expiry_month, item_id)
  WHERE expiry_year IS NOT NULL AND expiry_month IS NOT NULL;
  ''',
];

enum BankCardItemTrigger {
  validateVaultItemTypeOnInsert(
    'trg_bank_card_items_validate_vault_item_type_on_insert',
  ),

  validateVaultItemTypeOnUpdate(
    'trg_bank_card_items_validate_vault_item_type_on_update',
  ),

  preventItemIdUpdate('trg_bank_card_items_prevent_item_id_update');

  const BankCardItemTrigger(this.triggerName);

  final String triggerName;
}

enum BankCardItemRaise {
  invalidVaultItemType(
    'bank_card_items.item_id must reference vault_items.id with type = bankCard',
  ),

  itemIdImmutable('bank_card_items.item_id is immutable');

  const BankCardItemRaise(this.message);

  final String message;
}

final List<String> bankCardItemsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${BankCardItemTrigger.validateVaultItemTypeOnInsert.triggerName}
  BEFORE INSERT ON bank_card_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'bankCard'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${BankCardItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${BankCardItemTrigger.validateVaultItemTypeOnUpdate.triggerName}
  BEFORE UPDATE ON bank_card_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'bankCard'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${BankCardItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${BankCardItemTrigger.preventItemIdUpdate.triggerName}
  BEFORE UPDATE OF item_id ON bank_card_items
  FOR EACH ROW
  WHEN NEW.item_id <> OLD.item_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${BankCardItemRaise.itemIdImmutable.message}'
    );
  END;
  ''',
];
