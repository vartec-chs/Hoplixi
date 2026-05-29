import 'package:hoplixi/vault_db/core/vault_db.dart';

import '../../dto/system/item_tag_history_dto.dart';

extension ItemTagHistoryDataMapper on ItemTagHistoryData {
  ItemTagHistoryViewDto toItemTagHistoryViewDto() {
    return ItemTagHistoryViewDto(
      id: id,
      historyId: historyId,
      snapshotId: snapshotId,
      itemId: itemId,
      tagId: tagId,
      name: name,
      color: color,
      type: type,
      tagCreatedAt: tagCreatedAt,
      tagModifiedAt: tagModifiedAt,
      snapshotCreatedAt: snapshotCreatedAt,
    );
  }

  ItemTagHistoryCardDto toItemTagHistoryCardDto() {
    return ItemTagHistoryCardDto(
      id: id,
      historyId: historyId,
      name: name,
      color: color,
      type: type,
      snapshotCreatedAt: snapshotCreatedAt,
    );
  }
}
