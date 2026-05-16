import '../../../tables/api_key/api_key_items.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';

part 'api_key_history_card_dto.freezed.dart';
part 'api_key_history_card_dto.g.dart';

@freezed
sealed class ApiKeyHistoryCardDataDto with _$ApiKeyHistoryCardDataDto {
  const factory ApiKeyHistoryCardDataDto({
    String? service,
    ApiKeyTokenType? tokenType,
    ApiKeyEnvironment? environment,
    DateTime? expiresAt,
    DateTime? revokedAt,
    int? rotationPeriodDays,
    DateTime? lastRotatedAt,
    String? owner,
    String? baseUrl,
    @Default(false) bool hasKey,
  }) = _ApiKeyHistoryCardDataDto;

  factory ApiKeyHistoryCardDataDto.fromJson(Map<String, dynamic> json) => _$ApiKeyHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class ApiKeyHistoryCardDto with _$ApiKeyHistoryCardDto implements VaultHistoryCardDto {
  const factory ApiKeyHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required ApiKeyHistoryCardDataDto apikey,
  }) = _ApiKeyHistoryCardDto;

  factory ApiKeyHistoryCardDto.fromJson(Map<String, dynamic> json) => _$ApiKeyHistoryCardDtoFromJson(json);
}