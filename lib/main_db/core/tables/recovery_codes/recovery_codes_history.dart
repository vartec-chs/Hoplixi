import 'package:drift/drift.dart';

import '../vault_items/vault_item_history.dart';

/// History-таблица для специфичных полей recovery codes.
///
/// Данные вставляются только триггерами.
/// Сами коды обычно хранятся в отдельной таблице `recovery_codes`.
@DataClassName('RecoveryCodesHistoryData')
class RecoveryCodesHistory extends Table {
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// UUID снимка для группировки связанных записей.
  TextColumn get snapshotId => text().nullable()();

  /// Snapshot общего количества кодов.
  IntColumn get codesCount => integer().withDefault(const Constant(0))();

  /// Snapshot количества использованных кодов.
  IntColumn get usedCount => integer().withDefault(const Constant(0))();

  /// Snapshot даты генерации набора recovery codes.
  DateTimeColumn get generatedAt => dateTime().nullable()();

  /// Snapshot признака одноразового набора.
  BoolColumn get oneTime => boolean().withDefault(const Constant(false))();

  /// Дополнительные метаданные snapshot.
  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'recovery_codes_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${RecoveryCodesHistoryConstraint.codesCountNonNegative.constraintName}
    CHECK (
      codes_count >= 0
    )
    ''',
    '''
    CONSTRAINT ${RecoveryCodesHistoryConstraint.usedCountNonNegative.constraintName}
    CHECK (
      used_count >= 0
    )
    ''',
    '''
    CONSTRAINT ${RecoveryCodesHistoryConstraint.usedCountNotGreaterThanCodesCount.constraintName}
    CHECK (
      used_count <= codes_count
    )
    ''',
  ];
}

enum RecoveryCodesHistoryConstraint {
  codesCountNonNegative('chk_recovery_codes_history_codes_count_non_negative'),

  usedCountNonNegative('chk_recovery_codes_history_used_count_non_negative'),

  usedCountNotGreaterThanCodesCount(
    'chk_recovery_codes_history_used_count_not_greater_than_codes_count',
  );

  const RecoveryCodesHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum RecoveryCodesHistoryIndex {
  generatedAt('idx_recovery_codes_history_generated_at'),
  oneTime('idx_recovery_codes_history_one_time');

  const RecoveryCodesHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> recoveryCodesHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${RecoveryCodesHistoryIndex.generatedAt.indexName} ON recovery_codes_history(generated_at);',
  'CREATE INDEX IF NOT EXISTS ${RecoveryCodesHistoryIndex.oneTime.indexName} ON recovery_codes_history(one_time);',
];
