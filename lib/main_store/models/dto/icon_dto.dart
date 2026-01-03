import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';

part 'icon_dto.freezed.dart';
part 'icon_dto.g.dart';

/// DTO для карточки иконки (краткая информация)
@freezed
sealed class IconCardDto with _$IconCardDto {
  const factory IconCardDto({
    required String id,
    required String name,
    required String type,
    // required List<int> data,
    required DateTime createdAt,
    required DateTime modifiedAt,
  }) = _IconCardDto;

  factory IconCardDto.fromJson(Map<String, dynamic> json) =>
      _$IconCardDtoFromJson(json);
}

/// DTO для создания новой иконки
@freezed
sealed class CreateIconDto with _$CreateIconDto {
  const factory CreateIconDto({
    required String name,
    required IconType type,
    required List<int> data,
  }) = _CreateIconDto;

  factory CreateIconDto.fromJson(Map<String, dynamic> json) =>
      _$CreateIconDtoFromJson(json);
}

/// DTO для обновления иконки
@freezed
sealed class UpdateIconDto with _$UpdateIconDto {
  const factory UpdateIconDto({String? name, String? type, List<int>? data}) =
      _UpdateIconDto;

  factory UpdateIconDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateIconDtoFromJson(json);
}

/// DTO для полной информации об иконке
@freezed
sealed class IconDetailDto with _$IconDetailDto {
  const factory IconDetailDto({
    required String id,
    required String name,
    required String type,
    // required List<int> data,
    required DateTime createdAt,
    required DateTime modifiedAt,
  }) = _IconDetailDto;

  factory IconDetailDto.fromJson(Map<String, dynamic> json) =>
      _$IconDetailDtoFromJson(json);
}
