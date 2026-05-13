import 'package:drift/drift.dart';

import '../vault_items/vault_snapshots_history.dart';
import 'loyalty_card_items.dart';

/// History-таблица для специфичных полей карты лояльности.
///
/// Данные вставляются только триггерами.
/// Секретные поля cardNumber и barcodeValue могут быть NULL, если включён режим
/// истории без сохранения секретов.
@DataClassName('LoyaltyCardHistoryData')
class LoyaltyCardHistory extends Table {
  TextColumn get historyId => text().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Название программы лояльности snapshot.
  TextColumn get programName => text().withLength(min: 1, max: 255)();

  /// Номер карты snapshot.
  TextColumn get cardNumber => text().nullable()();

  /// Значение штрихкода/QR-кода snapshot.
  TextColumn get barcodeValue => text().nullable()();

  /// Тип штрихкода/QR-кода snapshot.
  TextColumn get barcodeType => textEnum<LoyaltyBarcodeType>().nullable()();

  /// Дополнительный тип штрихкода, если barcodeType = other.
  TextColumn get barcodeTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Эмитент или оператор программы snapshot.
  TextColumn get issuer => text().withLength(min: 1, max: 255).nullable()();

  /// Сайт программы snapshot.
  TextColumn get website => text().withLength(min: 1, max: 2048).nullable()();

  /// Телефон поддержки snapshot.
  TextColumn get phone => text().withLength(min: 1, max: 64).nullable()();

  /// Email поддержки или аккаунта программы snapshot.
  TextColumn get email => text().withLength(min: 1, max: 255).nullable()();

  /// Баллы/очки по карте snapshot.
  IntColumn get points => integer().nullable()();

  /// Дата начала действия карты snapshot.
  DateTimeColumn get validFrom => dateTime().nullable()();

  /// Дата окончания действия карты snapshot.
  DateTimeColumn get validTo => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'loyalty_card_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.historyIdNotBlank.constraintName}
    CHECK (
      length(trim(history_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.programNameNotBlank.constraintName}
    CHECK (
      length(trim(program_name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.programNameNoOuterWhitespace.constraintName}
    CHECK (
      program_name = trim(program_name)
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.cardNumberNotBlank.constraintName}
    CHECK (
      card_number IS NULL
      OR length(trim(card_number)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.barcodeValueNotBlank.constraintName}
    CHECK (
      barcode_value IS NULL
      OR length(trim(barcode_value)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.barcodeTypeOtherRequired.constraintName}
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
    CONSTRAINT ${LoyaltyCardHistoryConstraint.barcodeTypeOtherMustBeNull.constraintName}
    CHECK (
      barcode_type = 'other'
      OR barcode_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.barcodeTypeOtherNoOuterWhitespace.constraintName}
    CHECK (
      barcode_type_other IS NULL
      OR barcode_type_other = trim(barcode_type_other)
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.issuerNotBlank.constraintName}
    CHECK (
      issuer IS NULL
      OR length(trim(issuer)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.issuerNoOuterWhitespace.constraintName}
    CHECK (
      issuer IS NULL
      OR issuer = trim(issuer)
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.websiteNotBlank.constraintName}
    CHECK (
      website IS NULL
      OR length(trim(website)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.websiteNoOuterWhitespace.constraintName}
    CHECK (
      website IS NULL
      OR website = trim(website)
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.phoneNotBlank.constraintName}
    CHECK (
      phone IS NULL
      OR length(trim(phone)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.phoneNoOuterWhitespace.constraintName}
    CHECK (
      phone IS NULL
      OR phone = trim(phone)
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.emailNotBlank.constraintName}
    CHECK (
      email IS NULL
      OR length(trim(email)) > 0
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.emailNoOuterWhitespace.constraintName}
    CHECK (
      email IS NULL
      OR email = trim(email)
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.pointsNonNegative.constraintName}
    CHECK (
      points IS NULL
      OR points >= 0
    )
    ''',

    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.validDateRange.constraintName}
    CHECK (
      valid_from IS NULL
      OR valid_to IS NULL
      OR valid_from <= valid_to
    )
    ''',
  ];
}

enum LoyaltyCardHistoryConstraint {
  historyIdNotBlank('chk_loyalty_card_history_history_id_not_blank'),

  programNameNotBlank('chk_loyalty_card_history_program_name_not_blank'),

  programNameNoOuterWhitespace(
    'chk_loyalty_card_history_program_name_no_outer_whitespace',
  ),

  cardNumberNotBlank('chk_loyalty_card_history_card_number_not_blank'),

  barcodeValueNotBlank('chk_loyalty_card_history_barcode_value_not_blank'),

  barcodeTypeOtherRequired(
    'chk_loyalty_card_history_barcode_type_other_required',
  ),

  barcodeTypeOtherMustBeNull(
    'chk_loyalty_card_history_barcode_type_other_must_be_null',
  ),

  barcodeTypeOtherNoOuterWhitespace(
    'chk_loyalty_card_history_barcode_type_other_no_outer_whitespace',
  ),

  issuerNotBlank('chk_loyalty_card_history_issuer_not_blank'),

  issuerNoOuterWhitespace(
    'chk_loyalty_card_history_issuer_no_outer_whitespace',
  ),

  websiteNotBlank('chk_loyalty_card_history_website_not_blank'),

  websiteNoOuterWhitespace(
    'chk_loyalty_card_history_website_no_outer_whitespace',
  ),

  phoneNotBlank('chk_loyalty_card_history_phone_not_blank'),

  phoneNoOuterWhitespace('chk_loyalty_card_history_phone_no_outer_whitespace'),

  emailNotBlank('chk_loyalty_card_history_email_not_blank'),

  emailNoOuterWhitespace('chk_loyalty_card_history_email_no_outer_whitespace'),

  pointsNonNegative('chk_loyalty_card_history_points_non_negative'),

  validDateRange('chk_loyalty_card_history_valid_date_range');

  const LoyaltyCardHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum LoyaltyCardHistoryIndex {
  programName('idx_loyalty_card_history_program_name'),
  issuer('idx_loyalty_card_history_issuer'),
  barcodeType('idx_loyalty_card_history_barcode_type'),
  validTo('idx_loyalty_card_history_valid_to');

  const LoyaltyCardHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> loyaltyCardHistoryTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${LoyaltyCardHistoryIndex.programName.indexName}
  ON loyalty_card_history(program_name)
  WHERE program_name IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${LoyaltyCardHistoryIndex.issuer.indexName}
  ON loyalty_card_history(issuer)
  WHERE issuer IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${LoyaltyCardHistoryIndex.barcodeType.indexName}
  ON loyalty_card_history(barcode_type)
  WHERE barcode_type IS NOT NULL;
  ''',
  '''
  CREATE INDEX IF NOT EXISTS ${LoyaltyCardHistoryIndex.validTo.indexName}
  ON loyalty_card_history(valid_to)
  WHERE valid_to IS NOT NULL;
  ''',
];

enum LoyaltyCardHistoryTrigger {
  validateSnapshotTypeOnInsert(
    'trg_loyalty_card_history_validate_snapshot_type_on_insert',
  ),

  preventUpdate('trg_loyalty_card_history_prevent_update');

  const LoyaltyCardHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum LoyaltyCardHistoryRaise {
  invalidSnapshotType(
    'loyalty_card_history.history_id must reference vault_snapshots_history.id with type = loyaltyCard',
  ),

  historyIsImmutable('loyalty_card_history rows are immutable');

  const LoyaltyCardHistoryRaise(this.message);

  final String message;
}

final List<String> loyaltyCardHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${LoyaltyCardHistoryTrigger.validateSnapshotTypeOnInsert.triggerName}
  BEFORE INSERT ON loyalty_card_history
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_snapshots_history
    WHERE id = NEW.history_id
      AND type = 'loyaltyCard'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${LoyaltyCardHistoryRaise.invalidSnapshotType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${LoyaltyCardHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON loyalty_card_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${LoyaltyCardHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
