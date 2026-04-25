import 'package:hoplixi/db_core/db/main_store.dart';
import 'package:hoplixi/db_core/old/models/dto/custom_field_dto.dart';
import 'package:hoplixi/db_core/old/models/enums/entity_types.dart';

/// UI-модель кастомного поля для использования в формах.
/// Не зависит от кодогенерации — простой иммутабельный Dart-класс.
class CustomFieldEntry {
  const CustomFieldEntry({
    this.id,
    required this.label,
    this.value,
    this.fieldType = CustomFieldType.text,
    this.isObscured = true,
  });

  /// [id] существующей записи в БД; null для нового несохранённого поля.
  final String? id;
  final String label;
  final String? value;
  final CustomFieldType fieldType;

  /// Скрыто ли значение в UI (актуально только для [CustomFieldType.concealed]).
  final bool isObscured;

  static const _sentinel = Object();

  CustomFieldEntry copyWith({
    Object? id = _sentinel,
    String? label,
    Object? value = _sentinel,
    CustomFieldType? fieldType,
    bool? isObscured,
  }) {
    return CustomFieldEntry(
      id: id == _sentinel ? this.id : id as String?,
      label: label ?? this.label,
      value: value == _sentinel ? this.value : value as String?,
      fieldType: fieldType ?? this.fieldType,
      isObscured: isObscured ?? this.isObscured,
    );
  }

  factory CustomFieldEntry.fromData(VaultItemCustomFieldsData data) {
    return CustomFieldEntry(
      id: data.id,
      label: data.label,
      value: data.value,
      fieldType: data.fieldType,
    );
  }

  CreateCustomFieldDto toCreateDto() {
    return CreateCustomFieldDto(
      label: label,
      value: value,
      fieldType: fieldType,
    );
  }
}
