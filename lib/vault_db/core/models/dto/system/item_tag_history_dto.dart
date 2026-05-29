import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../scheme/tables/system/tags/tags.dart';

part 'item_tag_history_dto.freezed.dart';
part 'item_tag_history_dto.g.dart';

@freezed
sealed class ItemTagHistoryViewDto with _$ItemTagHistoryViewDto {
  const factory ItemTagHistoryViewDto({
    required String id,
    String? historyId,
    String? snapshotId,
    String? itemId,
    String? tagId,
    required String name,
    required int color,
    required TagType type,
    DateTime? tagCreatedAt,
    DateTime? tagModifiedAt,
    required DateTime snapshotCreatedAt,
  }) = _ItemTagHistoryViewDto;

  factory ItemTagHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$ItemTagHistoryViewDtoFromJson(json);
}

@freezed
sealed class ItemTagHistoryCardDto with _$ItemTagHistoryCardDto {
  const factory ItemTagHistoryCardDto({
    required String id,
    String? historyId,
    required String name,
    required int color,
    required TagType type,
    required DateTime snapshotCreatedAt,
  }) = _ItemTagHistoryCardDto;

  factory ItemTagHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$ItemTagHistoryCardDtoFromJson(json);
}
