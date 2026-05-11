import 'package:drift/drift.dart';

import 'loyalty_card_items.dart';
import '../vault_items/vault_item_history.dart';

/// History-таблица для специфичных полей карты лояльности.
///
/// Данные вставляются только триггерами.
/// Секретные поля могут быть NULL, если включён режим истории
/// без сохранения секретов.
@DataClassName('LoyaltyCardHistoryData')
class LoyaltyCardHistory extends Table {
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// Название программы лояльности snapshot.
  TextColumn get programName => text().withLength(min: 1, max: 255)();

  /// Номер карты snapshot.
  TextColumn get cardNumber => text().nullable()();

  /// Имя владельца карты snapshot.
  TextColumn get holderName => text().withLength(min: 1, max: 255).nullable()();

  /// Значение штрихкода/QR-кода snapshot.
  TextColumn get barcodeValue => text().nullable()();

  /// Тип штрихкода/QR-кода snapshot.
  TextColumn get barcodeType => textEnum<LoyaltyBarcodeType>().nullable()();

  /// Дополнительный тип штрихкода, если barcodeType = other.
  TextColumn get barcodeTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Пароль/PIN snapshot.
  ///
  /// Nullable intentionally:
  /// history may store metadata-only snapshots depending on secret history policy.
  TextColumn get password => text().nullable()();

  /// Уровень программы snapshot.
  TextColumn get tier => text().withLength(min: 1, max: 255).nullable()();

  /// Дата окончания действия карты snapshot.
  DateTimeColumn get expiryDate => dateTime().nullable()();

  /// Сайт программы snapshot.
  TextColumn get website => text().withLength(min: 1, max: 2048).nullable()();

  /// Телефон поддержки snapshot.
  TextColumn get phoneNumber => text().withLength(min: 1, max: 64).nullable()();

  /// Дополнительные метаданные snapshot.
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'loyalty_card_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.programNameNotBlank.constraintName}
    CHECK (
      length(trim(program_name)) > 0
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
    CONSTRAINT ${LoyaltyCardHistoryConstraint.holderNameNotBlank.constraintName}
    CHECK (
      holder_name IS NULL
      OR length(trim(holder_name)) > 0
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
    CONSTRAINT ${LoyaltyCardHistoryConstraint.passwordNotBlank.constraintName}
    CHECK (
      password IS NULL
      OR length(trim(password)) > 0
    )
    ''',
    '''
    CONSTRAINT ${LoyaltyCardHistoryConstraint.tierNotBlank.constraintName}
    CHECK (
      tier IS NULL
      OR length(trim(tier)) > 0
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
    CONSTRAINT ${LoyaltyCardHistoryConstraint.phoneNumberNotBlank.constraintName}
    CHECK (
      phone_number IS NULL
      OR length(trim(phone_number)) > 0
    )
    ''',
  ];
}

enum LoyaltyCardHistoryConstraint {
  programNameNotBlank(
    'chk_loyalty_card_history_program_name_not_blank',
  ),

  cardNumberNotBlank(
    'chk_loyalty_card_history_card_number_not_blank',
  ),

  holderNameNotBlank(
    'chk_loyalty_card_history_holder_name_not_blank',
  ),

  barcodeValueNotBlank(
    'chk_loyalty_card_history_barcode_value_not_blank',
  ),

  barcodeTypeOtherRequired(
    'chk_loyalty_card_history_barcode_type_other_required',
  ),

  barcodeTypeOtherMustBeNull(
    'chk_loyalty_card_history_barcode_type_other_must_be_null',
  ),

  passwordNotBlank(
    'chk_loyalty_card_history_password_not_blank',
  ),

  tierNotBlank(
    'chk_loyalty_card_history_tier_not_blank',
  ),

  websiteNotBlank(
    'chk_loyalty_card_history_website_not_blank',
  ),

  phoneNumberNotBlank(
    'chk_loyalty_card_history_phone_number_not_blank',
  );

  const LoyaltyCardHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum LoyaltyCardHistoryIndex {
  programName('idx_loyalty_card_history_program_name'),
  barcodeType('idx_loyalty_card_history_barcode_type'),
  expiryDate('idx_loyalty_card_history_expiry_date'),
  tier('idx_loyalty_card_history_tier');

  const LoyaltyCardHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> loyaltyCardHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${LoyaltyCardHistoryIndex.programName.indexName} ON loyalty_card_history(program_name);',
  'CREATE INDEX IF NOT EXISTS ${LoyaltyCardHistoryIndex.barcodeType.indexName} ON loyalty_card_history(barcode_type);',
  'CREATE INDEX IF NOT EXISTS ${LoyaltyCardHistoryIndex.expiryDate.indexName} ON loyalty_card_history(expiry_date);',
  'CREATE INDEX IF NOT EXISTS ${LoyaltyCardHistoryIndex.tier.indexName} ON loyalty_card_history(tier);',
];