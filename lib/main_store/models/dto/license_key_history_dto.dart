import 'package:freezed_annotation/freezed_annotation.dart';

part 'license_key_history_dto.freezed.dart';
part 'license_key_history_dto.g.dart';

@freezed
sealed class LicenseKeyHistoryCardDto with _$LicenseKeyHistoryCardDto {
  const factory LicenseKeyHistoryCardDto({
    required String id,
    required String originalLicenseKeyId,
    required String action,
    required String name,
    required String product,
    String? licenseType,
    String? orderId,
    DateTime? expiresAt,
    required DateTime actionAt,
  }) = _LicenseKeyHistoryCardDto;

  factory LicenseKeyHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$LicenseKeyHistoryCardDtoFromJson(json);
}
