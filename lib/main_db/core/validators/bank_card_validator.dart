import '../errors/db_error.dart';
import '../models/dto/bank_card_dto.dart';

DBCoreError? validateCreateBankCard(CreateBankCardDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DBCoreError.validation(
      entity: 'bankCard',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DBCoreError? validatePatchBankCard(PatchBankCardDto dto) {
  return null;
}
