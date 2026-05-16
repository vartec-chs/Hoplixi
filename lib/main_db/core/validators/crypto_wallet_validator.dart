import '../errors/db_error.dart';
import '../models/dto/crypto_wallet_dto.dart';

DbError? validateCreateCryptoWallet(CreateCryptoWalletDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DbError.validation(
      entity: 'cryptoWallet',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DbError? validatePatchCryptoWallet(PatchCryptoWalletDto dto) {
  return null;
}
