import 'package:drift/drift.dart';

import '../vault_items/vault_item_history.dart';
import 'bank_card_items.dart';

/// History-таблица для специфичных полей банковской карты.
///
/// Данные вставляются только триггерами.
/// Секретные поля вроде cardNumber/cvv могут быть NULL,
/// если включён режим истории без сохранения секретов.
@DataClassName('BankCardHistoryData')
class BankCardHistory extends Table {
  /// PK и FK → vault_item_history.id ON DELETE CASCADE
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// Имя владельца карты snapshot.
  TextColumn get cardholderName =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Номер карты snapshot.
  ///
  /// Nullable intentionally:
  /// history may store metadata-only snapshots depending on secret history policy.
  TextColumn get cardNumber => text().nullable()();

  /// Тип карты snapshot.
  TextColumn get cardType => textEnum<CardType>().nullable()();

  /// Дополнительный тип карты, если cardType = other.
  TextColumn get cardTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Платёжная сеть snapshot.
  TextColumn get cardNetwork => textEnum<CardNetwork>().nullable()();

  /// Дополнительная платёжная сеть, если cardNetwork = other.
  TextColumn get cardNetworkOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Месяц истечения snapshot: MM.
  TextColumn get expiryMonth => text().withLength(min: 2, max: 2).nullable()();

  /// Год истечения snapshot: YYYY.
  TextColumn get expiryYear => text().withLength(min: 4, max: 4).nullable()();

  /// CVV/CVC snapshot.
  ///
  /// Nullable intentionally:
  /// history may store metadata-only snapshots depending on secret history policy.
  TextColumn get cvv => text().nullable()();

  /// Название банка snapshot.
  TextColumn get bankName => text().withLength(min: 1, max: 255).nullable()();

  /// Номер счёта snapshot.
  TextColumn get accountNumber =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Routing number / sort code / bank code snapshot.
  TextColumn get routingNumber =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Дополнительные метаданные в JSON-формате snapshot.
  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'bank_card_history';

  @override
  List<String> get customConstraints => [
    '''
        CONSTRAINT ${BankCardHistoryConstraint.cardholderNameNotBlank.constraintName}
        CHECK (
          cardholder_name IS NULL
          OR length(trim(cardholder_name)) > 0
        )
        ''',

    '''
        CONSTRAINT ${BankCardHistoryConstraint.cardTypeOtherRequired.constraintName}
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
        CONSTRAINT ${BankCardHistoryConstraint.cardTypeOtherMustBeNull.constraintName}
        CHECK (
          card_type = 'other'
          OR card_type_other IS NULL
        )
        ''',

    '''
        CONSTRAINT ${BankCardHistoryConstraint.cardNetworkOtherRequired.constraintName}
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
        CONSTRAINT ${BankCardHistoryConstraint.cardNetworkOtherMustBeNull.constraintName}
        CHECK (
          card_network = 'other'
          OR card_network_other IS NULL
        )
        ''',

    '''
        CONSTRAINT ${BankCardHistoryConstraint.expiryMonthValid.constraintName}
        CHECK (
          expiry_month IS NULL
          OR (
            expiry_month GLOB '[0-9][0-9]'
            AND CAST(expiry_month AS INTEGER) BETWEEN 1 AND 12
          )
        )
        ''',

    '''
        CONSTRAINT ${BankCardHistoryConstraint.expiryYearValid.constraintName}
        CHECK (
          expiry_year IS NULL
          OR expiry_year GLOB '[0-9][0-9][0-9][0-9]'
        )
        ''',

    '''
        CONSTRAINT ${BankCardHistoryConstraint.expiryMonthYearBothNullOrBothSet.constraintName}
        CHECK (
          (expiry_month IS NULL AND expiry_year IS NULL)
          OR
          (expiry_month IS NOT NULL AND expiry_year IS NOT NULL)
        )
        ''',

    '''
        CONSTRAINT ${BankCardHistoryConstraint.bankNameNotBlank.constraintName}
        CHECK (
          bank_name IS NULL
          OR length(trim(bank_name)) > 0
        )
        ''',

    '''
        CONSTRAINT ${BankCardHistoryConstraint.accountNumberNotBlank.constraintName}
        CHECK (
          account_number IS NULL
          OR length(trim(account_number)) > 0
        )
        ''',

    '''
        CONSTRAINT ${BankCardHistoryConstraint.routingNumberNotBlank.constraintName}
        CHECK (
          routing_number IS NULL
          OR length(trim(routing_number)) > 0
        )
        ''',
  ];
}

enum BankCardHistoryConstraint {
  cardholderNameNotBlank('chk_bank_card_history_cardholder_name_not_blank'),

  cardTypeOtherRequired('chk_bank_card_history_card_type_other_required'),

  cardTypeOtherMustBeNull('chk_bank_card_history_card_type_other_must_be_null'),

  cardNetworkOtherRequired('chk_bank_card_history_card_network_other_required'),

  cardNetworkOtherMustBeNull(
    'chk_bank_card_history_card_network_other_must_be_null',
  ),

  expiryMonthValid('chk_bank_card_history_expiry_month_valid'),

  expiryYearValid('chk_bank_card_history_expiry_year_valid'),

  expiryMonthYearBothNullOrBothSet(
    'chk_bank_card_history_expiry_month_year_both_null_or_both_set',
  ),

  bankNameNotBlank('chk_bank_card_history_bank_name_not_blank'),

  accountNumberNotBlank('chk_bank_card_history_account_number_not_blank'),

  routingNumberNotBlank('chk_bank_card_history_routing_number_not_blank');

  const BankCardHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum BankCardHistoryIndex {
  cardType('idx_bank_card_history_card_type'),
  cardNetwork('idx_bank_card_history_card_network'),
  expiryYearMonth('idx_bank_card_history_expiry_year_month'),
  bankName('idx_bank_card_history_bank_name');

  const BankCardHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> bankCardHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${BankCardHistoryIndex.cardType.indexName} ON bank_card_history(card_type);',
  'CREATE INDEX IF NOT EXISTS ${BankCardHistoryIndex.cardNetwork.indexName} ON bank_card_history(card_network);',
  'CREATE INDEX IF NOT EXISTS ${BankCardHistoryIndex.expiryYearMonth.indexName} ON bank_card_history(expiry_year, expiry_month);',
  'CREATE INDEX IF NOT EXISTS ${BankCardHistoryIndex.bankName.indexName} ON bank_card_history(bank_name);',
];
