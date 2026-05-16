import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';

part 'contact_history_card_dto.freezed.dart';
part 'contact_history_card_dto.g.dart';

@freezed
sealed class ContactHistoryCardDataDto with _$ContactHistoryCardDataDto {
  const factory ContactHistoryCardDataDto({
    String? firstName,
    String? middleName,
    String? lastName,
    String? phone,
    String? email,
    String? company,
    String? jobTitle,
    String? address,
    String? website,
    DateTime? birthday,
    bool? isEmergencyContact,
  }) = _ContactHistoryCardDataDto;

  factory ContactHistoryCardDataDto.fromJson(Map<String, dynamic> json) => _$ContactHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class ContactHistoryCardDto with _$ContactHistoryCardDto implements VaultHistoryCardDto {
  const factory ContactHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required ContactHistoryCardDataDto contact,
  }) = _ContactHistoryCardDto;

  factory ContactHistoryCardDto.fromJson(Map<String, dynamic> json) => _$ContactHistoryCardDtoFromJson(json);
}