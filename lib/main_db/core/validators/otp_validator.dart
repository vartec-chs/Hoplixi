import '../errors/db_error.dart';
import '../models/dto/otp_dto.dart';

DbError? validateCreateOtp(CreateOtpDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DbError.validation(
      entity: 'otp',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DbError? validatePatchOtp(PatchOtpDto dto) {
  return null;
}
