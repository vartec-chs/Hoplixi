import '../errors/db_error.dart';
import '../models/dto/document_dto.dart';

DBCoreError? validateCreateDocument(CreateDocumentDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DBCoreError.validation(
      entity: 'document',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DBCoreError? validatePatchDocument(PatchDocumentDto dto) {
  return null;
}
