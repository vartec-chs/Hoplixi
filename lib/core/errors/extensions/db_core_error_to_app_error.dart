import 'package:hoplixi/core/errors/error_enums/error_enums.dart';
import 'package:hoplixi/vault_db/core/errors/db_error.dart';

import '../app_error.dart';

extension DBCoreErrorToAppError on DBCoreError {
  AppError toAppError() {
    return switch (this) {
      DbNotFoundError(:final entity, :final id, :final message) =>
        AppError.mainDatabase(
          code: MainDatabaseErrorCode.recordNotFound,
          message: message ?? '$entity не найден',
          data: {'entity': entity, 'id': id},
          cause: this,
        ),

      DbValidationError(
        :final code,
        :final message,
        :final field,
        :final entity,
        :final data,
      ) =>
        AppError.validation(
          code: ValidationErrorCode.invalidInput,
          message: message,
          data: {...data, 'dbCode': code, 'field': ?field, 'entity': ?entity},
          cause: this,
        ),

      DbConstraintError(
        :final constraint,
        :final message,
        :final table,
        :final field,
        :final entity,
        :final code,
        :final data,
      ) =>
        AppError.mainDatabase(
          code: MainDatabaseErrorCode.validationError,
          message: message,
          data: {
            ...data,
            'constraint': constraint,
            'table': ?table,
            'field': ?field,
            'entity': ?entity,
            'dbCode': ?code,
          },
          cause: this,
        ),

      DbConflictError(
        :final code,
        :final message,
        :final entity,
        :final data,
      ) =>
        AppError.mainDatabase(
          code: MainDatabaseErrorCode.queryFailed,
          message: message,
          data: {...data, 'dbCode': code, 'entity': ?entity},
          cause: this,
        ),

      DbSqliteError(
        :final message,
        :final statement,
        :final cause,
        :final stackTrace,
      ) =>
        AppError.mainDatabase(
          code: MainDatabaseErrorCode.queryFailed,
          message: 'Ошибка базы данных',
          debugMessage: message,
          data: {'statement': ?statement},
          cause: cause ?? this,
          stackTrace: stackTrace,
        ),

      DbUnknownError(:final message, :final cause, :final stackTrace) =>
        AppError.mainDatabase(
          code: MainDatabaseErrorCode.unknown,
          message: 'Неизвестная ошибка базы данных',
          debugMessage: message,
          cause: cause ?? this,
          stackTrace: stackTrace,
        ),
    };
  }
}

Future<T> mapDbErrors<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DBCoreError catch (e) {
    throw e.toAppError();
  } catch (e, st) {
    throw AppError.unknown(
      message: 'Неизвестная ошибка',
      cause: e,
      stackTrace: st,
    );
  }
}
