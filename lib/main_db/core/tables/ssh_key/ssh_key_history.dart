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
  TextColumn get historyId =>
      text().references(VaultSnapshotsHistory, #id, onDelete: KeyAction.cascade)();

  /// UUID снимка для группировки связанных записей.
  TextColumn get snapshotId => text().nullable()();

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

  /// Fingerprint snapshot.
  TextColumn get fingerprint =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Кто/что создало ключ snapshot.
  TextColumn get createdBy => text().withLength(min: 1, max: 255).nullable()();

  /// Добавлен ли ключ в ssh-agent snapshot.
  BoolColumn get addedToAgent => boolean().withDefault(const Constant(false))();

  /// Контекст использования snapshot.
  TextColumn get usage => text().withLength(min: 1, max: 255).nullable()();

  /// Дополнительные метаданные snapshot.
  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'ssh_key_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${SshKeyHistoryConstraint.keyMaterialRequired.constraintName}
    CHECK (
      public_key IS NOT NULL
      OR private_key IS NOT NULL
      OR fingerprint IS NOT NULL
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
    CONSTRAINT ${SshKeyHistoryConstraint.keySizePositive.constraintName}
    CHECK (
      key_size IS NULL
      OR key_size > 0
    )
    ''',

    '''
    CONSTRAINT ${SshKeyHistoryConstraint.fingerprintNotBlank.constraintName}
    CHECK (
      fingerprint IS NULL
      OR length(trim(fingerprint)) > 0
    )
    ''',

    '''
    CONSTRAINT ${SshKeyHistoryConstraint.createdByNotBlank.constraintName}
    CHECK (
      created_by IS NULL
      OR length(trim(created_by)) > 0
    )
    ''',

    '''
    CONSTRAINT ${SshKeyHistoryConstraint.usageNotBlank.constraintName}
    CHECK (
      usage IS NULL
      OR length(trim(usage)) > 0
    )
    ''',
  ];
}

enum SshKeyHistoryConstraint {
  keyMaterialRequired('chk_ssh_key_history_key_material_required'),

  publicKeyNotBlank('chk_ssh_key_history_public_key_not_blank'),

  privateKeyNotBlank('chk_ssh_key_history_private_key_not_blank'),

  keyTypeOtherRequired('chk_ssh_key_history_key_type_other_required'),

  keyTypeOtherMustBeNull('chk_ssh_key_history_key_type_other_must_be_null'),

  keySizePositive('chk_ssh_key_history_key_size_positive'),

  fingerprintNotBlank('chk_ssh_key_history_fingerprint_not_blank'),

  createdByNotBlank('chk_ssh_key_history_created_by_not_blank'),

  usageNotBlank('chk_ssh_key_history_usage_not_blank');

  const SshKeyHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum SshKeyHistoryIndex {
  keyType('idx_ssh_key_history_key_type'),
  fingerprint('idx_ssh_key_history_fingerprint'),
  addedToAgent('idx_ssh_key_history_added_to_agent'),
  createdBy('idx_ssh_key_history_created_by');

  const SshKeyHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> sshKeyHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${SshKeyHistoryIndex.keyType.indexName} ON ssh_key_history(key_type);',
  'CREATE INDEX IF NOT EXISTS ${SshKeyHistoryIndex.fingerprint.indexName} ON ssh_key_history(fingerprint);',
  'CREATE INDEX IF NOT EXISTS ${SshKeyHistoryIndex.addedToAgent.indexName} ON ssh_key_history(added_to_agent);',
  'CREATE INDEX IF NOT EXISTS ${SshKeyHistoryIndex.createdBy.indexName} ON ssh_key_history(created_by);',
];
