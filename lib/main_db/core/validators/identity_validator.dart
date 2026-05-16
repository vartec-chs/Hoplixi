import '../errors/db_error.dart';
import '../models/dto/identity_dto.dart';

DbError? validateCreateIdentity(CreateIdentityDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DbError.validation(
      entity: 'identity',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DbError? validatePatchIdentity(PatchIdentityDto dto) {
  return null;
}
