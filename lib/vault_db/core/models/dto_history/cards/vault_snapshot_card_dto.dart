import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../tables/vault_items/vault_events_history.dart';
import '../../../tables/vault_items/vault_items.dart';

part 'vault_snapshot_card_dto.freezed.dart';
part 'vault_snapshot_card_dto.g.dart';

@freezed
sealed class VaultSnapshotCardDto with _$VaultSnapshotCardDto {
  const factory VaultSnapshotCardDto({
    required String historyId,
    required String itemId,
    required VaultItemType type,
    required VaultEventHistoryAction action,
    required String name,
    String? description,
    String? categoryId,
    String? categoryHistoryId,
    String? iconRefId,
    required int usedCount,
    required bool isFavorite,
    required bool isArchived,
    required bool isPinned,
    required bool isDeleted,
    required DateTime createdAt,
    required DateTime modifiedAt,
    DateTime? lastUsedAt,
    DateTime? archivedAt,
    DateTime? deletedAt,
    double? recentScore,
    required DateTime historyCreatedAt,
  }) = _VaultSnapshotCardDto;

  factory VaultSnapshotCardDto.fromJson(Map<String, dynamic> json) =>
      _$VaultSnapshotCardDtoFromJson(json);
}
