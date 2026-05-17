import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/system/item_link/item_links.dart';
import '../field_update.dart';

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

@freezed
sealed class PatchItemLinkDto with _$PatchItemLinkDto {
  const factory PatchItemLinkDto({
    required String id,
    @Default(FieldUpdate.keep()) FieldUpdate<ItemLinkType> relationType,
    @Default(FieldUpdate.keep()) FieldUpdate<String> relationTypeOther,
    @Default(FieldUpdate.keep()) FieldUpdate<String> label,
    @Default(FieldUpdate.keep()) FieldUpdate<int> sortOrder,
  }) = _PatchItemLinkDto;
}
