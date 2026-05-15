import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../tables/system/item_link/item_links.dart';

part 'item_link_history_dto.freezed.dart';
part 'item_link_history_dto.g.dart';

@freezed
sealed class ItemLinkHistoryViewDto with _$ItemLinkHistoryViewDto {
  const factory ItemLinkHistoryViewDto({
    required String id,
    required String historyId,
    String? sourceLinkId,
    required String sourceItemId,
    required String targetItemId,
    required ItemLinkType relationType,
    String? relationTypeOther,
    String? label,
    required int sortOrder,
    required DateTime createdAt,
    required DateTime modifiedAt,
    required DateTime snapshotCreatedAt,
  }) = _ItemLinkHistoryViewDto;

  factory ItemLinkHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$ItemLinkHistoryViewDtoFromJson(json);
}

@freezed
sealed class ItemLinkHistoryCardDto with _$ItemLinkHistoryCardDto {
  const factory ItemLinkHistoryCardDto({
    required String id,
    required String historyId,
    required String sourceItemId,
    required String targetItemId,
    required ItemLinkType relationType,
    required DateTime snapshotCreatedAt,
  }) = _ItemLinkHistoryCardDto;

  factory ItemLinkHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$ItemLinkHistoryCardDtoFromJson(json);
}
