import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../scheme/tables/system/tags.dart';
import '../../field_update.dart';

part 'tag_dto.freezed.dart';
part 'tag_dto.g.dart';

@freezed
sealed class CreateTagDto with _$CreateTagDto {
  const factory CreateTagDto({
    required String name,
    @Default('FFFFFFFF') String color,
    required TagType type,
  }) = _CreateTagDto;

  factory CreateTagDto.fromJson(Map<String, dynamic> json) =>
      _$CreateTagDtoFromJson(json);
}

@freezed
sealed class TagViewDto with _$TagViewDto {
  const factory TagViewDto({
    required String id,
    required String name,
    required String color,
    required TagType type,
    required DateTime createdAt,
    required DateTime modifiedAt,
  }) = _TagViewDto;

  factory TagViewDto.fromJson(Map<String, dynamic> json) =>
      _$TagViewDtoFromJson(json);
}

@freezed
sealed class TagCardDto with _$TagCardDto {
  const factory TagCardDto({
    required String id,
    required String name,
    required String color,
    required TagType type,
  }) = _TagCardDto;

  factory TagCardDto.fromJson(Map<String, dynamic> json) =>
      _$TagCardDtoFromJson(json);
}

@freezed
sealed class PatchTagDto with _$PatchTagDto {
  const factory PatchTagDto({
    required String id,
    @Default(FieldUpdate.keep()) FieldUpdate<String> name,
    @Default(FieldUpdate.keep()) FieldUpdate<String> color,
  }) = _PatchTagDto;
}
