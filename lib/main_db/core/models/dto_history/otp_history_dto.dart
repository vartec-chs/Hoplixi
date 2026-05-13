import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/otp/otp_items.dart';
import '../dto/converters.dart';
import 'vault_snapshot_base_dto.dart';

part 'otp_history_dto.freezed.dart';
part 'otp_history_dto.g.dart';

@freezed
sealed class OtpHistoryDataDto with _$OtpHistoryDataDto {
  const factory OtpHistoryDataDto({
    @Default(OtpType.otp) OtpType type,
    String? issuer,
    String? accountName,
    @NullableUint8ListBase64Converter() Uint8List? secret,
    @Default(OtpHashAlgorithm.SHA1) OtpHashAlgorithm algorithm,
    @Default(6) int digits,
    @Default(30) int? period,
    int? counter,
  }) = _OtpHistoryDataDto;

  factory OtpHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$OtpHistoryDataDtoFromJson(json);
}

@freezed
sealed class OtpHistoryViewDto with _$OtpHistoryViewDto {
  const factory OtpHistoryViewDto({
    required VaultSnapshotViewDto snapshot,
    required OtpHistoryDataDto otp,
  }) = _OtpHistoryViewDto;

  factory OtpHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$OtpHistoryViewDtoFromJson(json);
}

@freezed
sealed class OtpHistoryCardDataDto with _$OtpHistoryCardDataDto {
  const factory OtpHistoryCardDataDto({
    @Default(OtpType.otp) OtpType type,
    String? issuer,
    String? accountName,
    @Default(OtpHashAlgorithm.SHA1) OtpHashAlgorithm algorithm,
    @Default(6) int digits,
    @Default(30) int? period,
    int? counter,
    required bool hasSecret,
  }) = _OtpHistoryCardDataDto;

  factory OtpHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$OtpHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class OtpHistoryCardDto with _$OtpHistoryCardDto {
  const factory OtpHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required OtpHistoryCardDataDto otp,
  }) = _OtpHistoryCardDto;

  factory OtpHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$OtpHistoryCardDtoFromJson(json);
}
