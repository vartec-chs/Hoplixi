import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/system/custom_fields/vault_item_custom_fields.dart';
import 'package:drift/drift.dart';

/// UI-модель кастомного поля для использования в формах.
/// Не зависит от кодогенерации — простой иммутабельный Dart-класс.
class CustomFieldEntry {
  const CustomFieldEntry({
    this.id,
    required this.label,
    this.value,
    this.fieldType = CustomFieldType.text,
    this.isObscured = true,
    this.isSecret = false,
    this.sortOrder = 0,
  });

  /// [id] существующей записи в БД; null для нового несохранённого поля.
  final String? id;
  final String label;
  final String? value;
  final CustomFieldType fieldType;

  /// Скрыто ли значение в UI (актуально только для [CustomFieldType.concealed]).
  final bool isObscured;

  /// Флаг секретности поля.
  final bool isSecret;

  /// Порядок отображения.
  final int sortOrder;

  static const _sentinel = Object();

  CustomFieldEntry copyWith({
    Object? id = _sentinel,
    String? label,
    Object? value = _sentinel,
    CustomFieldType? fieldType,
    bool? isObscured,
    bool? isSecret,
    int? sortOrder,
  }) {
    return CustomFieldEntry(
      id: id == _sentinel ? this.id : id as String?,
      label: label ?? this.label,
      value: value == _sentinel ? this.value : value as String?,
      fieldType: fieldType ?? this.fieldType,
      isObscured: isObscured ?? this.isObscured,
      isSecret: isSecret ?? this.isSecret,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory CustomFieldEntry.fromData(VaultItemCustomFieldsData data) {
    return CustomFieldEntry(
      id: data.id,
      label: data.label,
      value: data.value,
      fieldType: data.fieldType,
      isSecret: data.isSecret,
      sortOrder: data.sortOrder,
    );
  }

  VaultItemCustomFieldsCompanion toCompanion(String itemId) {
    return VaultItemCustomFieldsCompanion.insert(
      id: id == null ? const Value.absent() : Value(id!),
      itemId: itemId,
      label: label,
      value: Value(value),
      fieldType: Value(fieldType),
      isSecret: Value(isSecret),
      sortOrder: Value(sortOrder),
    );
  }
}
