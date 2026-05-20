import '../db_constraint_descriptor.dart';
import '../../tables/crypto_wallet/crypto_wallet_items.dart';

final Map<String, DbConstraintDescriptor> cryptoWalletRegistry = {
  CryptoWalletItemConstraint.itemIdNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_crypto_wallet_items_item_id_not_blank',
        entity: 'cryptoWallet',
        table: 'crypto_wallet_items',
        field: 'itemId',
        code: 'crypto_wallet.item_id.not_blank',
        message: 'ID записи не может быть пустым',
      ),
  CryptoWalletItemConstraint.walletContentRequired.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_crypto_wallet_items_content_required',
        entity: 'cryptoWallet',
        table: 'crypto_wallet_items',
        field: 'mnemonic',
        code: 'crypto_wallet.content.required',
        message: 'Необходимо указать мнемоническую фразу или приватный ключ',
      ),
  CryptoWalletItemConstraint.addressesNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_crypto_wallet_items_addresses_not_blank',
        entity: 'cryptoWallet',
        table: 'crypto_wallet_items',
        field: 'addresses',
        code: 'crypto_wallet.addresses.not_blank',
        message: 'Список адресов не может состоять из одних пробелов',
      ),
  CryptoWalletItemConstraint.hardwareDeviceNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_crypto_wallet_items_hardware_device_not_blank',
        entity: 'cryptoWallet',
        table: 'crypto_wallet_items',
        field: 'hardwareDevice',
        code: 'crypto_wallet.hardware_device.not_blank',
        message: 'Название аппаратного кошелька не может быть пустым',
      ),
};
