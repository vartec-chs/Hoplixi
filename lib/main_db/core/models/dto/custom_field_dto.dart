import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/vault_items/vault_item_custom_fields.dart';
import '../field_update.dart';

part 'custom_field_dto.freezed.dart';
part 'custom_field_dto.g.dart';

@freezed
sealed class CustomFieldDto with _$CustomFieldDto {
  const factory CustomFieldDto({
    String? id,
    String? itemId,
    required String label,
    String? value,
    @Default(CustomFieldType.text)
    CustomFieldType fieldType,
    @Default(false) bool isSecret,
    @Default(0) int sortOrder,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) = _CustomFieldDto;

  factory CustomFieldDto.fromJson(Map<String, dynamic> json) =>
      _$CustomFieldDtoFromJson(json);
}

@freezed
sealed class VaultItemCustomFieldCardDataDto with _$VaultItemCustomFieldCardDataDto {
  const factory VaultItemCustomFieldCardDataDto({
    required String id,
    required String itemId,
    required String label,
    required CustomFieldType fieldType,
    required bool isSecret,
    required int sortOrder,
    required bool hasValue,
    required DateTime createdAt,
    required DateTime modifiedAt,
  }) = _VaultItemCustomFieldCardDataDto;

  factory VaultItemCustomFieldCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$VaultItemCustomFieldCardDataDtoFromJson(json);
}

@freezed
sealed class PatchCustomFieldDto with _$PatchCustomFieldDto {
  const factory PatchCustomFieldDto({
    required String id,
    @Default(FieldUpdate.keep()) FieldUpdate<String> label,
    @Default(FieldUpdate.keep()) FieldUpdate<String> value,
    @Default(FieldUpdate.keep()) FieldUpdate<CustomFieldType> fieldType,
    @Default(FieldUpdate.keep()) FieldUpdate<bool> isSecret,
    @Default(FieldUpdate.keep()) FieldUpdate<int> sortOrder,
  }) = _PatchCustomFieldDto;
}
