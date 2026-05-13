import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/vault_items/vault_item_custom_fields.dart';

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
