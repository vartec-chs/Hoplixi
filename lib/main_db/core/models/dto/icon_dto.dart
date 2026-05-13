import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/system/icons/custom_icons.dart';
import '../../tables/system/icons/icon_refs.dart';
import 'converters.dart';

part 'icon_dto.freezed.dart';
part 'icon_dto.g.dart';

@freezed
sealed class IconRefDto with _$IconRefDto {
  const factory IconRefDto({
    String? id,
    required IconSourceType iconSourceType,
    String? iconPackId,
    String? iconValue,
    String? customIconId,
    String? color,
    String? backgroundColor,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) = _IconRefDto;

  factory IconRefDto.fromJson(Map<String, dynamic> json) =>
      _$IconRefDtoFromJson(json);
}

@freezed
sealed class CustomIconDto with _$CustomIconDto {
  const factory CustomIconDto({
    String? id,
    required String name,
    required CustomIconFormat format,
    @Uint8ListConverter() required Uint8List data,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) = _CustomIconDto;

  factory CustomIconDto.fromJson(Map<String, dynamic> json) =>
      _$CustomIconDtoFromJson(json);
}
