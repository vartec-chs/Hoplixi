import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/base_card_dto.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';

part 'certificate_dto.freezed.dart';
part 'certificate_dto.g.dart';

@freezed
sealed class CreateCertificateDto with _$CreateCertificateDto {
  const factory CreateCertificateDto({
    required String name,
    required String certificatePem,
    String? privateKey,
    String? serialNumber,
    String? issuer,
    String? subject,
    DateTime? validFrom,
    DateTime? validTo,
    String? fingerprint,
    String? keyUsage,
    String? extensions,
    List<int>? pfxBlob,
    String? passwordForPfx,
    String? ocspUrl,
    String? crlUrl,
    bool? autoRenew,
    DateTime? lastCheckedAt,
    String? description,
    String? noteId,
    String? categoryId,
    List<String>? tagsIds,
  }) = _CreateCertificateDto;

  factory CreateCertificateDto.fromJson(Map<String, dynamic> json) =>
      _$CreateCertificateDtoFromJson(json);
}

@freezed
sealed class UpdateCertificateDto with _$UpdateCertificateDto {
  const factory UpdateCertificateDto({
    String? name,
    String? certificatePem,
    String? privateKey,
    String? serialNumber,
    String? issuer,
    String? subject,
    DateTime? validFrom,
    DateTime? validTo,
    String? fingerprint,
    String? keyUsage,
    String? extensions,
    List<int>? pfxBlob,
    String? passwordForPfx,
    String? ocspUrl,
    String? crlUrl,
    bool? autoRenew,
    DateTime? lastCheckedAt,
    String? description,
    String? noteId,
    String? categoryId,
    bool? isFavorite,
    bool? isArchived,
    bool? isPinned,
    List<String>? tagsIds,
  }) = _UpdateCertificateDto;

  factory UpdateCertificateDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateCertificateDtoFromJson(json);
}

@freezed
sealed class CertificateCardDto
    with _$CertificateCardDto
    implements BaseCardDto {
  const factory CertificateCardDto({
    required String id,
    required String name,
    String? serialNumber,
    String? issuer,
    String? subject,
    DateTime? validFrom,
    DateTime? validTo,
    String? fingerprint,
    required bool hasPrivateKey,
    required bool hasPfx,
    required bool autoRenew,
    DateTime? lastCheckedAt,
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
  }) = _CertificateCardDto;

  factory CertificateCardDto.fromJson(Map<String, dynamic> json) =>
      _$CertificateCardDtoFromJson(json);
}
