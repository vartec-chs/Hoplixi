import '../../../main_store.dart';
import '../../dto/system/item_category_history_dto.dart';

extension ItemCategoryHistoryDataMapper on ItemCategoryHistoryData {
  ItemCategoryHistoryViewDto toItemCategoryHistoryViewDto() {
    return ItemCategoryHistoryViewDto(
      id: id,
      snapshotId: snapshotId,
      itemId: itemId,
      categoryId: categoryId,
      name: name,
      description: description,
      iconRefId: iconRefId,
      color: color,
      type: type,
      parentId: parentId,
      categoryCreatedAt: categoryCreatedAt,
      categoryModifiedAt: categoryModifiedAt,
      snapshotCreatedAt: snapshotCreatedAt,
    );
  }

  ItemCategoryHistoryCardDto toItemCategoryHistoryCardDto() {
    return ItemCategoryHistoryCardDto(
      id: id,
      snapshotId: snapshotId,
      itemId: itemId,
      name: name,
      iconRefId: iconRefId,
      color: color,
      type: type,
      snapshotCreatedAt: snapshotCreatedAt,
    );
  }
}
