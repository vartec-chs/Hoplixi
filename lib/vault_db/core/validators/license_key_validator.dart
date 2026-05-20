import '../errors/db_error.dart';
import '../models/dto/license_key_dto.dart';

DBCoreError? validateCreateLicenseKey(CreateLicenseKeyDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DBCoreError.validation(
      entity: 'licenseKey',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DBCoreError? validatePatchLicenseKey(PatchLicenseKeyDto dto) {
  return null;
}
