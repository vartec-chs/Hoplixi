import 'package:freezed_annotation/freezed_annotation.dart';

part 'identity_history_dto.freezed.dart';
part 'identity_history_dto.g.dart';

@freezed
sealed class IdentityHistoryCardDto with _$IdentityHistoryCardDto {
  const factory IdentityHistoryCardDto({
    required String id,
    required String originalIdentityId,
    required String action,
    required String name,
    required String idType,
    required String idNumber,
    String? fullName,
    DateTime? expiryDate,
    required bool verified,
    required DateTime actionAt,
  }) = _IdentityHistoryCardDto;

  factory IdentityHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$IdentityHistoryCardDtoFromJson(json);
}
