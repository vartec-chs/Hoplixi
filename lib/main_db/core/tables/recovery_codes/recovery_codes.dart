import 'package:drift/drift.dart';

import 'recovery_codes_items.dart';

@DataClassName('RecoveryCodeData')
class RecoveryCodes extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get itemId => text().references(
        RecoveryCodesItems,
        #itemId,
        onDelete: KeyAction.cascade,
      )();

  /// Recovery code.
  ///
  /// Секретное значение. Не ограничиваем длину:
  /// у разных сервисов форматы recovery codes отличаются.
  TextColumn get code => text()();

  /// Использован ли код.
  BoolColumn get used => boolean().withDefault(const Constant(false))();

  /// Дата использования.
  DateTimeColumn get usedAt => dateTime().nullable()();

  /// Позиция кода в исходном списке.
  IntColumn get position => integer().nullable()();

  /// Дополнительные метаданные в JSON-формате.
  ///
  /// Например: importInfo, originalLine, label, group.
  TextColumn get metadata => text().nullable()();

  @override
  String get tableName => 'recovery_codes';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${RecoveryCodeConstraint.codeNotBlank.constraintName}
    CHECK (
      length(trim(code)) > 0
    )
    ''',
    '''
    CONSTRAINT ${RecoveryCodeConstraint.usedAtConsistency.constraintName}
    CHECK (
      (used = 1 AND used_at IS NOT NULL)
      OR
      (used = 0 AND used_at IS NULL)
    )
    ''',
    '''
    CONSTRAINT ${RecoveryCodeConstraint.positionPositive.constraintName}
    CHECK (
      position IS NULL
      OR position > 0
    )
    ''',
  ];
}

enum RecoveryCodeConstraint {
  codeNotBlank(
    'chk_recovery_codes_code_not_blank',
  ),

  usedAtConsistency(
    'chk_recovery_codes_used_at_consistency',
  ),

  positionPositive(
    'chk_recovery_codes_position_positive',
  );

  const RecoveryCodeConstraint(this.constraintName);

  final String constraintName;
}

enum RecoveryCodeIndex {
  itemId('idx_recovery_codes_item_id'),
  used('idx_recovery_codes_used'),
  usedAt('idx_recovery_codes_used_at'),
  position('idx_recovery_codes_position'),
  itemPosition('idx_recovery_codes_item_id_position');

  const RecoveryCodeIndex(this.indexName);

  final String indexName;
}

final List<String> recoveryCodesTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${RecoveryCodeIndex.itemId.indexName} ON recovery_codes(item_id);',
  'CREATE INDEX IF NOT EXISTS ${RecoveryCodeIndex.used.indexName} ON recovery_codes(used);',
  'CREATE INDEX IF NOT EXISTS ${RecoveryCodeIndex.usedAt.indexName} ON recovery_codes(used_at);',
  'CREATE INDEX IF NOT EXISTS ${RecoveryCodeIndex.position.indexName} ON recovery_codes(position);',
  'CREATE INDEX IF NOT EXISTS ${RecoveryCodeIndex.itemPosition.indexName} ON recovery_codes(item_id, position);',
];