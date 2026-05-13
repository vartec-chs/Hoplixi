import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

enum SshKeyType { rsa, ed25519, ecdsa, dsa, other }

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

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'ssh_key_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${SshKeyItemConstraint.itemIdNotBlank.constraintName}
    CHECK (
      length(trim(item_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${SshKeyItemConstraint.authMaterialRequired.constraintName}
    CHECK (
      public_key IS NOT NULL
      OR private_key IS NOT NULL
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
    CONSTRAINT ${SshKeyItemConstraint.keyTypeOtherNoOuterWhitespace.constraintName}
    CHECK (
      key_type_other IS NULL
      OR key_type_other = trim(key_type_other)
    )
    ''',

    '''
    CONSTRAINT ${SshKeyItemConstraint.keySizePositive.constraintName}
    CHECK (
      key_size IS NULL
      OR key_size > 0
    )
    ''',
  ];
}

enum SshKeyItemConstraint {
  itemIdNotBlank('chk_ssh_key_items_item_id_not_blank'),

  authMaterialRequired('chk_ssh_key_items_auth_material_required'),

  publicKeyNotBlank('chk_ssh_key_items_public_key_not_blank'),

  privateKeyNotBlank('chk_ssh_key_items_private_key_not_blank'),

  keyTypeOtherRequired('chk_ssh_key_items_key_type_other_required'),

  keyTypeOtherMustBeNull('chk_ssh_key_items_key_type_other_must_be_null'),

  keyTypeOtherNoOuterWhitespace(
    'chk_ssh_key_items_key_type_other_no_outer_whitespace',
  ),

  keySizePositive('chk_ssh_key_items_key_size_positive');

  const SshKeyItemConstraint(this.constraintName);

  final String constraintName;
}

enum SshKeyItemIndex {
  keyType('idx_ssh_key_items_key_type');

  const SshKeyItemIndex(this.indexName);

  final String indexName;
}

final List<String> sshKeyItemsTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${SshKeyItemIndex.keyType.indexName}
  ON ssh_key_items(key_type)
  WHERE key_type IS NOT NULL;
  ''',
];

enum SshKeyItemTrigger {
  validateVaultItemTypeOnInsert(
    'trg_ssh_key_items_validate_vault_item_type_on_insert',
  ),

  validateVaultItemTypeOnUpdate(
    'trg_ssh_key_items_validate_vault_item_type_on_update',
  ),

  preventItemIdUpdate('trg_ssh_key_items_prevent_item_id_update');

  const SshKeyItemTrigger(this.triggerName);

  final String triggerName;
}

enum SshKeyItemRaise {
  invalidVaultItemType(
    'ssh_key_items.item_id must reference vault_items.id with type = sshKey',
  ),

  itemIdImmutable('ssh_key_items.item_id is immutable');

  const SshKeyItemRaise(this.message);

  final String message;
}

final List<String> sshKeyItemsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${SshKeyItemTrigger.validateVaultItemTypeOnInsert.triggerName}
  BEFORE INSERT ON ssh_key_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'sshKey'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${SshKeyItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${SshKeyItemTrigger.validateVaultItemTypeOnUpdate.triggerName}
  BEFORE UPDATE ON ssh_key_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'sshKey'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${SshKeyItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${SshKeyItemTrigger.preventItemIdUpdate.triggerName}
  BEFORE UPDATE OF item_id ON ssh_key_items
  FOR EACH ROW
  WHEN NEW.item_id <> OLD.item_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${SshKeyItemRaise.itemIdImmutable.message}'
    );
  END;
  ''',
];
