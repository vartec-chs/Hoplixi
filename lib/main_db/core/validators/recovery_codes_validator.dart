import '../errors/db_error.dart';
import '../models/dto/recovery_codes_dto.dart';

DbError? validateCreateRecoveryCodes(CreateRecoveryCodesDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DbError.validation(
      entity: 'recoveryCodes',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DbError? validatePatchRecoveryCodes(PatchRecoveryCodesDto dto) {
  return null;
}
