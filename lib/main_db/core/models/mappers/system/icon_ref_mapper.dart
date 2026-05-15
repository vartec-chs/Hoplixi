import '../../../main_store.dart';
import '../../dto/system/icon_ref_dto.dart';

extension IconRefDataMapper on IconRefsData {
  IconRefViewDto toIconRefViewDto() {
    return IconRefViewDto(
      id: id,
      iconSourceType: iconSourceType,
      iconPackId: iconPackId,
      iconValue: iconValue,
      customIconId: customIconId,
      color: color,
      backgroundColor: backgroundColor,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
    );
  }

  IconRefCardDto toIconRefCardDto() {
    return IconRefCardDto(
      id: id,
      iconSourceType: iconSourceType,
      iconPackId: iconPackId,
      iconValue: iconValue,
      customIconId: customIconId,
    );
  }
}
