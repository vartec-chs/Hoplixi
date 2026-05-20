import '../errors/db_error.dart';
import '../models/dto/loyalty_card_dto.dart';

DBCoreError? validateCreateLoyaltyCard(CreateLoyaltyCardDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DBCoreError.validation(
      entity: 'loyaltyCard',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DBCoreError? validatePatchLoyaltyCard(PatchLoyaltyCardDto dto) {
  return null;
}
