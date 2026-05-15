import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../tables/system/item_link/item_links.dart';

part 'item_link_dto.freezed.dart';
part 'item_link_dto.g.dart';

@freezed
sealed class CreateItemLinkDto with _$CreateItemLinkDto {
  const factory CreateItemLinkDto({
    required String sourceItemId,
    required String targetItemId,
    required ItemLinkType relationType,
    String? relationTypeOther,
    String? label,
    @Default(0) int sortOrder,
  }) = _CreateItemLinkDto;

  factory CreateItemLinkDto.fromJson(Map<String, dynamic> json) =>
      _$CreateItemLinkDtoFromJson(json);
}

@freezed
sealed class UpdateItemLinkDto with _$UpdateItemLinkDto {
  const factory UpdateItemLinkDto({
    required String id,
    ItemLinkType? relationType,
    String? relationTypeOther,
    String? label,
    int? sortOrder,
  }) = _UpdateItemLinkDto;

  factory UpdateItemLinkDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateItemLinkDtoFromJson(json);
}

@freezed
sealed class ItemLinkViewDto with _$ItemLinkViewDto {
  const factory ItemLinkViewDto({
    required String id,
    required String sourceItemId,
    required String targetItemId,
    required ItemLinkType relationType,
    String? relationTypeOther,
    String? label,
    required int sortOrder,
    required DateTime createdAt,
    required DateTime modifiedAt,
  }) = _ItemLinkViewDto;

  factory ItemLinkViewDto.fromJson(Map<String, dynamic> json) =>
      _$ItemLinkViewDtoFromJson(json);
}

@freezed
sealed class ItemLinkCardDto with _$ItemLinkCardDto {
  const factory ItemLinkCardDto({
    required String id,
    required String sourceItemId,
    required String targetItemId,
    required ItemLinkType relationType,
    String? label,
  }) = _ItemLinkCardDto;

  factory ItemLinkCardDto.fromJson(Map<String, dynamic> json) =>
      _$ItemLinkCardDtoFromJson(json);
}
