import '../errors/db_error.dart';
import '../models/dto/password_dto.dart';

DBCoreError? validateCreatePassword(CreatePasswordDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DBCoreError.validation(
      entity: 'password',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  if (dto.password.password.isEmpty) {
    return const DBCoreError.validation(
      entity: 'password',
      field: 'password',
      code: 'password.password.not_blank',
      message: 'Пароль не может быть пустым',
    );
  }
  return null;
}

DBCoreError? validatePatchPassword(PatchPasswordDto dto) {
  return null;
}
