import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/vault_items/vault_item_custom_fields.dart';
import 'vault_snapshot_base_dto.dart';

part 'custom_field_history_dto.freezed.dart';
part 'custom_field_history_dto.g.dart';

@freezed
sealed class CustomFieldHistoryDataDto with _$CustomFieldHistoryDataDto {
  const factory CustomFieldHistoryDataDto({
    required String id,
    String? originalFieldId,
    required String label,
    String? value,
    @Default(CustomFieldType.text) CustomFieldType fieldType,
    @Default(false) bool isSecret,
    @Default(0) int sortOrder,
    required DateTime createdAt,
    required DateTime modifiedAt,
    required DateTime historyCreatedAt,
  }) = _CustomFieldHistoryDataDto;

  factory CustomFieldHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$CustomFieldHistoryDataDtoFromJson(json);
}

@freezed
sealed class CustomFieldHistoryViewDto with _$CustomFieldHistoryViewDto {
  const factory CustomFieldHistoryViewDto({
    required VaultSnapshotViewDto snapshot,
    @Default([]) List<CustomFieldHistoryDataDto> customFields,
  }) = _CustomFieldHistoryViewDto;

  factory CustomFieldHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$CustomFieldHistoryViewDtoFromJson(json);
}

@freezed
sealed class CustomFieldHistoryCardDataDto
    with _$CustomFieldHistoryCardDataDto {
  const factory CustomFieldHistoryCardDataDto({
    required String label,
    @Default(CustomFieldType.text) CustomFieldType fieldType,
    @Default(false) bool isSecret,
    required bool hasValue,
  }) = _CustomFieldHistoryCardDataDto;

  factory CustomFieldHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$CustomFieldHistoryCardDataDtoFromJson(json);
}
