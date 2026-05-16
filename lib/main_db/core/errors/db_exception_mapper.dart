import 'db_constraint_registry.dart';
import 'db_error.dart';

DbError mapDbException(Object error, StackTrace stackTrace) {
  final message = error.toString();

  if (_isUniqueError(message)) {
    return DbError.constraint(
      constraint: 'unique',
      message: 'Такая запись уже существует',
      data: {
        'rawMessage': message,
      },
    );
  }

  if (_isForeignKeyError(message)) {
    return DbError.constraint(
      constraint: 'foreign_key',
      message: 'Нарушена ссылочная целостность данных',
      data: {
        'rawMessage': message,
      },
    );
  }

  final constraintName = extractConstraintName(message);

  if (constraintName != null) {
    final descriptor = dbConstraintRegistry[constraintName];

    if (descriptor != null) {
      return DbError.constraint(
        constraint: descriptor.constraint,
        table: descriptor.table,
        entity: descriptor.entity,
        field: descriptor.field,
        code: descriptor.code,
        message: descriptor.message,
        data: {
          'rawMessage': message,
        },
      );
    }

    return DbError.constraint(
      constraint: constraintName,
      message: 'Нарушено ограничение базы данных',
      data: {
        'rawMessage': message,
      },
    );
  }

  return DbError.sqlite(
    message: 'Ошибка базы данных',
    cause: error,
    stackTrace: stackTrace,
  );
}

String? extractConstraintName(String message) {
  final checkPatterns = [
    RegExp(r'CHECK constraint failed: ([a-zA-Z0-9_]+)'),
    RegExp(r'constraint failed: ([a-zA-Z0-9_]+)'),
  ];

  for (final pattern in checkPatterns) {
    final match = pattern.firstMatch(message);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
  }

  return null;
}

bool _isForeignKeyError(String message) {
  return message.toLowerCase().contains('foreign key constraint failed');
}

bool _isUniqueError(String message) {
  return message.toLowerCase().contains('unique constraint failed');
}
