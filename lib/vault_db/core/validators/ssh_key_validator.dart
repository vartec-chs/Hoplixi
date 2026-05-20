import '../errors/db_error.dart';
import '../models/dto/ssh_key_dto.dart';

DBCoreError? validateCreateSshKey(CreateSshKeyDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DBCoreError.validation(
      entity: 'sshKey',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DBCoreError? validatePatchSshKey(PatchSshKeyDto dto) {
  return null;
}
