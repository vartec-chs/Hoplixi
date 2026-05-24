import 'package:drift/drift.dart';

import '../vault_items/vault_snapshots_history.dart';
import 'ssh_key_items.dart';

/// History-таблица для специфичных полей SSH-ключа.
///
/// Данные вставляются только триггерами.
/// Секретное поле privateKey может быть NULL,
/// если включён режим истории без сохранения секретов.
@DataClassName('SshKeyHistoryData')
class SshKeyHistory extends Table {
  TextColumn get historyId => text().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Публичный ключ snapshot.
  TextColumn get publicKey => text().nullable()();

  /// Приватный ключ snapshot.
  ///
  /// Nullable intentionally:
  /// history may store metadata-only snapshots depending on secret history policy.
  TextColumn get privateKey => text().nullable()();

  /// Тип ключа snapshot.
  TextColumn get keyType => textEnum<SshKeyType>().nullable()();

  /// Дополнительный тип ключа, если keyType = other.
  TextColumn get keyTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Размер ключа snapshot.
  IntColumn get keySize => integer().nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'ssh_key_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${SshKeyHistoryConstraint.historyIdNotBlank.constraintName}
    CHECK (
      length(trim(history_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${SshKeyHistoryConstraint.publicKeyNotBlank.constraintName}
    CHECK (
      public_key IS NULL
      OR length(trim(public_key)) > 0
    )
    ''',

    '''
    CONSTRAINT ${SshKeyHistoryConstraint.privateKeyNotBlank.constraintName}
    CHECK (
      private_key IS NULL
      OR length(trim(private_key)) > 0
    )
    ''',

    '''
    CONSTRAINT ${SshKeyHistoryConstraint.keyTypeOtherRequired.constraintName}
    CHECK (
      key_type IS NULL
      OR key_type != 'other'
      OR (
        key_type_other IS NOT NULL
        AND length(trim(key_type_other)) > 0
      )
    )
    ''',

    '''
    CONSTRAINT ${SshKeyHistoryConstraint.keyTypeOtherMustBeNull.constraintName}
    CHECK (
      key_type = 'other'
      OR key_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${SshKeyHistoryConstraint.keyTypeOtherNoOuterWhitespace.constraintName}
    CHECK (
      key_type_other IS NULL
      OR key_type_other = trim(key_type_other)
    )
    ''',

    '''
    CONSTRAINT ${SshKeyHistoryConstraint.keySizePositive.constraintName}
    CHECK (
      key_size IS NULL
      OR key_size > 0
    )
    ''',
  ];
}

enum SshKeyHistoryConstraint {
  historyIdNotBlank('chk_ssh_key_history_history_id_not_blank'),

  publicKeyNotBlank('chk_ssh_key_history_public_key_not_blank'),

  privateKeyNotBlank('chk_ssh_key_history_private_key_not_blank'),

  keyTypeOtherRequired('chk_ssh_key_history_key_type_other_required'),

  keyTypeOtherMustBeNull('chk_ssh_key_history_key_type_other_must_be_null'),

  keyTypeOtherNoOuterWhitespace(
    'chk_ssh_key_history_key_type_other_no_outer_whitespace',
  ),

  keySizePositive('chk_ssh_key_history_key_size_positive');

  const SshKeyHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum SshKeyHistoryIndex {
  keyType('idx_ssh_key_history_key_type');

  const SshKeyHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> sshKeyHistoryTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${SshKeyHistoryIndex.keyType.indexName}
  ON ssh_key_history(key_type)
  WHERE key_type IS NOT NULL;
  ''',
];

enum SshKeyHistoryTrigger {
  validateSnapshotTypeOnInsert(
    'trg_ssh_key_history_validate_snapshot_type_on_insert',
  ),

  preventUpdate('trg_ssh_key_history_prevent_update');

  const SshKeyHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum SshKeyHistoryRaise {
  invalidSnapshotType(
    'ssh_key_history.history_id must reference vault_snapshots_history.id with type = sshKey',
  ),

  historyIsImmutable('ssh_key_history rows are immutable');

  const SshKeyHistoryRaise(this.message);

  final String message;
}

final List<String> sshKeyHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${SshKeyHistoryTrigger.validateSnapshotTypeOnInsert.triggerName}
  BEFORE INSERT ON ssh_key_history
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_snapshots_history
    WHERE id = NEW.history_id
      AND type = 'sshKey'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${SshKeyHistoryRaise.invalidSnapshotType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${SshKeyHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON ssh_key_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${SshKeyHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
