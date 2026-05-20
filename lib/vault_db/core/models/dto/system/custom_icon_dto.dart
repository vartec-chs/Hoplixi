import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../tables/system/icons/custom_icons.dart';
import '../../field_update.dart';
import '../converters.dart';

part 'custom_icon_dto.freezed.dart';
part 'custom_icon_dto.g.dart';

@freezed
sealed class PatchCustomIconDto with _$PatchCustomIconDto {
  const factory PatchCustomIconDto({
    required String id,
    @Default(FieldUpdate.keep()) FieldUpdate<String> name,
    @Default(FieldUpdate.keep()) FieldUpdate<CustomIconFormat> format,
    @Default(FieldUpdate.keep()) FieldUpdate<Uint8List> data,
  }) = _PatchCustomIconDto;
}

@freezed
sealed class CreateCustomIconDto with _$CreateCustomIconDto {
  const factory CreateCustomIconDto({
    required String name,
    required CustomIconFormat format,
    @Uint8ListBase64Converter() required Uint8List data,
  }) = _CreateCustomIconDto;

  factory CreateCustomIconDto.fromJson(Map<String, dynamic> json) =>
      _$CreateCustomIconDtoFromJson(json);
}

@freezed
sealed class CustomIconViewDto with _$CustomIconViewDto {
  const factory CustomIconViewDto({
    required String id,
    required String name,
    required CustomIconFormat format,
    @Uint8ListBase64Converter() required Uint8List data,
    required DateTime createdAt,
    required DateTime modifiedAt,
  }) = _CustomIconViewDto;

  factory CustomIconViewDto.fromJson(Map<String, dynamic> json) =>
      _$CustomIconViewDtoFromJson(json);
}

@freezed
sealed class CustomIconCardDto with _$CustomIconCardDto {
  const factory CustomIconCardDto({
    required String id,
    required String name,
    required CustomIconFormat format,
    // Не включаем data в CardDto для экономии памяти в списках
  }) = _CustomIconCardDto;

  factory CustomIconCardDto.fromJson(Map<String, dynamic> json) =>
      _$CustomIconCardDtoFromJson(json);
}
