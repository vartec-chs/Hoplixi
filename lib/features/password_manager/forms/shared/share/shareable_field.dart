import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/main_db/core/models/enums/entity_types.dart';

class ShareableField {
  const ShareableField({
    required this.id,
    required this.label,
    required this.value,
    this.isSensitive = false,
  });

  final String id;
  final String label;
  final String value;
  final bool isSensitive;

  bool get isNotEmpty => value.trim().isNotEmpty;
}

class ShareableEntity {
  const ShareableEntity({
    required this.title,
    required this.entityTypeLabel,
    required this.fields,
  });

  final String title;
  final String entityTypeLabel;
  final List<ShareableField> fields;

  List<ShareableField> get nonEmptyFields =>
      fields.where((field) => field.isNotEmpty).toList(growable: false);
}

ShareableField? shareableField({
  required String id,
  required String label,
  required Object? value,
  bool isSensitive = false,
}) {
  final text = _stringValue(value);
  if (text == null || text.trim().isEmpty) return null;

  return ShareableField(
    id: id,
    label: label,
    value: text,
    isSensitive: isSensitive,
  );
}

List<ShareableField> compactShareableFields(Iterable<ShareableField?> fields) {
  return fields.whereType<ShareableField>().toList(growable: false);
}

List<ShareableField> customFieldsToShareableFields(
  Iterable<CustomFieldEntry> fields,
) {
  return compactShareableFields(
    fields.map(
      (field) => shareableField(
        id: 'custom:${field.id ?? field.label}',
        label: field.label,
        value: field.value,
        isSensitive: field.fieldType == CustomFieldType.concealed,
      ),
    ),
  );
}

String? _stringValue(Object? value) {
  return switch (value) {
    null => null,
    DateTime value => value.toIso8601String(),
    Iterable<Object?> value =>
      value
          .map(_stringValue)
          .whereType<String>()
          .where((item) => item.trim().isNotEmpty)
          .join(', '),
    _ => value.toString(),
  };
}
