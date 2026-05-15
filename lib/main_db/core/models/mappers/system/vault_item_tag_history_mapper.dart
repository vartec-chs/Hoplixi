import '../../../main_store.dart';
import '../../dto/system/vault_item_tag_history_dto.dart';

extension VaultItemTagHistoryDataMapper on VaultItemTagHistoryData {
  VaultItemTagHistoryViewDto toVaultItemTagHistoryViewDto() {
    return VaultItemTagHistoryViewDto(
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

  VaultItemTagHistoryCardDto toVaultItemTagHistoryCardDto() {
    return VaultItemTagHistoryCardDto(
      id: id,
      historyId: historyId,
      name: name,
      color: color,
      type: type,
      snapshotCreatedAt: snapshotCreatedAt,
    );
  }
}
