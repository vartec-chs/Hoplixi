import '../errors/db_error.dart';
import '../models/dto/license_key_dto.dart';

DbError? validateCreateLicenseKey(CreateLicenseKeyDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DbError.validation(
      entity: 'licenseKey',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DbError? validatePatchLicenseKey(PatchLicenseKeyDto dto) {
  return null;
}
