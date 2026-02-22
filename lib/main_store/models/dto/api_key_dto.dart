import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/base_card_dto.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';

part 'api_key_dto.freezed.dart';
part 'api_key_dto.g.dart';

@freezed
sealed class CreateApiKeyDto with _$CreateApiKeyDto {
  const factory CreateApiKeyDto({
    required String name,
    required String service,
    required String key,
    String? maskedKey,
    String? tokenType,
    String? environment,
    DateTime? expiresAt,
    bool? revoked,
    int? rotationPeriodDays,
    DateTime? lastRotatedAt,
    String? metadata,
    String? description,
    String? noteId,
    String? categoryId,
    List<String>? tagsIds,
  }) = _CreateApiKeyDto;

  factory CreateApiKeyDto.fromJson(Map<String, dynamic> json) =>
      _$CreateApiKeyDtoFromJson(json);
}

@freezed
sealed class UpdateApiKeyDto with _$UpdateApiKeyDto {
  const factory UpdateApiKeyDto({
    String? name,
    String? service,
    String? key,
    String? maskedKey,
    String? tokenType,
    String? environment,
    DateTime? expiresAt,
    bool? revoked,
    int? rotationPeriodDays,
    DateTime? lastRotatedAt,
    String? metadata,
    String? description,
    String? noteId,
    String? categoryId,
    bool? isFavorite,
    bool? isArchived,
    bool? isPinned,
    List<String>? tagsIds,
  }) = _UpdateApiKeyDto;

  factory UpdateApiKeyDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateApiKeyDtoFromJson(json);
}

@freezed
sealed class ApiKeyCardDto with _$ApiKeyCardDto implements BaseCardDto {
  const factory ApiKeyCardDto({
    required String id,
    required String name,
    required String service,
    String? maskedKey,
    String? tokenType,
    String? environment,
    DateTime? expiresAt,
    required bool revoked,
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
  }) = _ApiKeyCardDto;

  factory ApiKeyCardDto.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyCardDtoFromJson(json);
}
