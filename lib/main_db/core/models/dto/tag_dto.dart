import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/system/tags.dart';
import '../field_update.dart';

part 'tag_dto.freezed.dart';
part 'tag_dto.g.dart';

@freezed
sealed class TagDto with _$TagDto {
  const factory TagDto({
    String? id,
    required String name,
    @Default('FFFFFFFF') String color,
     required TagType type,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) = _TagDto;

  factory TagDto.fromJson(Map<String, dynamic> json) => _$TagDtoFromJson(json);
}

@freezed
sealed class PatchTagDto with _$PatchTagDto {
  const factory PatchTagDto({
    required String id,
    @Default(FieldUpdate.keep()) FieldUpdate<String> name,
    @Default(FieldUpdate.keep()) FieldUpdate<String> color,
    @Default(FieldUpdate.keep()) FieldUpdate<TagType> type,
  }) = _PatchTagDto;
}


