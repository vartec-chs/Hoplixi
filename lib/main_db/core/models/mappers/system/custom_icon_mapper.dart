import '../../../main_store.dart';
import '../../dto/system/custom_icon_dto.dart';

extension CustomIconDataMapper on CustomIconsData {
  CustomIconViewDto toCustomIconViewDto() {
    return CustomIconViewDto(
      id: id,
      name: name,
      format: format,
      data: data,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
    );
  }

  CustomIconCardDto toCustomIconCardDto() {
    return CustomIconCardDto(id: id, name: name, format: format);
  }
}
