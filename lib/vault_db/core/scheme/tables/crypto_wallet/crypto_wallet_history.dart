import 'package:drift/drift.dart';

import '../vault_items/vault_snapshots_history.dart';
import 'crypto_wallet_items.dart';

/// History-таблица для специфичных полей криптокошелька.
///
/// Данные вставляются только триггерами.
/// Секретные поля могут быть NULL, если включён режим истории без сохранения секретов.
@DataClassName('CryptoWalletHistoryData')
class CryptoWalletHistory extends Table {
  TextColumn get historyId => text().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Тип кошелька snapshot.
  TextColumn get walletType => textEnum<CryptoWalletType>().nullable()();

  /// Дополнительный тип кошелька, если walletType = other.
  TextColumn get walletTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Сеть/блокчейн snapshot.
  TextColumn get network => textEnum<CryptoNetwork>().nullable()();

  /// Дополнительная сеть, если network = other.
  TextColumn get networkOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Mnemonic/seed phrase snapshot.
  ///
  /// Nullable intentionally:
  /// history may store metadata-only snapshots depending on secret history policy.
  TextColumn get mnemonic => text().nullable()();

  /// Приватный ключ snapshot.
  ///
  /// Nullable intentionally.
  TextColumn get privateKey => text().nullable()();

  /// Путь деривации snapshot.
  TextColumn get derivationPath =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Схема деривации snapshot.
  TextColumn get derivationScheme =>
      textEnum<CryptoDerivationScheme>().nullable()();

  /// Дополнительная схема деривации, если derivationScheme = other.
  TextColumn get derivationSchemeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Адреса кошелька snapshot.
  ///
  /// Хранятся как plain text; один адрес на строку.
  TextColumn get addresses => text().nullable()();

  /// Extended public key snapshot.
  TextColumn get xpub => text().nullable()();

  /// Extended private key snapshot.
  ///
  /// Nullable intentionally.
  TextColumn get xprv => text().nullable()();

  /// Аппаратное устройство snapshot.
  TextColumn get hardwareDevice =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Watch-only snapshot.
  BoolColumn get watchOnly => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'crypto_wallet_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${CryptoWalletHistoryConstraint.historyIdNotBlank.constraintName}
    CHECK (length(trim(history_id)) > 0)
    ''',

    '''
    CONSTRAINT ${CryptoWalletHistoryConstraint.walletContentRequired.constraintName}
    CHECK (
      mnemonic IS NOT NULL
      OR private_key IS NOT NULL
      OR xpub IS NOT NULL
      OR xprv IS NOT NULL
      OR addresses IS NOT NULL
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletHistoryConstraint.mnemonicNotBlank.constraintName}
    CHECK (
      mnemonic IS NULL
      OR length(trim(mnemonic)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletHistoryConstraint.privateKeyNotBlank.constraintName}
    CHECK (
      private_key IS NULL
      OR length(trim(private_key)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletHistoryConstraint.addressesNotBlank.constraintName}
    CHECK (
      addresses IS NULL
      OR length(trim(addresses)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletHistoryConstraint.xpubNotBlank.constraintName}
    CHECK (
      xpub IS NULL
      OR length(trim(xpub)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletHistoryConstraint.xprvNotBlank.constraintName}
    CHECK (
      xprv IS NULL
      OR length(trim(xprv)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletHistoryConstraint.walletTypeOtherRequired.constraintName}
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
    CONSTRAINT ${CryptoWalletHistoryConstraint.walletTypeOtherMustBeNull.constraintName}
    CHECK (
      wallet_type = 'other'
      OR wallet_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletHistoryConstraint.walletTypeOtherNoOuterWhitespace.constraintName}
    CHECK (
      wallet_type_other IS NULL
      OR wallet_type_other = trim(wallet_type_other)
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletHistoryConstraint.networkOtherRequired.constraintName}
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
    CONSTRAINT ${CryptoWalletHistoryConstraint.networkOtherMustBeNull.constraintName}
    CHECK (
      network = 'other'
      OR network_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletHistoryConstraint.networkOtherNoOuterWhitespace.constraintName}
    CHECK (
      network_other IS NULL
      OR network_other = trim(network_other)
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletHistoryConstraint.derivationSchemeOtherRequired.constraintName}
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
    CONSTRAINT ${CryptoWalletHistoryConstraint.derivationSchemeOtherMustBeNull.constraintName}
    CHECK (
      derivation_scheme = 'other'
      OR derivation_scheme_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletHistoryConstraint.derivationSchemeOtherNoOuterWhitespace.constraintName}
    CHECK (
      derivation_scheme_other IS NULL
      OR derivation_scheme_other = trim(derivation_scheme_other)
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletHistoryConstraint.derivationPathNotBlank.constraintName}
    CHECK (
      derivation_path IS NULL
      OR length(trim(derivation_path)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletHistoryConstraint.derivationPathNoOuterWhitespace.constraintName}
    CHECK (
      derivation_path IS NULL
      OR derivation_path = trim(derivation_path)
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletHistoryConstraint.hardwareDeviceNotBlank.constraintName}
    CHECK (
      hardware_device IS NULL
      OR length(trim(hardware_device)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletHistoryConstraint.hardwareDeviceNoOuterWhitespace.constraintName}
    CHECK (
      hardware_device IS NULL
      OR hardware_device = trim(hardware_device)
    )
    ''',

    '''
    CONSTRAINT ${CryptoWalletHistoryConstraint.watchOnlyHasPublicData.constraintName}
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

enum CryptoWalletHistoryConstraint {
  historyIdNotBlank('chk_crypto_wallet_history_history_id_not_blank'),

  walletContentRequired('chk_crypto_wallet_history_content_required'),

  mnemonicNotBlank('chk_crypto_wallet_history_mnemonic_not_blank'),

  privateKeyNotBlank('chk_crypto_wallet_history_private_key_not_blank'),

  addressesNotBlank('chk_crypto_wallet_history_addresses_not_blank'),

  xpubNotBlank('chk_crypto_wallet_history_xpub_not_blank'),

  xprvNotBlank('chk_crypto_wallet_history_xprv_not_blank'),

  walletTypeOtherRequired(
    'chk_crypto_wallet_history_wallet_type_other_required',
  ),

  walletTypeOtherMustBeNull(
    'chk_crypto_wallet_history_wallet_type_other_must_be_null',
  ),

  walletTypeOtherNoOuterWhitespace(
    'chk_crypto_wallet_history_wallet_type_other_no_outer_whitespace',
  ),

  networkOtherRequired('chk_crypto_wallet_history_network_other_required'),

  networkOtherMustBeNull(
    'chk_crypto_wallet_history_network_other_must_be_null',
  ),

  networkOtherNoOuterWhitespace(
    'chk_crypto_wallet_history_network_other_no_outer_whitespace',
  ),

  derivationSchemeOtherRequired(
    'chk_crypto_wallet_history_derivation_scheme_other_required',
  ),

  derivationSchemeOtherMustBeNull(
    'chk_crypto_wallet_history_derivation_scheme_other_must_be_null',
  ),

  derivationSchemeOtherNoOuterWhitespace(
    'chk_crypto_wallet_history_derivation_scheme_other_no_outer_whitespace',
  ),

  derivationPathNotBlank('chk_crypto_wallet_history_derivation_path_not_blank'),

  derivationPathNoOuterWhitespace(
    'chk_crypto_wallet_history_derivation_path_no_outer_whitespace',
  ),

  hardwareDeviceNotBlank('chk_crypto_wallet_history_hardware_device_not_blank'),

  hardwareDeviceNoOuterWhitespace(
    'chk_crypto_wallet_history_hardware_device_no_outer_whitespace',
  ),

  watchOnlyHasPublicData(
    'chk_crypto_wallet_history_watch_only_has_public_data',
  );

  const CryptoWalletHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum CryptoWalletHistoryIndex {
  walletType('idx_crypto_wallet_history_wallet_type'),
  network('idx_crypto_wallet_history_network'),
  derivationScheme('idx_crypto_wallet_history_derivation_scheme');

  const CryptoWalletHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> cryptoWalletHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${CryptoWalletHistoryIndex.walletType.indexName} ON crypto_wallet_history(wallet_type) WHERE wallet_type IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${CryptoWalletHistoryIndex.network.indexName} ON crypto_wallet_history(network) WHERE network IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${CryptoWalletHistoryIndex.derivationScheme.indexName} ON crypto_wallet_history(derivation_scheme) WHERE derivation_scheme IS NOT NULL;',
];

enum CryptoWalletHistoryTrigger {
  validateSnapshotTypeOnInsert(
    'trg_crypto_wallet_history_validate_snapshot_type_on_insert',
  ),

  preventUpdate('trg_crypto_wallet_history_prevent_update');

  const CryptoWalletHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum CryptoWalletHistoryRaise {
  invalidSnapshotType(
    'crypto_wallet_history.history_id must reference vault_snapshots_history.id with type = cryptoWallet',
  ),

  historyIsImmutable('crypto_wallet_history rows are immutable');

  const CryptoWalletHistoryRaise(this.message);

  final String message;
}

final List<String> cryptoWalletHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${CryptoWalletHistoryTrigger.validateSnapshotTypeOnInsert.triggerName}
  BEFORE INSERT ON crypto_wallet_history
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_snapshots_history
    WHERE id = NEW.history_id
      AND type = 'cryptoWallet'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${CryptoWalletHistoryRaise.invalidSnapshotType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${CryptoWalletHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON crypto_wallet_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${CryptoWalletHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
