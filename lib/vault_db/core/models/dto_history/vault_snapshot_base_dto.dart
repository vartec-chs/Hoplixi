import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/vault_items/vault_events_history.dart';
import '../../tables/vault_items/vault_items.dart';

part 'vault_snapshot_base_dto.freezed.dart';
part 'vault_snapshot_base_dto.g.dart';

@freezed
sealed class VaultSnapshotViewDto with _$VaultSnapshotViewDto {
  const factory VaultSnapshotViewDto({
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

    required DateTime historyCreatedAt,
  }) = _VaultSnapshotViewDto;

  factory VaultSnapshotViewDto.fromJson(Map<String, dynamic> json) =>
      _$VaultSnapshotViewDtoFromJson(json);
}

@freezed
sealed class VaultSnapshotCardDto with _$VaultSnapshotCardDto {
  const factory VaultSnapshotCardDto({
    required String id,
    required String itemId,
    required VaultItemType type,
    required VaultEventHistoryAction action,

    required String name,

    required DateTime historyCreatedAt,
    required DateTime modifiedAt,

    @Default(false) bool isArchived,
    @Default(false) bool isDeleted,
    @Default(false) bool isFavorite,
    @Default(false) bool isPinned,
  }) = _VaultSnapshotCardDto;

  factory VaultSnapshotCardDto.fromJson(Map<String, dynamic> json) =>
      _$VaultSnapshotCardDtoFromJson(json);
}
