import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';

extension VaultSnapshotHistoryDataMapper on VaultSnapshotHistoryData {
  VaultSnapshotCardDto toVaultSnapshotCardDto() {
    return VaultSnapshotCardDto(
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
