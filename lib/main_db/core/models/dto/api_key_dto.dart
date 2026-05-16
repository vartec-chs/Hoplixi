import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/api_key/api_key_items.dart';
import '../field_update.dart';
import 'vault_item_base_dto.dart';

part 'api_key_dto.freezed.dart';
part 'api_key_dto.g.dart';

@freezed
sealed class ApiKeyDataDto with _$ApiKeyDataDto {
  const factory ApiKeyDataDto({
    required String service,
    required String key,

    ApiKeyTokenType? tokenType,
    String? tokenTypeOther,

    ApiKeyEnvironment? environment,
    String? environmentOther,

    DateTime? expiresAt,
    DateTime? revokedAt,

    int? rotationPeriodDays,
    DateTime? lastRotatedAt,

    String? owner,
    String? baseUrl,
    String? scopesText,
  }) = _ApiKeyDataDto;

  factory ApiKeyDataDto.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyDataDtoFromJson(json);
}

@freezed
sealed class ApiKeyCardDataDto with _$ApiKeyCardDataDto {
  const factory ApiKeyCardDataDto({
    required String service,

    ApiKeyTokenType? tokenType,
    ApiKeyEnvironment? environment,

    DateTime? expiresAt,
    DateTime? revokedAt,

    int? rotationPeriodDays,
    DateTime? lastRotatedAt,

    String? owner,
    String? baseUrl,

    @Default(true) bool hasKey,
  }) = _ApiKeyCardDataDto;

  factory ApiKeyCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyCardDataDtoFromJson(json);
}

@freezed
sealed class CreateApiKeyDto with _$CreateApiKeyDto {
  const factory CreateApiKeyDto({
    required VaultItemCreateDto item,
    required ApiKeyDataDto apiKey,
    @Default([]) List<String> tagIds,
  }) = _CreateApiKeyDto;

  factory CreateApiKeyDto.fromJson(Map<String, dynamic> json) =>
      _$CreateApiKeyDtoFromJson(json);
}

@freezed
sealed class ApiKeyViewDto with _$ApiKeyViewDto implements VaultEntityViewDto {
  const factory ApiKeyViewDto({
    required VaultItemViewDto item,
    required ApiKeyDataDto apiKey,
  }) = _ApiKeyViewDto;

  factory ApiKeyViewDto.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyViewDtoFromJson(json);
}

@freezed
sealed class ApiKeyCardDto with _$ApiKeyCardDto implements VaultEntityCardDto {
  const factory ApiKeyCardDto({
    required VaultItemCardDto item,
    required ApiKeyCardDataDto apiKey,
  }) = _ApiKeyCardDto;

  factory ApiKeyCardDto.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyCardDtoFromJson(json);
}

@freezed
sealed class PatchApiKeyDataDto with _$PatchApiKeyDataDto {
  const factory PatchApiKeyDataDto({
    @Default(FieldUpdate.keep()) FieldUpdate<String> service,
    @Default(FieldUpdate.keep()) FieldUpdate<String> key,

    @Default(FieldUpdate.keep()) FieldUpdate<ApiKeyTokenType> tokenType,
    @Default(FieldUpdate.keep()) FieldUpdate<String> tokenTypeOther,

    @Default(FieldUpdate.keep()) FieldUpdate<ApiKeyEnvironment> environment,
    @Default(FieldUpdate.keep()) FieldUpdate<String> environmentOther,

    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> expiresAt,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> revokedAt,

    @Default(FieldUpdate.keep()) FieldUpdate<int> rotationPeriodDays,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> lastRotatedAt,

    @Default(FieldUpdate.keep()) FieldUpdate<String> owner,
    @Default(FieldUpdate.keep()) FieldUpdate<String> baseUrl,
    @Default(FieldUpdate.keep()) FieldUpdate<String> scopesText,
  }) = _PatchApiKeyDataDto;
}

@freezed
sealed class PatchApiKeyDto with _$PatchApiKeyDto {
  const factory PatchApiKeyDto({
    required VaultItemPatchDto item,
    required PatchApiKeyDataDto apiKey,
    @Default(FieldUpdate.keep()) FieldUpdate<List<String>> tags,
  }) = _PatchApiKeyDto;
}

extension ApiKeyDataDtoX on ApiKeyDataDto {
  bool get isRevoked => revokedAt != null;
}

extension ApiKeyCardDataDtoX on ApiKeyCardDataDto {
  bool get isRevoked => revokedAt != null;
}


