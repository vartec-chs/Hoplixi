import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/system/item_link/item_links.dart';

part 'item_link_dto.freezed.dart';
part 'item_link_dto.g.dart';

@freezed
sealed class ItemLinkDto with _$ItemLinkDto {
  const factory ItemLinkDto({
    String? id,
    required String sourceItemId,
    required String targetItemId,
    required ItemLinkType relationType,
    String? relationTypeOther,
    String? label,
    @Default(0) int sortOrder,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) = _ItemLinkDto;

  factory ItemLinkDto.fromJson(Map<String, dynamic> json) =>
      _$ItemLinkDtoFromJson(json);
}
