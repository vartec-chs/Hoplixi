import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/base_card_dto.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';

part 'otp_dto.freezed.dart';
part 'otp_dto.g.dart';

/// DTO для создания новой OTP
@freezed
sealed class CreateOtpDto with _$CreateOtpDto {
  const factory CreateOtpDto({
    required String type, // 'totp' или 'hotp'
    required List<int> secret,
    required String secretEncoding, // 'BASE32', 'HEX', 'BINARY'
    String? issuer,
    String? accountName,
    String? noteId,
    String? algorithm, // 'SHA1', 'SHA256', 'SHA512'
    int? digits,
    int? period,
    int? counter,
    String? categoryId,
    List<String>? tagsIds,
    String? passwordId,
  }) = _CreateOtpDto;

  factory CreateOtpDto.fromJson(Map<String, dynamic> json) =>
      _$CreateOtpDtoFromJson(json);
}

/// DTO для получения полной информации об OTP
@freezed
sealed class GetOtpDto with _$GetOtpDto {
  const factory GetOtpDto({
    required String id,
    required String type,
    required List<int> secret,
    required String secretEncoding,
    String? issuer,
    String? accountName,
    String? noteId,
    required String algorithm,
    required int digits,
    required int period,
    int? counter,
    String? categoryId,
    String? categoryName,
    String? passwordId,
    required int usedCount,
    required bool isFavorite,
    required bool isPinned,
    required DateTime createdAt,
    required DateTime modifiedAt,
    DateTime? lastAccessedAt,
    required List<String> tags,
  }) = _GetOtpDto;

  factory GetOtpDto.fromJson(Map<String, dynamic> json) =>
      _$GetOtpDtoFromJson(json);
}

/// DTO для карточки OTP (основная информация для отображения)
@freezed
sealed class OtpCardDto with _$OtpCardDto implements BaseCardDto {
  const factory OtpCardDto({
    required String id,
    String? issuer, // Сервис
    String? accountName, // Имя аккаунта
    required String type,
    required int digits,
    required int period,
    required bool isFavorite,
    required bool isPinned,
    required bool isArchived,
    required bool isDeleted,
    required int usedCount,
    required DateTime modifiedAt,
    CategoryInCardDto? category,
    List<TagInCardDto>? tags,
  }) = _OtpCardDto;

  factory OtpCardDto.fromJson(Map<String, dynamic> json) =>
      _$OtpCardDtoFromJson(json);
}

/// DTO для обновления OTP
@freezed
sealed class UpdateOtpDto with _$UpdateOtpDto {
  const factory UpdateOtpDto({
    String? issuer,
    String? accountName,
    String? noteId,
    String? algorithm,
    int? digits,
    int? period,
    int? counter,
    String? categoryId,
    String? passwordId,
    bool? isFavorite,
    bool? isPinned,
    List<String>? tagsIds,
  }) = _UpdateOtpDto;

  factory UpdateOtpDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateOtpDtoFromJson(json);
}
