import '../errors/db_error.dart';
import '../models/dto/contact_dto.dart';

DBCoreError? validateCreateContact(CreateContactDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DBCoreError.validation(
      entity: 'contact',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DBCoreError? validatePatchContact(PatchContactDto dto) {
  return null;
}
