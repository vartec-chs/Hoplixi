import '../../../main_store.dart';
import '../../dto/system/item_link_dto.dart';

extension ItemLinkDataMapper on ItemLinksData {
  ItemLinkViewDto toItemLinkViewDto() {
    return ItemLinkViewDto(
      id: id,
      sourceItemId: sourceItemId,
      targetItemId: targetItemId,
      relationType: relationType,
      relationTypeOther: relationTypeOther,
      label: label,
      sortOrder: sortOrder,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
    );
  }

  ItemLinkCardDto toItemLinkCardDto() {
    return ItemLinkCardDto(
      id: id,
      sourceItemId: sourceItemId,
      targetItemId: targetItemId,
      relationType: relationType,
      label: label,
    );
  }
}
