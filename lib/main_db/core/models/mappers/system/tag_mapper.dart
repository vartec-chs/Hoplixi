import '../../../main_store.dart';
import '../../dto/system/tag_dto.dart';

extension TagDataMapper on TagsData {
  TagViewDto toTagViewDto() {
    return TagViewDto(
      id: id,
      name: name,
      color: color,
      type: type,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
    );
  }

  TagCardDto toTagCardDto() {
    return TagCardDto(
      id: id,
      name: name,
      color: color,
      type: type,
    );
  }
}
