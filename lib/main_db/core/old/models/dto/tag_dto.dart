import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag_dto.freezed.dart';
part 'tag_dto.g.dart';

/// DTO для создания нового тега
@freezed
sealed class CreateTagDto with _$CreateTagDto {
  const factory CreateTagDto({
    required String name,
    required String type, // 'notes', 'password', 'totp', 'mixed'
    String? color,
  }) = _CreateTagDto;

  factory CreateTagDto.fromJson(Map<String, dynamic> json) =>
      _$CreateTagDtoFromJson(json);
}

/// DTO для получения полной информации о теге
@freezed
sealed class GetTagDto with _$GetTagDto {
  const factory GetTagDto({
    required String id,
    required String name,
    required String type,
    String? color,
    required int itemsCount,
    required DateTime createdAt,
    required DateTime modifiedAt,
  }) = _GetTagDto;

  factory GetTagDto.fromJson(Map<String, dynamic> json) =>
      _$GetTagDtoFromJson(json);
}

/// DTO для карточки тега (основная информация для отображения)
@freezed
sealed class TagCardDto with _$TagCardDto {
  const factory TagCardDto({
    required String id,
    required String name,
    required String type,
    String? color,
    required int itemsCount,
  }) = _TagCardDto;

  factory TagCardDto.fromJson(Map<String, dynamic> json) =>
      _$TagCardDtoFromJson(json);
}

/// DTO для рендеринга в каточках других сущностей
@freezed
sealed class TagInCardDto with _$TagInCardDto {
  const factory TagInCardDto({
    required String id,
    required String name,
    String? color,
  }) = _TagInCardDto;

  factory TagInCardDto.fromJson(Map<String, dynamic> json) =>
      _$TagInCardDtoFromJson(json);
}

/// DTO для обновления тега
@freezed
sealed class UpdateTagDto with _$UpdateTagDto {
  const factory UpdateTagDto({String? name, String? color}) = _UpdateTagDto;

  factory UpdateTagDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateTagDtoFromJson(json);
}
