import '../errors/db_error.dart';
import '../models/dto/file_dto.dart';

DbError? validateCreateFile(CreateFileDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DbError.validation(
      entity: 'file',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DbError? validatePatchFile(PatchFileDto dto) {
  return null;
}
