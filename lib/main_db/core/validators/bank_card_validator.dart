import '../errors/db_error.dart';
import '../models/dto/bank_card_dto.dart';

DbError? validateCreateBankCard(CreateBankCardDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DbError.validation(
      entity: 'bankCard',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DbError? validatePatchBankCard(PatchBankCardDto dto) {
  return null;
}
