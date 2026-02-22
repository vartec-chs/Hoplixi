import 'package:freezed_annotation/freezed_annotation.dart';

part 'recovery_codes_history_dto.freezed.dart';
part 'recovery_codes_history_dto.g.dart';

@freezed
sealed class RecoveryCodesHistoryCardDto with _$RecoveryCodesHistoryCardDto {
  const factory RecoveryCodesHistoryCardDto({
    required String id,
    required String originalRecoveryCodesId,
    required String action,
    required String name,
    int? codesCount,
    int? usedCount,
    bool? oneTime,
    required DateTime actionAt,
  }) = _RecoveryCodesHistoryCardDto;

  factory RecoveryCodesHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodesHistoryCardDtoFromJson(json);
}
