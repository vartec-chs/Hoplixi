import '../errors/db_error.dart';
import '../models/dto/certificate_dto.dart';

DbError? validateCreateCertificate(CreateCertificateDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DbError.validation(
      entity: 'certificate',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DbError? validatePatchCertificate(PatchCertificateDto dto) {
  return null;
}
