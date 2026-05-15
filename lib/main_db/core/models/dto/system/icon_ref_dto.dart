import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../tables/system/icons/icon_refs.dart';

part 'icon_ref_dto.freezed.dart';
part 'icon_ref_dto.g.dart';

@freezed
sealed class CreateIconRefDto with _$CreateIconRefDto {
  const factory CreateIconRefDto({
    required IconSourceType iconSourceType,
    String? iconPackId,
    String? iconValue,
    String? customIconId,
    String? color,
    String? backgroundColor,
  }) = _CreateIconRefDto;

  factory CreateIconRefDto.fromJson(Map<String, dynamic> json) =>
      _$CreateIconRefDtoFromJson(json);
}

@freezed
sealed class UpdateIconRefDto with _$UpdateIconRefDto {
  const factory UpdateIconRefDto({
    required String id,
    IconSourceType? iconSourceType,
    String? iconPackId,
    String? iconValue,
    String? customIconId,
    String? color,
    String? backgroundColor,
  }) = _UpdateIconRefDto;

  factory UpdateIconRefDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateIconRefDtoFromJson(json);
}

@freezed
sealed class IconRefViewDto with _$IconRefViewDto {
  const factory IconRefViewDto({
    required String id,
    required IconSourceType iconSourceType,
    String? iconPackId,
    String? iconValue,
    String? customIconId,
    String? color,
    String? backgroundColor,
    required DateTime createdAt,
    required DateTime modifiedAt,
  }) = _IconRefViewDto;

  factory IconRefViewDto.fromJson(Map<String, dynamic> json) =>
      _$IconRefViewDtoFromJson(json);
}

@freezed
sealed class IconRefCardDto with _$IconRefCardDto {
  const factory IconRefCardDto({
    required String id,
    required IconSourceType iconSourceType,
    String? iconPackId,
    String? iconValue,
    String? customIconId,
  }) = _IconRefCardDto;

  factory IconRefCardDto.fromJson(Map<String, dynamic> json) =>
      _$IconRefCardDtoFromJson(json);
}
