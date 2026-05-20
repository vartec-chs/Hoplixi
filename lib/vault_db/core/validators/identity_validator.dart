import '../errors/db_error.dart';
import '../models/dto/identity_dto.dart';

DBCoreError? validateCreateIdentity(CreateIdentityDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DBCoreError.validation(
      entity: 'identity',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DBCoreError? validatePatchIdentity(PatchIdentityDto dto) {
  return null;
}
