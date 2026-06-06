import 'package:result_dart/result_dart.dart';

import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/custom_icon_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/icon_ref_dto.dart';
import 'package:hoplixi/vault_db/core/repositories/base/system/icon_repository.dart';

/// Public API boundary for icon refs and custom icons.
class IconsApi {
  const IconsApi({required this._repository});

  final IconRepository _repository;

  AsyncDBResult<String> createCustomIcon(CreateCustomIconDto dto) {
    return _repository.createCustomIcon(dto);
  }

  AsyncDBResult<Unit> updateCustomIcon(PatchCustomIconDto dto) {
    return _repository.updateCustomIcon(dto);
  }

  AsyncDBResult<Unit> deleteCustomIcon(String customIconId) {
    return _repository.deleteCustomIcon(customIconId);
  }

  AsyncDBResult<Optional<CustomIconViewDto>> getCustomIcon(
    String customIconId,
  ) {
    return _repository.getCustomIcon(customIconId);
  }

  AsyncDBResult<List<CustomIconCardDto>> listCustomIcons() {
    return _repository.getCustomIcons();
  }

  AsyncDBResult<String> createIconRef(CreateIconRefDto dto) {
    return _repository.createIconRef(dto);
  }

  AsyncDBResult<Unit> updateIconRef(PatchIconRefDto dto) {
    return _repository.updateIconRef(dto);
  }

  AsyncDBResult<Unit> deleteIconRef(String iconRefId) {
    return _repository.deleteIconRef(iconRefId);
  }

  AsyncDBResult<Optional<IconRefViewDto>> getIconRef(String iconRefId) {
    return _repository.getIconRef(iconRefId);
  }

  AsyncDBResult<List<IconRefCardDto>> listIconRefs() {
    return _repository.getIconRefs();
  }
}
