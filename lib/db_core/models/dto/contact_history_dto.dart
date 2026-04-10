import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact_history_dto.freezed.dart';
part 'contact_history_dto.g.dart';

@freezed
sealed class ContactHistoryCardDto with _$ContactHistoryCardDto {
  const factory ContactHistoryCardDto({
    required String id,
    required String originalContactId,
    required String action,
    required String name,
    String? phone,
    String? email,
    String? company,
    required bool isEmergencyContact,
    required DateTime actionAt,
  }) = _ContactHistoryCardDto;

  factory ContactHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$ContactHistoryCardDtoFromJson(json);
}
