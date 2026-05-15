import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../tables/system/tags.dart';

part 'vault_item_tag_history_dto.freezed.dart';
part 'vault_item_tag_history_dto.g.dart';

@freezed
sealed class VaultItemTagHistoryViewDto with _$VaultItemTagHistoryViewDto {
  const factory VaultItemTagHistoryViewDto({
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
    required DateTime snapshotCreatedAt,
  }) = _VaultItemTagHistoryViewDto;

  factory VaultItemTagHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$VaultItemTagHistoryViewDtoFromJson(json);
}

@freezed
sealed class VaultItemTagHistoryCardDto with _$VaultItemTagHistoryCardDto {
  const factory VaultItemTagHistoryCardDto({
    required String id,
    String? historyId,
    required String name,
    required String color,
    required TagType type,
    required DateTime snapshotCreatedAt,
  }) = _VaultItemTagHistoryCardDto;

  factory VaultItemTagHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$VaultItemTagHistoryCardDtoFromJson(json);
}
