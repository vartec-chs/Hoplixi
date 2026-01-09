import 'package:freezed_annotation/freezed_annotation.dart';

part 'otp_history_dto.freezed.dart';
part 'otp_history_dto.g.dart';

/// DTO для создания записи истории OTP
@freezed
sealed class CreateOtpHistoryDto with _$CreateOtpHistoryDto {
  const factory CreateOtpHistoryDto({
    required String originalOtpId,
    required String action,
    required String type,
    String? issuer,
    String? accountName,
    required List<int> secret,
    required String secretEncoding,
    String? noteId,
    required String algorithm,
    required int digits,
    required int period,
    int? counter,
    String? categoryName,
    required int usedCount,
    required bool isFavorite,
    required bool isPinned,
    required DateTime originalCreatedAt,
    required DateTime originalModifiedAt,
  }) = _CreateOtpHistoryDto;

  factory CreateOtpHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$CreateOtpHistoryDtoFromJson(json);
}

/// DTO для получения записи из истории OTP
@freezed
sealed class GetOtpHistoryDto with _$GetOtpHistoryDto {
  const factory GetOtpHistoryDto({
    required String id,
    required String originalOtpId,
    required String action,
    required String type,
    String? issuer,
    String? accountName,
    String? noteId,
    required String algorithm,
    required int digits,
    required int period,
    int? counter,
    String? categoryName,
    required int usedCount,
    required bool isFavorite,
    required bool isPinned,
    required DateTime originalCreatedAt,
    required DateTime originalModifiedAt,
    required DateTime actionAt,
  }) = _GetOtpHistoryDto;

  factory GetOtpHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$GetOtpHistoryDtoFromJson(json);
}

/// DTO для карточки истории OTP (основная информация)
@freezed
sealed class OtpHistoryCardDto with _$OtpHistoryCardDto {
  const factory OtpHistoryCardDto({
    required String id,
    required String originalOtpId,
    required String action,
    String? issuer,
    String? accountName,
    required String type,
    required DateTime actionAt,
  }) = _OtpHistoryCardDto;

  factory OtpHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$OtpHistoryCardDtoFromJson(json);
}
