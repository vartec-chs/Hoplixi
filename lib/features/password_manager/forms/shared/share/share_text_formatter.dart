import 'shareable_field.dart';

String buildShareText(ShareableEntity entity, Set<String> selectedFieldIds) {
  final buffer = StringBuffer(entity.title.trim());
  final fields = entity.nonEmptyFields.where(
    (field) => selectedFieldIds.contains(field.id),
  );

  for (final field in fields) {
    buffer
      ..writeln()
      ..writeln();
    _writeField(buffer, field);
  }

  return buffer.toString().trimRight();
}

void _writeField(StringBuffer buffer, ShareableField field) {
  final value = field.value.trimRight();
  if (!value.contains('\n')) {
    buffer.write('${field.label}: $value');
    return;
  }

  buffer.writeln('${field.label}:');
  buffer.write(value);
}
