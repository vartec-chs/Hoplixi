import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

enum CryptoWalletType { software, hardware, paper, watchOnly, multisig, other }

enum CryptoNetwork {
  bitcoin,
  ethereum,
  solana,
  ton,
  tron,
  polygon,
  bsc,
  litecoin,
  monero,
  dogecoin,
  other,
}

enum CryptoDerivationScheme {
  bip32,
  bip39,
  bip44,
  bip49,
  bip84,
  bip86,
  slip10,
  other,
}

@DataClassName('CryptoWalletItemsData')
class CryptoWalletItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Тип кошелька: software, hardware, paper, watchOnly, multisig, other.
  TextColumn get walletType => textEnum<CryptoWalletType>().nullable()();

  /// Дополнительный тип кошелька, если walletType = other.
  TextColumn get walletTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Сеть/блокчейн: bitcoin, ethereum, solana и т.д.
  TextColumn get network => textEnum<CryptoNetwork>().nullable()();

  /// Дополнительная сеть, если network = other.
  TextColumn get networkOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Mnemonic/seed phrase.
  ///
  /// Секретное значение. Не ограничиваем длину.
  TextColumn get mnemonic => text().nullable()();

  /// Приватный ключ.
  ///
  /// Секретное значение. Не ограничиваем длину.
  TextColumn get privateKey => text().nullable()();

  /// Путь деривации, например m/44'/0'/0'/0/0.
  TextColumn get derivationPath =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Схема деривации: BIP32/BIP39/BIP44/BIP84 и т.д.
  TextColumn get derivationScheme =>
      textEnum<CryptoDerivationScheme>().nullable()();

  /// Дополнительная схема деривации, если derivationScheme = other.
  TextColumn get derivationSchemeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Адреса кошелька.
  ///
  /// Хранятся как plain text; один адрес на строку.
  TextColumn get addresses => text().nullable()();

  /// Extended public key.
  TextColumn get xpub => text().nullable()();

  /// Extended private key.
  ///
  /// Секретное значение.
  TextColumn get xprv => text().nullable()();

  /// Аппаратное устройство: Ledger, Trezor и т.д.
  TextColumn get hardwareDevice =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Watch-only кошелёк.
  BoolColumn get watchOnly => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'crypto_wallet_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${CryptoWalletItemConstraint.walletContentRequired.constraintName}
    CHECK (
      mnemonic IS NOT NULL
      OR private_key IS NOT NULL
      OR xpub IS NOT NULL
      OR xprv IS NOT NULL
      OR addresses IS NOT NULL
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletItemConstraint.walletTypeOtherRequired.constraintName}
    CHECK (
      wallet_type IS NULL
      OR wallet_type != 'other'
      OR (
        wallet_type_other IS NOT NULL
        AND length(trim(wallet_type_other)) > 0
      )
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletItemConstraint.walletTypeOtherMustBeNull.constraintName}
    CHECK (
      wallet_type = 'other'
      OR wallet_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletItemConstraint.networkOtherRequired.constraintName}
    CHECK (
      network IS NULL
      OR network != 'other'
      OR (
        network_other IS NOT NULL
        AND length(trim(network_other)) > 0
      )
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletItemConstraint.networkOtherMustBeNull.constraintName}
    CHECK (
      network = 'other'
      OR network_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletItemConstraint.derivationSchemeOtherRequired.constraintName}
    CHECK (
      derivation_scheme IS NULL
      OR derivation_scheme != 'other'
      OR (
        derivation_scheme_other IS NOT NULL
        AND length(trim(derivation_scheme_other)) > 0
      )
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletItemConstraint.derivationSchemeOtherMustBeNull.constraintName}
    CHECK (
      derivation_scheme = 'other'
      OR derivation_scheme_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletItemConstraint.derivationPathNotBlank.constraintName}
    CHECK (
      derivation_path IS NULL
      OR length(trim(derivation_path)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletItemConstraint.hardwareDeviceNotBlank.constraintName}
    CHECK (
      hardware_device IS NULL
      OR length(trim(hardware_device)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletItemConstraint.watchOnlyHasPublicData.constraintName}
    CHECK (
      watch_only = 0
      OR (
        mnemonic IS NULL
        AND private_key IS NULL
        AND xprv IS NULL
        AND (
          xpub IS NOT NULL
          OR addresses IS NOT NULL
        )
      )
    )
    ''',
  ];
}

enum CryptoWalletItemConstraint {
  walletContentRequired('chk_crypto_wallet_items_content_required'),

  walletTypeOtherRequired('chk_crypto_wallet_items_wallet_type_other_required'),

  walletTypeOtherMustBeNull(
    'chk_crypto_wallet_items_wallet_type_other_must_be_null',
  ),

  networkOtherRequired('chk_crypto_wallet_items_network_other_required'),

  networkOtherMustBeNull('chk_crypto_wallet_items_network_other_must_be_null'),

  derivationSchemeOtherRequired(
    'chk_crypto_wallet_items_derivation_scheme_other_required',
  ),

  derivationSchemeOtherMustBeNull(
    'chk_crypto_wallet_items_derivation_scheme_other_must_be_null',
  ),

  derivationPathNotBlank('chk_crypto_wallet_items_derivation_path_not_blank'),

  hardwareDeviceNotBlank('chk_crypto_wallet_items_hardware_device_not_blank'),

  watchOnlyHasPublicData('chk_crypto_wallet_items_watch_only_has_public_data');

  const CryptoWalletItemConstraint(this.constraintName);

  final String constraintName;
}

enum CryptoWalletItemIndex {
  walletType('idx_crypto_wallet_items_wallet_type'),
  network('idx_crypto_wallet_items_network'),
  derivationScheme('idx_crypto_wallet_items_derivation_scheme');

  const CryptoWalletItemIndex(this.indexName);

  final String indexName;
}

final List<String> cryptoWalletItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${CryptoWalletItemIndex.walletType.indexName} ON crypto_wallet_items(wallet_type);',
  'CREATE INDEX IF NOT EXISTS ${CryptoWalletItemIndex.network.indexName} ON crypto_wallet_items(network);',
  'CREATE INDEX IF NOT EXISTS ${CryptoWalletItemIndex.derivationScheme.indexName} ON crypto_wallet_items(derivation_scheme);',
];

enum CryptoWalletItemTrigger {
  validateVaultItemTypeOnInsert(
    'trg_crypto_wallet_items_validate_vault_item_type_on_insert',
  ),

  validateVaultItemTypeOnUpdate(
    'trg_crypto_wallet_items_validate_vault_item_type_on_update',
  ),

  preventItemIdUpdate('trg_crypto_wallet_items_prevent_item_id_update');

  const CryptoWalletItemTrigger(this.triggerName);

  final String triggerName;
}

enum CryptoWalletItemRaise {
  invalidVaultItemType(
    'crypto_wallet_items.item_id must reference vault_items.id with type = cryptoWallet',
  ),

  itemIdImmutable('crypto_wallet_items.item_id is immutable');

  const CryptoWalletItemRaise(this.message);

  final String message;
}

final List<String> cryptoWalletItemsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${CryptoWalletItemTrigger.validateVaultItemTypeOnInsert.triggerName}
  BEFORE INSERT ON crypto_wallet_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'cryptoWallet'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${CryptoWalletItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${CryptoWalletItemTrigger.validateVaultItemTypeOnUpdate.triggerName}
  BEFORE UPDATE ON crypto_wallet_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'cryptoWallet'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${CryptoWalletItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${CryptoWalletItemTrigger.preventItemIdUpdate.triggerName}
  BEFORE UPDATE OF item_id ON crypto_wallet_items
  FOR EACH ROW
  WHEN NEW.item_id <> OLD.item_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${CryptoWalletItemRaise.itemIdImmutable.message}'
    );
  END;
  ''',
];
