import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/otp/otp_items.dart';
import 'converters.dart';
import 'vault_item_base_dto.dart';

part 'otp_dto.freezed.dart';
part 'otp_dto.g.dart';

@freezed
sealed class OtpDataDto with _$OtpDataDto {
  const factory OtpDataDto({
    @Default(OtpType.otp) OtpType type,
    String? issuer,
    String? accountName,
    @Uint8ListBase64Converter() required Uint8List secret,
    @Default(OtpHashAlgorithm.SHA1) OtpHashAlgorithm algorithm,
    @Default(6) int digits,
    @Default(30) int? period,
    int? counter,
  }) = _OtpDataDto;

  factory OtpDataDto.fromJson(Map<String, dynamic> json) =>
      _$OtpDataDtoFromJson(json);
}

@freezed
sealed class OtpCardDataDto with _$OtpCardDataDto {
  const factory OtpCardDataDto({
    @Default(OtpType.otp) OtpType type,
    String? issuer,
    String? accountName,
    @Default(OtpHashAlgorithm.SHA1) OtpHashAlgorithm algorithm,
    @Default(6) int digits,
    @Default(30) int? period,
    int? counter,
    @Default(true) bool hasSecret,
  }) = _OtpCardDataDto;

  factory OtpCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$OtpCardDataDtoFromJson(json);
}

@freezed
sealed class CreateOtpDto with _$CreateOtpDto {
  const factory CreateOtpDto({
    required VaultItemCreateDto item,
    required OtpDataDto otp,
  }) = _CreateOtpDto;

  factory CreateOtpDto.fromJson(Map<String, dynamic> json) =>
      _$CreateOtpDtoFromJson(json);
}

@freezed
sealed class UpdateOtpDto with _$UpdateOtpDto {
  const factory UpdateOtpDto({
    required VaultItemUpdateDto item,
    required OtpDataDto otp,
  }) = _UpdateOtpDto;

  factory UpdateOtpDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateOtpDtoFromJson(json);
}

@freezed
sealed class OtpViewDto with _$OtpViewDto {
  const factory OtpViewDto({
    required VaultItemViewDto item,
    required OtpDataDto otp,
  }) = _OtpViewDto;

  factory OtpViewDto.fromJson(Map<String, dynamic> json) =>
      _$OtpViewDtoFromJson(json);
}

@freezed
sealed class OtpCardDto with _$OtpCardDto {
  const factory OtpCardDto({
    required VaultItemCardDto item,
    required OtpCardDataDto otp,
  }) = _OtpCardDto;

  factory OtpCardDto.fromJson(Map<String, dynamic> json) =>
      _$OtpCardDtoFromJson(json);
}
