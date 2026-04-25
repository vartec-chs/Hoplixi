import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_db/core/models/enums/index.dart';

part 'custom_field_dto.freezed.dart';
part 'custom_field_dto.g.dart';

/// DTO кастомного поля для отображения
@freezed
sealed class CustomFieldDto with _$CustomFieldDto {
  const factory CustomFieldDto({
    required String id,
    required String itemId,
    required String label,
    String? value,
    required CustomFieldType fieldType,
    required int sortOrder,
  }) = _CustomFieldDto;

  factory CustomFieldDto.fromJson(Map<String, dynamic> json) =>
      _$CustomFieldDtoFromJson(json);
}

/// DTO для создания кастомного поля
@freezed
sealed class CreateCustomFieldDto with _$CreateCustomFieldDto {
  const factory CreateCustomFieldDto({
    required String label,
    String? value,
    @Default(CustomFieldType.text) CustomFieldType fieldType,
    @Default(0) int sortOrder,
  }) = _CreateCustomFieldDto;

  factory CreateCustomFieldDto.fromJson(Map<String, dynamic> json) =>
      _$CreateCustomFieldDtoFromJson(json);
}

/// DTO для обновления кастомного поля
@freezed
sealed class UpdateCustomFieldDto with _$UpdateCustomFieldDto {
  const factory UpdateCustomFieldDto({
    String? label,
    String? value,
    bool? clearValue,
    CustomFieldType? fieldType,
    int? sortOrder,
  }) = _UpdateCustomFieldDto;

  factory UpdateCustomFieldDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateCustomFieldDtoFromJson(json);
}
