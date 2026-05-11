import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

@DataClassName('RecoveryCodesItemsData')
class RecoveryCodesItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Кэш: общее количество кодов.
  ///
  /// Обновляется триггерами при изменении recovery_codes.
  IntColumn get codesCount => integer().withDefault(const Constant(0))();

  /// Кэш: количество использованных кодов.
  ///
  /// Обновляется триггерами при изменении recovery_codes.
  IntColumn get usedCount => integer().withDefault(const Constant(0))();

  /// Дата генерации набора recovery codes.
  DateTimeColumn get generatedAt => dateTime().nullable()();

  /// Набор одноразовых кодов.
  BoolColumn get oneTime => boolean().withDefault(const Constant(false))();

  /// Дополнительные метаданные в JSON-формате.
  ///
  /// Например: sourceService, importInfo, generationPolicy,
  /// originalFormat, displayHint.
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'recovery_codes_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${RecoveryCodesItemConstraint.codesCountNonNegative.constraintName}
    CHECK (
      codes_count >= 0
    )
    ''',
    '''
    CONSTRAINT ${RecoveryCodesItemConstraint.usedCountNonNegative.constraintName}
    CHECK (
      used_count >= 0
    )
    ''',
    '''
    CONSTRAINT ${RecoveryCodesItemConstraint.usedCountNotGreaterThanCodesCount.constraintName}
    CHECK (
      used_count <= codes_count
    )
    ''',
  ];
}

enum RecoveryCodesItemConstraint {
  codesCountNonNegative('chk_recovery_codes_items_codes_count_non_negative'),

  usedCountNonNegative('chk_recovery_codes_items_used_count_non_negative'),

  usedCountNotGreaterThanCodesCount(
    'chk_recovery_codes_items_used_count_not_greater_than_codes_count',
  );

  const RecoveryCodesItemConstraint(this.constraintName);

  final String constraintName;
}

enum RecoveryCodesItemIndex {
  generatedAt('idx_recovery_codes_items_generated_at'),
  oneTime('idx_recovery_codes_items_one_time');

  const RecoveryCodesItemIndex(this.indexName);

  final String indexName;
}

final List<String> recoveryCodesItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${RecoveryCodesItemIndex.generatedAt.indexName} ON recovery_codes_items(generated_at);',
  'CREATE INDEX IF NOT EXISTS ${RecoveryCodesItemIndex.oneTime.indexName} ON recovery_codes_items(one_time);',
];
