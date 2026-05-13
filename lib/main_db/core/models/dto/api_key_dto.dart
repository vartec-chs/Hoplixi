import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/api_key/api_key_items.dart';
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
  }) = _CreateApiKeyDto;

  factory CreateApiKeyDto.fromJson(Map<String, dynamic> json) =>
      _$CreateApiKeyDtoFromJson(json);
}

@freezed
sealed class UpdateApiKeyDto with _$UpdateApiKeyDto {
  const factory UpdateApiKeyDto({
    required VaultItemUpdateDto item,
    required ApiKeyDataDto apiKey,
  }) = _UpdateApiKeyDto;

  factory UpdateApiKeyDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateApiKeyDtoFromJson(json);
}

@freezed
sealed class ApiKeyViewDto with _$ApiKeyViewDto {
  const factory ApiKeyViewDto({
    required VaultItemViewDto item,
    required ApiKeyDataDto apiKey,
  }) = _ApiKeyViewDto;

  factory ApiKeyViewDto.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyViewDtoFromJson(json);
}

@freezed
sealed class ApiKeyCardDto with _$ApiKeyCardDto {
  const factory ApiKeyCardDto({
    required VaultItemCardDto item,
    required ApiKeyCardDataDto apiKey,
  }) = _ApiKeyCardDto;

  factory ApiKeyCardDto.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyCardDtoFromJson(json);
}

extension ApiKeyDataDtoX on ApiKeyDataDto {
  bool get isRevoked => revokedAt != null;
}

extension ApiKeyCardDataDtoX on ApiKeyCardDataDto {
  bool get isRevoked => revokedAt != null;
}
