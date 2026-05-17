import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/system/categories.dart';

part 'category_dto.freezed.dart';
part 'category_dto.g.dart';

@freezed
sealed class CategoryDto with _$CategoryDto {
  const factory CategoryDto({
    String? id,
    required String name,
    String? description,
    String? iconRefId,
    @Default('FFFFFFFF') String color,
    required CategoryType type,
    String? parentId,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) = _CategoryDto;

  factory CategoryDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryDtoFromJson(json);
}
