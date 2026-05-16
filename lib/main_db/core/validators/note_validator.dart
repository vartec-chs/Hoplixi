import '../errors/db_error.dart';
import '../models/dto/note_dto.dart';

DBCoreError? validateCreateNote(CreateNoteDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DBCoreError.validation(
      entity: 'note',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DBCoreError? validatePatchNote(PatchNoteDto dto) {
  return null;
}
