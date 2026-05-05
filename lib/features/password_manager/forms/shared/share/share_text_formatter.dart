import 'shareable_field.dart';

String buildShareText(ShareableEntity entity, Set<String> selectedFieldIds) {
  final fields = entity.nonEmptyFields.where(
    (field) => selectedFieldIds.contains(field.id),
  );

  return buildShareTextFromFields(fields, title: entity.title);
}

String buildShareTextFromFields(
  Iterable<ShareableField> fields, {
  String? title,
}) {
  final buffer = StringBuffer();
  final trimmedTitle = title?.trim();
  var needsSeparator = false;

  if (trimmedTitle != null && trimmedTitle.isNotEmpty) {
    buffer.write(trimmedTitle);
    needsSeparator = true;
  }

  for (final field in fields) {
    if (needsSeparator) {
      buffer
        ..writeln()
        ..writeln();
    }

    _writeField(buffer, field);
    needsSeparator = true;
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
