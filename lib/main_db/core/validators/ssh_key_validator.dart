import '../errors/db_error.dart';
import '../models/dto/ssh_key_dto.dart';

DbError? validateCreateSshKey(CreateSshKeyDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DbError.validation(
      entity: 'sshKey',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DbError? validatePatchSshKey(PatchSshKeyDto dto) {
  return null;
}
