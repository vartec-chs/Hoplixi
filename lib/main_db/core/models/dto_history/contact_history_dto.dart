import 'package:freezed_annotation/freezed_annotation.dart';

import 'vault_snapshot_base_dto.dart';

part 'contact_history_dto.freezed.dart';
part 'contact_history_dto.g.dart';

@freezed
sealed class ContactHistoryDataDto with _$ContactHistoryDataDto {
  const factory ContactHistoryDataDto({
    String? phone,
    String? email,
    String? company,
    String? jobTitle,
    String? address,
    String? website,
    DateTime? birthday,
    @Default(false) bool isEmergencyContact,
  }) = _ContactHistoryDataDto;

  factory ContactHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$ContactHistoryDataDtoFromJson(json);
}

@freezed
sealed class ContactHistoryViewDto with _$ContactHistoryViewDto {
  const factory ContactHistoryViewDto({
    required VaultSnapshotViewDto snapshot,
    required ContactHistoryDataDto contact,
  }) = _ContactHistoryViewDto;

  factory ContactHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$ContactHistoryViewDtoFromJson(json);
}

@freezed
sealed class ContactHistoryCardDataDto with _$ContactHistoryCardDataDto {
  const factory ContactHistoryCardDataDto({
    String? phone,
    String? email,
    String? company,
    String? jobTitle,
    String? address,
    String? website,
    DateTime? birthday,
    @Default(false) bool isEmergencyContact,
  }) = _ContactHistoryCardDataDto;

  factory ContactHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$ContactHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class ContactHistoryCardDto with _$ContactHistoryCardDto {
  const factory ContactHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required ContactHistoryCardDataDto contact,
  }) = _ContactHistoryCardDto;

  factory ContactHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$ContactHistoryCardDtoFromJson(json);
}
