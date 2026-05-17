import '../../../main_store.dart';
import '../../../models/dto/dto.dart';
import '../../../tables/vault_items/vault_events_history.dart';
import '../../../services/history/models/vault_item_base_history_payload.dart';

extension VaultSnapshotHistoryBasePayloadMapper on VaultSnapshotHistoryData {
  VaultItemBaseHistoryPayload toVaultItemBaseHistoryPayload() {
    return VaultItemBaseHistoryPayload(
      historyId: id,
      itemId: itemId,
      type: type,
      action: action,
      name: name,
      description: description,
      categoryId: categoryId,
      categoryHistoryId: categoryHistoryId,
      iconRefId: iconRefId,
      usedCount: usedCount,
      isFavorite: isFavorite,
      isArchived: isArchived,
      isPinned: isPinned,
      isDeleted: isDeleted,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      lastUsedAt: lastUsedAt,
      archivedAt: archivedAt,
      deletedAt: deletedAt,
      recentScore: recentScore,
      historyCreatedAt: historyCreatedAt,
    );
  }
}

extension VaultItemsDataBasePayloadMapper on VaultItemsData {
  VaultItemBaseHistoryPayload toCurrentVaultItemBaseHistoryPayload() {
    return VaultItemBaseHistoryPayload(
      historyId: 'current',
      itemId: id,
      type: type,
      action: VaultEventHistoryAction.updated,
      name: name,
      description: description,
      categoryId: categoryId,
      categoryHistoryId: null,
      iconRefId: iconRefId,
      usedCount: usedCount,
      isFavorite: isFavorite,
      isArchived: isArchived,
      isPinned: isPinned,
      isDeleted: isDeleted,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      lastUsedAt: lastUsedAt,
      archivedAt: archivedAt,
      deletedAt: deletedAt,
      recentScore: recentScore,
      historyCreatedAt: DateTime.now(),
    );
  }
}

extension VaultItemBaseHistoryPayloadMapper on VaultItemBaseHistoryPayload {
  VaultSnapshotCardDto toVaultSnapshotCardDto() {
    return VaultSnapshotCardDto(
      historyId: historyId,
      itemId: itemId,
      type: type,
      action: action,
      name: name,
      description: description,
      categoryId: categoryId,
      categoryHistoryId: categoryHistoryId,
      iconRefId: iconRefId,
      usedCount: usedCount,
      isFavorite: isFavorite,
      isArchived: isArchived,
      isPinned: isPinned,
      isDeleted: isDeleted,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      lastUsedAt: lastUsedAt,
      archivedAt: archivedAt,
      deletedAt: deletedAt,
      recentScore: recentScore,
      historyCreatedAt: historyCreatedAt,
    );
  }
}
