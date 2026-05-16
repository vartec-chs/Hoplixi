import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/main_db/core/errors/db_error.dart';
import 'package:hoplixi/main_db/core/errors/db_exception_mapper.dart';
import 'package:hoplixi/main_db/core/tables/api_key/api_key_items.dart';

void main() {
  group('DbExceptionMapper', () {
    test('extracts constraint name from CHECK constraint failed', () {
      const message =
          'SqliteException(787): CHECK constraint failed: chk_api_key_items_service_not_blank, constraint failed';
      final constraintName = extractConstraintName(message);
      expect(constraintName, 'chk_api_key_items_service_not_blank');
    });

    test(
      'maps known CHECK constraint to DBCoreError.constraint with details',
      () {
        final constraintName =
            ApiKeyItemConstraint.serviceNotBlank.constraintName;
        final message =
            'SqliteException(787): CHECK constraint failed: $constraintName, constraint failed';

        final error = mapDbException(Exception(message), StackTrace.empty);

        expect(error, isA<DbConstraintError>());
        final constraintError = error as DbConstraintError;
        expect(constraintError.constraint, constraintName);
        expect(constraintError.field, 'service');
        expect(constraintError.entity, 'apiKey');
        expect(constraintError.code, 'api_key.service.not_blank');
        expect(
          constraintError.message,
          'Название сервиса не может быть пустым',
        );
      },
    );

    test('maps unknown CHECK constraint to generic DBCoreError.constraint', () {
      const message =
          'SqliteException(787): CHECK constraint failed: unknown_constraint';

      final error = mapDbException(Exception(message), StackTrace.empty);

      expect(error, isA<DbConstraintError>());
      final constraintError = error as DbConstraintError;
      expect(constraintError.constraint, 'unknown_constraint');
      expect(constraintError.message, 'Нарушено ограничение базы данных');
    });

    test('maps foreign key error', () {
      const message = 'SqliteException(787): FOREIGN KEY constraint failed';

      final error = mapDbException(Exception(message), StackTrace.empty);

      expect(error, isA<DbConstraintError>());
      final constraintError = error as DbConstraintError;
      expect(constraintError.constraint, 'foreign_key');
      expect(constraintError.message, 'Нарушена ссылочная целостность данных');
    });

    test('maps unique constraint error', () {
      const message =
          'SqliteException(2067): UNIQUE constraint failed: table.column';

      final error = mapDbException(Exception(message), StackTrace.empty);

      expect(error, isA<DbConstraintError>());
      final constraintError = error as DbConstraintError;
      expect(constraintError.constraint, 'unique');
      expect(constraintError.message, 'Такая запись уже существует');
    });

    test('maps unknown error to DbSqliteError', () {
      final exception = Exception('Some weird database error');
      final error = mapDbException(exception, StackTrace.empty);

      expect(error, isA<DbSqliteError>());
      final sqliteError = error as DbSqliteError;
      expect(sqliteError.message, 'Ошибка базы данных');
      expect(sqliteError.cause, exception);
    });
  });
}
