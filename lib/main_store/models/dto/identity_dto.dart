import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/base_card_dto.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';

part 'identity_dto.freezed.dart';
part 'identity_dto.g.dart';

@freezed
sealed class CreateIdentityDto with _$CreateIdentityDto {
  const factory CreateIdentityDto({
    required String name,
    required String idType,
    required String idNumber,
    String? fullName,
    DateTime? dateOfBirth,
    String? placeOfBirth,
    String? nationality,
    String? issuingAuthority,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? mrz,
    String? scanAttachmentId,
    String? photoAttachmentId,
    String? notes,
    bool? verified,
    String? description,
    String? noteId,
    String? categoryId,
    List<String>? tagsIds,
  }) = _CreateIdentityDto;

  factory CreateIdentityDto.fromJson(Map<String, dynamic> json) =>
      _$CreateIdentityDtoFromJson(json);
}

@freezed
sealed class UpdateIdentityDto with _$UpdateIdentityDto {
  const factory UpdateIdentityDto({
    String? name,
    String? idType,
    String? idNumber,
    String? fullName,
    DateTime? dateOfBirth,
    String? placeOfBirth,
    String? nationality,
    String? issuingAuthority,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? mrz,
    String? scanAttachmentId,
    String? photoAttachmentId,
    String? notes,
    bool? verified,
    String? description,
    String? noteId,
    String? categoryId,
    bool? isFavorite,
    bool? isArchived,
    bool? isPinned,
    List<String>? tagsIds,
  }) = _UpdateIdentityDto;

  factory UpdateIdentityDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateIdentityDtoFromJson(json);
}

@freezed
sealed class IdentityCardDto with _$IdentityCardDto implements BaseCardDto {
  const factory IdentityCardDto({
    required String id,
    required String name,
    required String idType,
    required String idNumber,
    String? fullName,
    String? nationality,
    DateTime? expiryDate,
    required bool verified,
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
  }) = _IdentityCardDto;

  factory IdentityCardDto.fromJson(Map<String, dynamic> json) =>
      _$IdentityCardDtoFromJson(json);
}
