import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../tables/vault_items/vault_item_custom_fields.dart';

part 'custom_field_history_card_dto.freezed.dart';
part 'custom_field_history_card_dto.g.dart';

@freezed
sealed class VaultItemCustomFieldHistoryCardDataDto
    with _$VaultItemCustomFieldHistoryCardDataDto {
  const factory VaultItemCustomFieldHistoryCardDataDto({
    required String id,
    required String snapshotHistoryId,
    String? originalFieldId,
    required String label,
    required CustomFieldType fieldType,
    required bool isSecret,
    required int sortOrder,
    required bool hasValue,
    required DateTime createdAt,
    required DateTime modifiedAt,
    required DateTime historyCreatedAt,
  }) = _VaultItemCustomFieldHistoryCardDataDto;

  factory VaultItemCustomFieldHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$VaultItemCustomFieldHistoryCardDataDtoFromJson(json);
}
