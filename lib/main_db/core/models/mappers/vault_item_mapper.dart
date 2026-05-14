import 'package:hoplixi/main_db/core/models/dto/vault_item_base_dto.dart';
import 'package:hoplixi/main_db/core/main_store.dart';

extension VaultItemsDataMapper on VaultItemsData {
  VaultItemViewDto toVaultItemViewDto() {
    return VaultItemViewDto(
      itemId: id,
      type: type,
      name: name,
      description: description,
      categoryId: categoryId,
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
    );
  }

  VaultItemCardDto toVaultItemCardDto() {
    return VaultItemCardDto(
      itemId: id,
      type: type,
      name: name,
      description: description,
      categoryId: categoryId,
      iconRefId: iconRefId,
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
    );
  }
}
