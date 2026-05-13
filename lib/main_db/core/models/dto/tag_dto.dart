import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/system/tags.dart';

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
