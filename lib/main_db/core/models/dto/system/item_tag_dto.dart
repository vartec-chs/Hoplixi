import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_tag_dto.freezed.dart';
part 'item_tag_dto.g.dart';

@freezed
sealed class ItemTagDto with _$ItemTagDto {
  const factory ItemTagDto({
    required String itemId,
    required String tagId,
    required DateTime createdAt,
  }) = _ItemTagDto;

  factory ItemTagDto.fromJson(Map<String, dynamic> json) =>
      _$ItemTagDtoFromJson(json);
}

@freezed
sealed class AssignTagDto with _$AssignTagDto {
  const factory AssignTagDto({
    required String itemId,
    required String tagId,
  }) = _AssignTagDto;

  factory AssignTagDto.fromJson(Map<String, dynamic> json) =>
      _$AssignTagDtoFromJson(json);
}

@freezed
sealed class RemoveTagDto with _$RemoveTagDto {
  const factory RemoveTagDto({
    required String itemId,
    required String tagId,
  }) = _RemoveTagDto;

  factory RemoveTagDto.fromJson(Map<String, dynamic> json) =>
      _$RemoveTagDtoFromJson(json);
}
