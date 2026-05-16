import '../errors/db_error.dart';
import '../models/dto/contact_dto.dart';

DbError? validateCreateContact(CreateContactDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DbError.validation(
      entity: 'contact',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DbError? validatePatchContact(PatchContactDto dto) {
  return null;
}
