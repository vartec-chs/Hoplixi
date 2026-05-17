import '../../../main_store.dart';
import '../../dto/system/item_tag_dto.dart';

extension ItemTagDataMapper on ItemTagsData {
  ItemTagDto toItemTagDto() {
    return ItemTagDto(itemId: itemId, tagId: tagId, createdAt: createdAt);
  }
}
