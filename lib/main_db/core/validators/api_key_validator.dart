import '../errors/db_error.dart';
import '../models/dto/api_key_dto.dart';
import '../models/field_update.dart';

DbError? validateCreateApiKey(CreateApiKeyDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DbError.validation(
      entity: 'apiKey',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }

  if (dto.apiKey.service.trim().isEmpty) {
    return const DbError.validation(
      entity: 'apiKey',
      field: 'service',
      code: 'api_key.service.not_blank',
      message: 'Название сервиса не может быть пустым',
    );
  }

  if (dto.apiKey.key.trim().isEmpty) {
    return const DbError.validation(
      entity: 'apiKey',
      field: 'key',
      code: 'api_key.key.not_blank',
      message: 'API ключ не может быть пустым',
    );
  }

  return null;
}

DbError? validatePatchApiKey(PatchApiKeyDto dto) {
  if (dto.item.name case FieldUpdateSet<String>(value: final value)) {
    if (value == null || value.trim().isEmpty) {
      return const DbError.validation(
        entity: 'apiKey',
        field: 'name',
        code: 'vault_item.name.not_blank',
        message: 'Название записи не может быть пустым',
      );
    }
  }

  if (dto.apiKey.service case FieldUpdateSet<String>(value: final value)) {
    if (value == null || value.trim().isEmpty) {
      return const DbError.validation(
        entity: 'apiKey',
        field: 'service',
        code: 'api_key.service.not_blank',
        message: 'Название сервиса не может быть пустым',
      );
    }
  }

  if (dto.apiKey.key case FieldUpdateSet<String>(value: final value)) {
    if (value == null || value.trim().isEmpty) {
      return const DbError.validation(
        entity: 'apiKey',
        field: 'key',
        code: 'api_key.key.not_blank',
        message: 'API ключ не может быть пустым',
      );
    }
  }

  return null;
}
