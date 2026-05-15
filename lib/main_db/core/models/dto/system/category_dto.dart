import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../tables/system/categories.dart';

part 'category_dto.freezed.dart';
part 'category_dto.g.dart';

@freezed
sealed class CreateCategoryDto with _$CreateCategoryDto {
  const factory CreateCategoryDto({
    required String name,
    String? description,
    String? iconRefId,
    @Default('FFFFFFFF') String color,
    required CategoryType type,
    String? parentId,
  }) = _CreateCategoryDto;

  factory CreateCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$CreateCategoryDtoFromJson(json);
}

@freezed
sealed class UpdateCategoryDto with _$UpdateCategoryDto {
  const factory UpdateCategoryDto({
    required String id,
    String? name,
    String? description,
    String? iconRefId,
    String? color,
    CategoryType? type,
    String? parentId,
  }) = _UpdateCategoryDto;

  factory UpdateCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateCategoryDtoFromJson(json);
}

@freezed
sealed class CategoryViewDto with _$CategoryViewDto {
  const factory CategoryViewDto({
    required String id,
    required String name,
    String? description,
    String? iconRefId,
    required String color,
    required CategoryType type,
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
    required String color,
    required CategoryType type,
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
