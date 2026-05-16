import '../errors/db_error.dart';
import '../models/dto/wifi_dto.dart';

DbError? validateCreateWifi(CreateWifiDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DbError.validation(
      entity: 'wifi',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DbError? validatePatchWifi(PatchWifiDto dto) {
  return null;
}
