import '../errors/db_error.dart';
import '../models/dto/certificate_dto.dart';

DBCoreError? validateCreateCertificate(CreateCertificateDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DBCoreError.validation(
      entity: 'certificate',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DBCoreError? validatePatchCertificate(PatchCertificateDto dto) {
  return null;
}
