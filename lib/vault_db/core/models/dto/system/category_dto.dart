import 'package:freezed_annotation/freezed_annotation.dart';

import '../../field_update.dart';

part 'category_dto.freezed.dart';
part 'category_dto.g.dart';

@freezed
sealed class CreateCategoryDto with _$CreateCategoryDto {
  const factory CreateCategoryDto({
    required String name,
    String? iconRefId,
    @Default(0xFFFFFF) int color,
    String? parentId,
  }) = _CreateCategoryDto;

  factory CreateCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$CreateCategoryDtoFromJson(json);
}

@freezed
sealed class CategoryViewDto with _$CategoryViewDto {
  const factory CategoryViewDto({
    required String id,
    required String name,
    String? iconRefId,
    required int color,
    String? parentId,
    required DateTime createdAt,
    required DateTime modifiedAt,
  }) = _CategoryViewDto;

  factory CategoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryViewDtoFromJson(json);
}

@freezed
sealed class CategoryCardDto with _$CategoryCardDto {
  const factory CategoryCardDto({
    required String id,
    required String name,
    String? iconRefId,
    required int color,
    String? parentId,
  }) = _CategoryCardDto;

  factory CategoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryCardDtoFromJson(json);
}

@freezed
sealed class CategoryTreeNodeDto with _$CategoryTreeNodeDto {
  const factory CategoryTreeNodeDto({
    required CategoryCardDto category,
    @Default([]) List<CategoryTreeNodeDto> children,
  }) = _CategoryTreeNodeDto;

  factory CategoryTreeNodeDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryTreeNodeDtoFromJson(json);
}

@freezed
sealed class PatchCategoryDto with _$PatchCategoryDto {
  const factory PatchCategoryDto({
    required String id,
    @Default(FieldUpdate.keep()) FieldUpdate<String> name,
    @Default(FieldUpdate.keep()) FieldUpdate<String> iconRefId,
    @Default(FieldUpdate.keep()) FieldUpdate<int> color,
    @Default(FieldUpdate.keep()) FieldUpdate<String> parentId,
  }) = _PatchCategoryDto;
}
