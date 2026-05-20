import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/api_key/api_key_items.dart';
import 'vault_snapshot_base_dto.dart';

part 'api_key_history_dto.freezed.dart';
part 'api_key_history_dto.g.dart';

@freezed
sealed class ApiKeyHistoryDataDto with _$ApiKeyHistoryDataDto {
  const factory ApiKeyHistoryDataDto({
    required String service,
    String? key,
    ApiKeyTokenType? tokenType,
    String? tokenTypeOther,
    ApiKeyEnvironment? environment,
    String? environmentOther,
    DateTime? expiresAt,
    @Default(false) bool revoked,
    DateTime? revokedAt,
    int? rotationPeriodDays,
    DateTime? lastRotatedAt,
    String? scopesText,
    String? owner,
    String? baseUrl,
  }) = _ApiKeyHistoryDataDto;

  factory ApiKeyHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyHistoryDataDtoFromJson(json);
}

@freezed
sealed class ApiKeyHistoryViewDto with _$ApiKeyHistoryViewDto {
  const factory ApiKeyHistoryViewDto({
    required VaultSnapshotViewDto snapshot,
    required ApiKeyHistoryDataDto apiKey,
  }) = _ApiKeyHistoryViewDto;

  factory ApiKeyHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyHistoryViewDtoFromJson(json);
}

@freezed
sealed class ApiKeyHistoryCardDataDto with _$ApiKeyHistoryCardDataDto {
  const factory ApiKeyHistoryCardDataDto({
    required String service,
    ApiKeyTokenType? tokenType,
    String? tokenTypeOther,
    ApiKeyEnvironment? environment,
    String? environmentOther,
    DateTime? expiresAt,
    @Default(false) bool revoked,
    DateTime? revokedAt,
    String? owner,
    String? baseUrl,
    required bool hasKey,
  }) = _ApiKeyHistoryCardDataDto;

  factory ApiKeyHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class ApiKeyHistoryCardDto with _$ApiKeyHistoryCardDto {
  const factory ApiKeyHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required ApiKeyHistoryCardDataDto apiKey,
  }) = _ApiKeyHistoryCardDto;

  factory ApiKeyHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyHistoryCardDtoFromJson(json);
}
