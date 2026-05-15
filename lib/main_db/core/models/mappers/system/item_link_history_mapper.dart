import '../../../main_store.dart';
import '../../dto/system/item_link_history_dto.dart';

extension ItemLinkHistoryDataMapper on ItemLinkHistoryData {
  ItemLinkHistoryViewDto toItemLinkHistoryViewDto() {
    return ItemLinkHistoryViewDto(
      id: id,
      historyId: historyId,
      sourceLinkId: sourceLinkId,
      sourceItemId: sourceItemId,
      targetItemId: targetItemId,
      relationType: relationType,
      relationTypeOther: relationTypeOther,
      label: label,
      sortOrder: sortOrder,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      snapshotCreatedAt: snapshotCreatedAt,
    );
  }

  ItemLinkHistoryCardDto toItemLinkHistoryCardDto() {
    return ItemLinkHistoryCardDto(
      id: id,
      historyId: historyId,
      sourceItemId: sourceItemId,
      targetItemId: targetItemId,
      relationType: relationType,
      snapshotCreatedAt: snapshotCreatedAt,
    );
  }
}
