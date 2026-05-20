import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/system/item_link/item_links.dart';
import 'vault_snapshot_base_dto.dart';

part 'item_link_history_dto.freezed.dart';
part 'item_link_history_dto.g.dart';

@freezed
sealed class ItemLinkHistoryDataDto with _$ItemLinkHistoryDataDto {
  const factory ItemLinkHistoryDataDto({
    required String id,
    String? sourceLinkId,
    required String sourceItemId,
    required String targetItemId,
    required ItemLinkType relationType,
    String? relationTypeOther,
    String? label,
    @Default(0) int sortOrder,
    required DateTime createdAt,
    required DateTime modifiedAt,
    required DateTime snapshotCreatedAt,
  }) = _ItemLinkHistoryDataDto;

  factory ItemLinkHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$ItemLinkHistoryDataDtoFromJson(json);
}

@freezed
sealed class ItemLinkHistoryViewDto with _$ItemLinkHistoryViewDto {
  const factory ItemLinkHistoryViewDto({
    required VaultSnapshotViewDto snapshot,
    @Default([]) List<ItemLinkHistoryDataDto> links,
  }) = _ItemLinkHistoryViewDto;

  factory ItemLinkHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$ItemLinkHistoryViewDtoFromJson(json);
}
