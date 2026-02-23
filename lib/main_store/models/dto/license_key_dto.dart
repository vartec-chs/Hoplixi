import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/base_card_dto.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';

part 'license_key_dto.freezed.dart';
part 'license_key_dto.g.dart';

@freezed
sealed class CreateLicenseKeyDto with _$CreateLicenseKeyDto {
  const factory CreateLicenseKeyDto({
    required String name,
    required String product,
    required String licenseKey,
    String? licenseType,
    int? seats,
    int? maxActivations,
    DateTime? activatedOn,
    DateTime? purchaseDate,
    String? purchaseFrom,
    String? orderId,
    String? licenseFileId,
    DateTime? expiresAt,
    String? supportContact,
    String? description,
    String? noteId,
    String? categoryId,
    List<String>? tagsIds,
  }) = _CreateLicenseKeyDto;

  factory CreateLicenseKeyDto.fromJson(Map<String, dynamic> json) =>
      _$CreateLicenseKeyDtoFromJson(json);
}

@freezed
sealed class UpdateLicenseKeyDto with _$UpdateLicenseKeyDto {
  const factory UpdateLicenseKeyDto({
    String? name,
    String? product,
    String? licenseKey,
    String? licenseType,
    int? seats,
    int? maxActivations,
    DateTime? activatedOn,
    DateTime? purchaseDate,
    String? purchaseFrom,
    String? orderId,
    String? licenseFileId,
    DateTime? expiresAt,
    String? supportContact,
    String? description,
    String? noteId,
    String? categoryId,
    bool? isFavorite,
    bool? isArchived,
    bool? isPinned,
    List<String>? tagsIds,
  }) = _UpdateLicenseKeyDto;

  factory UpdateLicenseKeyDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateLicenseKeyDtoFromJson(json);
}

@freezed
sealed class LicenseKeyCardDto with _$LicenseKeyCardDto implements BaseCardDto {
  const factory LicenseKeyCardDto({
    required String id,
    required String name,
    required String product,
    String? licenseType,
    String? orderId,
    DateTime? expiresAt,
    int? seats,
    String? description,
    CategoryInCardDto? category,
    List<TagInCardDto>? tags,
    required bool isFavorite,
    required bool isPinned,
    required bool isArchived,
    required bool isDeleted,
    required int usedCount,
    required DateTime modifiedAt,
    required DateTime createdAt,
  }) = _LicenseKeyCardDto;

  factory LicenseKeyCardDto.fromJson(Map<String, dynamic> json) =>
      _$LicenseKeyCardDtoFromJson(json);
}
