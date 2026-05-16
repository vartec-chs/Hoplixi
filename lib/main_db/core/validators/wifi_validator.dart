import '../errors/db_error.dart';
import '../models/dto/wifi_dto.dart';

DBCoreError? validateCreateWifi(CreateWifiDto dto) {
  if (dto.item.name.trim().isEmpty) {
    return const DBCoreError.validation(
      entity: 'wifi',
      field: 'name',
      code: 'vault_item.name.not_blank',
      message: 'Название записи не может быть пустым',
    );
  }
  return null;
}

DBCoreError? validatePatchWifi(PatchWifiDto dto) {
  return null;
}
