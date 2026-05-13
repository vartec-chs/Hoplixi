import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/system/categories.dart';
import '../../tables/system/tags.dart';
import '../../tables/vault_items/vault_events_history.dart';
import '../../tables/vault_items/vault_items.dart';

part 'vault_history_dto.freezed.dart';
part 'vault_history_dto.g.dart';

@freezed
sealed class VaultSnapshotHistoryDto with _$VaultSnapshotHistoryDto {
  const factory VaultSnapshotHistoryDto({
    required String id,
    required String itemId,
    required VaultEventHistoryAction action,
    required VaultItemType type,
    required String name,
    String? description,
    String? categoryId,
    String? categoryHistoryId,
    String? iconRefId,
    @Default(0) int usedCount,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,
    required DateTime createdAt,
    required DateTime modifiedAt,
    DateTime? lastUsedAt,
    DateTime? archivedAt,
    DateTime? deletedAt,
    double? recentScore,
    DateTime? historyCreatedAt,
  }) = _VaultSnapshotHistoryDto;

  factory VaultSnapshotHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$VaultSnapshotHistoryDtoFromJson(json);
}

@freezed
sealed class VaultEventHistoryDto with _$VaultEventHistoryDto {
  const factory VaultEventHistoryDto({
    required String id,
    required String itemId,
    required VaultEventHistoryAction action,
    required VaultItemType type,
    String? name,
    String? description,
    String? categoryId,
    String? iconRefId,
    String? snapshotHistoryId,
    @Default(VaultHistoryActorType.user) VaultHistoryActorType actorType,
    DateTime? eventCreatedAt,
  }) = _VaultEventHistoryDto;

  factory VaultEventHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$VaultEventHistoryDtoFromJson(json);
}

@freezed
sealed class ItemCategoryHistoryDto with _$ItemCategoryHistoryDto {
  const factory ItemCategoryHistoryDto({
    required String id,
    String? snapshotId,
    String? itemId,
    String? categoryId,
    required String name,
    String? description,
    String? iconRefId,
    required String color,
    required CategoryType type,
    String? parentId,
    DateTime? categoryCreatedAt,
    DateTime? categoryModifiedAt,
    DateTime? snapshotCreatedAt,
  }) = _ItemCategoryHistoryDto;

  factory ItemCategoryHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$ItemCategoryHistoryDtoFromJson(json);
}

@freezed
sealed class VaultItemTagHistoryDto with _$VaultItemTagHistoryDto {
  const factory VaultItemTagHistoryDto({
    required String id,
    String? historyId,
    String? snapshotId,
    String? itemId,
    String? tagId,
    required String name,
    required String color,
    required TagType type,
    DateTime? tagCreatedAt,
    DateTime? tagModifiedAt,
    DateTime? snapshotCreatedAt,
  }) = _VaultItemTagHistoryDto;

  factory VaultItemTagHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$VaultItemTagHistoryDtoFromJson(json);
}
