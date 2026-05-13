import 'package:drift/drift.dart';

import '../vault_items/vault_snapshots_history.dart';
import 'bank_card_items.dart';

/// History-таблица для специфичных полей банковской карты.
///
/// Данные вставляются только через snapshot-сервис/триггеры.
/// Секретные поля вроде cardNumber/cvv могут быть NULL,
/// если включён режим истории без сохранения секретов.
@DataClassName('BankCardHistoryData')
class BankCardHistory extends Table {
  /// PK и FK → vault_snapshots_history.id ON DELETE CASCADE.
  ///
  /// Один snapshot базового vault item имеет максимум одну
  /// snapshot-запись банковской карты.
  TextColumn get historyId => text().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

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

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'bank_card_history';

  @override
  List<String> get customConstraints => [
    '''
        CONSTRAINT ${BankCardHistoryConstraint.historyIdNotBlank.constraintName}
        CHECK (
          length(trim(history_id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${BankCardHistoryConstraint.cardholderNameNotBlank.constraintName}
        CHECK (
          cardholder_name IS NULL
          OR length(trim(cardholder_name)) > 0
        )
        ''',

    '''
        CONSTRAINT ${BankCardHistoryConstraint.cardholderNameNoOuterWhitespace.constraintName}
        CHECK (
          cardholder_name IS NULL
          OR cardholder_name = trim(cardholder_name)
        )
        ''',

    '''
        CONSTRAINT ${BankCardHistoryConstraint.cardNumberNotBlank.constraintName}
        CHECK (
          card_number IS NULL
          OR length(trim(card_number)) > 0
        )
        ''',

    '''
        CONSTRAINT ${BankCardHistoryConstraint.cardNumberNoOuterWhitespace.constraintName}
        CHECK (
          card_number IS NULL
          OR card_number = trim(card_number)
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
        CONSTRAINT ${BankCardHistoryConstraint.cardTypeOtherNoOuterWhitespace.constraintName}
        CHECK (
          card_type_other IS NULL
          OR card_type_other = trim(card_type_other)
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
        CONSTRAINT ${BankCardHistoryConstraint.cardNetworkOtherNoOuterWhitespace.constraintName}
        CHECK (
          card_network_other IS NULL
          OR card_network_other = trim(card_network_other)
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
        CONSTRAINT ${BankCardHistoryConstraint.cvvNotBlank.constraintName}
        CHECK (
          cvv IS NULL
          OR length(trim(cvv)) > 0
        )
        ''',

    '''
        CONSTRAINT ${BankCardHistoryConstraint.cvvNoOuterWhitespace.constraintName}
        CHECK (
          cvv IS NULL
          OR cvv = trim(cvv)
        )
        ''',

    '''
        CONSTRAINT ${BankCardHistoryConstraint.cvvLengthValid.constraintName}
        CHECK (
          cvv IS NULL
          OR length(cvv) BETWEEN 3 AND 8
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
        CONSTRAINT ${BankCardHistoryConstraint.bankNameNoOuterWhitespace.constraintName}
        CHECK (
          bank_name IS NULL
          OR bank_name = trim(bank_name)
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
        CONSTRAINT ${BankCardHistoryConstraint.accountNumberNoOuterWhitespace.constraintName}
        CHECK (
          account_number IS NULL
          OR account_number = trim(account_number)
        )
        ''',

    '''
        CONSTRAINT ${BankCardHistoryConstraint.routingNumberNotBlank.constraintName}
        CHECK (
          routing_number IS NULL
          OR length(trim(routing_number)) > 0
        )
        ''',

    '''
        CONSTRAINT ${BankCardHistoryConstraint.routingNumberNoOuterWhitespace.constraintName}
        CHECK (
          routing_number IS NULL
          OR routing_number = trim(routing_number)
        )
        ''',
  ];
}

enum BankCardHistoryConstraint {
  historyIdNotBlank('chk_bank_card_history_history_id_not_blank'),

  cardholderNameNotBlank('chk_bank_card_history_cardholder_name_not_blank'),

  cardholderNameNoOuterWhitespace(
    'chk_bank_card_history_cardholder_name_no_outer_whitespace',
  ),

  cardNumberNotBlank('chk_bank_card_history_card_number_not_blank'),

  cardNumberNoOuterWhitespace(
    'chk_bank_card_history_card_number_no_outer_whitespace',
  ),

  cardTypeOtherRequired('chk_bank_card_history_card_type_other_required'),

  cardTypeOtherMustBeNull('chk_bank_card_history_card_type_other_must_be_null'),

  cardTypeOtherNoOuterWhitespace(
    'chk_bank_card_history_card_type_other_no_outer_whitespace',
  ),

  cardNetworkOtherRequired('chk_bank_card_history_card_network_other_required'),

  cardNetworkOtherMustBeNull(
    'chk_bank_card_history_card_network_other_must_be_null',
  ),

  cardNetworkOtherNoOuterWhitespace(
    'chk_bank_card_history_card_network_other_no_outer_whitespace',
  ),

  expiryMonthValid('chk_bank_card_history_expiry_month_valid'),

  expiryYearValid('chk_bank_card_history_expiry_year_valid'),

  expiryMonthYearBothNullOrBothSet(
    'chk_bank_card_history_expiry_month_year_both_null_or_both_set',
  ),

  cvvNotBlank('chk_bank_card_history_cvv_not_blank'),

  cvvNoOuterWhitespace('chk_bank_card_history_cvv_no_outer_whitespace'),

  cvvLengthValid('chk_bank_card_history_cvv_length_valid'),

  bankNameNotBlank('chk_bank_card_history_bank_name_not_blank'),

  bankNameNoOuterWhitespace(
    'chk_bank_card_history_bank_name_no_outer_whitespace',
  ),

  accountNumberNotBlank('chk_bank_card_history_account_number_not_blank'),

  accountNumberNoOuterWhitespace(
    'chk_bank_card_history_account_number_no_outer_whitespace',
  ),

  routingNumberNotBlank('chk_bank_card_history_routing_number_not_blank'),

  routingNumberNoOuterWhitespace(
    'chk_bank_card_history_routing_number_no_outer_whitespace',
  );

  const BankCardHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum BankCardHistoryIndex {
  cardType('idx_bank_card_history_card_type'),

  cardNetwork('idx_bank_card_history_card_network'),

  expiringCards('idx_bank_card_history_expiring_cards'),

  bankName('idx_bank_card_history_bank_name');

  const BankCardHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> bankCardHistoryTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${BankCardHistoryIndex.cardType.indexName}
  ON bank_card_history(card_type)
  WHERE card_type IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${BankCardHistoryIndex.cardNetwork.indexName}
  ON bank_card_history(card_network)
  WHERE card_network IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${BankCardHistoryIndex.expiringCards.indexName}
  ON bank_card_history(expiry_year, expiry_month, history_id)
  WHERE expiry_year IS NOT NULL AND expiry_month IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${BankCardHistoryIndex.bankName.indexName}
  ON bank_card_history(bank_name)
  WHERE bank_name IS NOT NULL;
  ''',
];

enum BankCardHistoryTrigger {
  validateSnapshotTypeOnInsert(
    'trg_bank_card_history_validate_snapshot_type_on_insert',
  ),

  preventUpdate('trg_bank_card_history_prevent_update');

  const BankCardHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum BankCardHistoryRaise {
  invalidSnapshotType(
    'bank_card_history.history_id must reference vault_snapshots_history.id with type = bankCard',
  ),

  historyIsImmutable('bank_card_history rows are immutable');

  const BankCardHistoryRaise(this.message);

  final String message;
}

final List<String> bankCardHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${BankCardHistoryTrigger.validateSnapshotTypeOnInsert.triggerName}
  BEFORE INSERT ON bank_card_history
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_snapshots_history
    WHERE id = NEW.history_id
      AND type = 'bankCard'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${BankCardHistoryRaise.invalidSnapshotType.message}'
    );
  END;
  ''',
  '''
  CREATE TRIGGER IF NOT EXISTS ${BankCardHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON bank_card_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${BankCardHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
