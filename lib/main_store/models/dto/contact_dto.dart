import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/base_card_dto.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';

part 'contact_dto.freezed.dart';
part 'contact_dto.g.dart';

@freezed
sealed class CreateContactDto with _$CreateContactDto {
  const factory CreateContactDto({
    required String name,
    String? phone,
    String? email,
    String? company,
    String? jobTitle,
    String? address,
    String? website,
    DateTime? birthday,
    bool? isEmergencyContact,
    String? notes,
    String? description,
    String? noteId,
    String? categoryId,
    List<String>? tagsIds,
  }) = _CreateContactDto;

  factory CreateContactDto.fromJson(Map<String, dynamic> json) =>
      _$CreateContactDtoFromJson(json);
}

@freezed
sealed class UpdateContactDto with _$UpdateContactDto {
  const factory UpdateContactDto({
    String? name,
    String? phone,
    String? email,
    String? company,
    String? jobTitle,
    String? address,
    String? website,
    DateTime? birthday,
    bool? isEmergencyContact,
    String? notes,
    String? description,
    String? noteId,
    String? categoryId,
    bool? isFavorite,
    bool? isArchived,
    bool? isPinned,
    List<String>? tagsIds,
  }) = _UpdateContactDto;

  factory UpdateContactDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateContactDtoFromJson(json);
}

@freezed
sealed class ContactCardDto with _$ContactCardDto implements BaseCardDto {
  const factory ContactCardDto({
    required String id,
    required String name,
    String? phone,
    String? email,
    String? company,
    String? jobTitle,
    bool? isEmergencyContact,
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
  }) = _ContactCardDto;

  factory ContactCardDto.fromJson(Map<String, dynamic> json) =>
      _$ContactCardDtoFromJson(json);
}
