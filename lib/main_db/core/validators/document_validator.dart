import '../errors/db_error.dart';
import '../models/dto/document_dto.dart';

DbError? validateCreateDocument(CreateDocumentDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DbError.validation(
      entity: 'document',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DbError? validatePatchDocument(PatchDocumentDto dto) {
  return null;
}
