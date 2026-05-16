import 'package:freezed_annotation/freezed_annotation.dart';

part 'db_error.freezed.dart';

@freezed
sealed class DbError with _$DbError {
  const factory DbError.notFound({
    required String entity,
    required String id,
    String? message,
  }) = DbNotFoundError;

  const factory DbError.validation({
    required String code,
    required String message,
    String? field,
    String? entity,
    @Default(<String, Object?>{}) Map<String, Object?> data,
  }) = DbValidationError;

  const factory DbError.constraint({
    required String constraint,
    required String message,
    String? table,
    String? field,
    String? entity,
    String? code,
    @Default(<String, Object?>{}) Map<String, Object?> data,
  }) = DbConstraintError;

  const factory DbError.conflict({
    required String code,
    required String message,
    String? entity,
    @Default(<String, Object?>{}) Map<String, Object?> data,
  }) = DbConflictError;

  const factory DbError.sqlite({
    required String message,
    String? statement,
    Object? cause,
    StackTrace? stackTrace,
  }) = DbSqliteError;

  const factory DbError.unknown({
    required String message,
    Object? cause,
    StackTrace? stackTrace,
  }) = DbUnknownError;
}
