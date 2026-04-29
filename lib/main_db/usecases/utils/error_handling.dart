import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:result_dart/result_dart.dart';

Failure<S, AppError> handleMainStoreUseCaseError<S extends Object>({
  required String message,
  required Object error,
  required StackTrace stackTrace,
  required String tag,
}) {
  logError(message, error: error, stackTrace: stackTrace, tag: tag);

  if (error is AppError) {
    return Failure<S, AppError>(error);
  }

  return Failure<S, AppError>(
    AppError.mainDatabase(
      code: MainDatabaseErrorCode.unknown,
      message: message,
      stackTrace: stackTrace,
      data: {'exception': error.toString()},
      timestamp: DateTime.now(),
    ),
  );
}
