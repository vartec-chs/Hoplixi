import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

enum SshKeyType {
  rsa,
  ed25519,
  ecdsa,
  dsa,
  other,
}

@DataClassName('SshKeyItemsData')
class SshKeyItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Публичный ключ.
  ///
  /// Может быть NULL, если пользователь хранит только приватный ключ.
  TextColumn get publicKey => text().nullable()();

  /// Приватный ключ.
  ///
  /// Секретное значение. Может быть NULL для public-only записи.
  TextColumn get privateKey => text().nullable()();

  /// Тип ключа: rsa, ed25519, ecdsa, dsa, other.
  TextColumn get keyType => textEnum<SshKeyType>().nullable()();

  /// Дополнительный тип ключа, если keyType = other.
  TextColumn get keyTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Размер ключа, например 2048, 4096.
  ///
  /// В основном полезно для RSA/DSA и аудита слабых ключей.
  IntColumn get keySize => integer().nullable()();

  /// Fingerprint публичного ключа.
  ///
  /// Полезен для идентификации, сравнения и поиска дубликатов.
  TextColumn get fingerprint =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Кто/что создало ключ: user, ssh-keygen, imported, GitHub, server name.
  TextColumn get createdBy =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Добавлен ли ключ в ssh-agent.
  ///
  /// Это пользовательская пометка, а не гарантированное текущее состояние агента.
  BoolColumn get addedToAgent => boolean().withDefault(const Constant(false))();

  /// Контекст использования: server login, git deploy, backup, CI и т.д.
  TextColumn get usage => text().withLength(min: 1, max: 255).nullable()();

  /// Дополнительные метаданные в JSON-формате.
  ///
  /// Например: host, username, port, knownHostsEntry, sourceFileName,
  /// importInfo, agentIdentity, certificateInfo, comment.
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'ssh_key_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${SshKeyItemConstraint.keyMaterialRequired.constraintName}
    CHECK (
      public_key IS NOT NULL
      OR private_key IS NOT NULL
      OR fingerprint IS NOT NULL
    )
    ''',

    '''
    CONSTRAINT ${SshKeyItemConstraint.publicKeyNotBlank.constraintName}
    CHECK (
      public_key IS NULL
      OR length(trim(public_key)) > 0
    )
    ''',

    '''
    CONSTRAINT ${SshKeyItemConstraint.privateKeyNotBlank.constraintName}
    CHECK (
      private_key IS NULL
      OR length(trim(private_key)) > 0
    )
    ''',

    '''
    CONSTRAINT ${SshKeyItemConstraint.keyTypeOtherRequired.constraintName}
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
    CONSTRAINT ${SshKeyItemConstraint.keyTypeOtherMustBeNull.constraintName}
    CHECK (
      key_type = 'other'
      OR key_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${SshKeyItemConstraint.keySizePositive.constraintName}
    CHECK (
      key_size IS NULL
      OR key_size > 0
    )
    ''',

    '''
    CONSTRAINT ${SshKeyItemConstraint.fingerprintNotBlank.constraintName}
    CHECK (
      fingerprint IS NULL
      OR length(trim(fingerprint)) > 0
    )
    ''',

    '''
    CONSTRAINT ${SshKeyItemConstraint.createdByNotBlank.constraintName}
    CHECK (
      created_by IS NULL
      OR length(trim(created_by)) > 0
    )
    ''',

    '''
    CONSTRAINT ${SshKeyItemConstraint.usageNotBlank.constraintName}
    CHECK (
      usage IS NULL
      OR length(trim(usage)) > 0
    )
    ''',
  ];
}

enum SshKeyItemConstraint {
  keyMaterialRequired(
    'chk_ssh_key_items_key_material_required',
  ),

  publicKeyNotBlank(
    'chk_ssh_key_items_public_key_not_blank',
  ),

  privateKeyNotBlank(
    'chk_ssh_key_items_private_key_not_blank',
  ),

  keyTypeOtherRequired(
    'chk_ssh_key_items_key_type_other_required',
  ),

  keyTypeOtherMustBeNull(
    'chk_ssh_key_items_key_type_other_must_be_null',
  ),

  keySizePositive(
    'chk_ssh_key_items_key_size_positive',
  ),

  fingerprintNotBlank(
    'chk_ssh_key_items_fingerprint_not_blank',
  ),

  createdByNotBlank(
    'chk_ssh_key_items_created_by_not_blank',
  ),

  usageNotBlank(
    'chk_ssh_key_items_usage_not_blank',
  );

  const SshKeyItemConstraint(this.constraintName);

  final String constraintName;
}

enum SshKeyItemIndex {
  keyType('idx_ssh_key_items_key_type'),
  fingerprint('idx_ssh_key_items_fingerprint'),
  addedToAgent('idx_ssh_key_items_added_to_agent'),
  createdBy('idx_ssh_key_items_created_by');

  const SshKeyItemIndex(this.indexName);

  final String indexName;
}

final List<String> sshKeyItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${SshKeyItemIndex.keyType.indexName} ON ssh_key_items(key_type);',
  'CREATE INDEX IF NOT EXISTS ${SshKeyItemIndex.fingerprint.indexName} ON ssh_key_items(fingerprint);',
  'CREATE INDEX IF NOT EXISTS ${SshKeyItemIndex.addedToAgent.indexName} ON ssh_key_items(added_to_agent);',
  'CREATE INDEX IF NOT EXISTS ${SshKeyItemIndex.createdBy.indexName} ON ssh_key_items(created_by);',
];