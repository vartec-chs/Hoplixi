import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_key_history_dto.freezed.dart';
part 'api_key_history_dto.g.dart';

@freezed
sealed class ApiKeyHistoryCardDto with _$ApiKeyHistoryCardDto {
  const factory ApiKeyHistoryCardDto({
    required String id,
    required String originalApiKeyId,
    required String action,
    required String name,
    required String service,
    String? tokenType,
    String? environment,
    required bool revoked,
    required DateTime actionAt,
  }) = _ApiKeyHistoryCardDto;

  factory ApiKeyHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyHistoryCardDtoFromJson(json);
}
