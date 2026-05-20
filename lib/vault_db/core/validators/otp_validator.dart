import '../errors/db_error.dart';
import '../models/dto/otp_dto.dart';

DBCoreError? validateCreateOtp(CreateOtpDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DBCoreError.validation(
      entity: 'otp',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DBCoreError? validatePatchOtp(PatchOtpDto dto) {
  return null;
}
