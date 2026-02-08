import 'package:drift/native.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'db_errors.freezed.dart';

@freezed
sealed class DatabaseError with _$DatabaseError implements Exception {
  const DatabaseError._();

  const factory DatabaseError.invalidPassword({
    @Default('DB_INVALID_PASSWORD') String code,
    @Default('Неверный пароль для базы данных') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = InvalidPasswordError;

  const factory DatabaseError.notInitialized({
    @Default('DB_NOT_INITIALIZED') String code,
    @Default('База данных не инициализирована') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = NotInitializedError;

  const factory DatabaseError.alreadyInitialized({
    @Default('DB_ALREADY_INITIALIZED') String code,
    @Default('База данных уже инициализирована') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = AlreadyInitializedError;

  const factory DatabaseError.connectionFailed({
    @Default('DB_CONNECTION_FAILED') String code,
    @Default('Не удалось подключиться к базе данных') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = ConnectionFailedError;

  const factory DatabaseError.queryFailed({
    @Default('DB_QUERY_FAILED') String code,
    @Default('Не удалось выполнить запрос к базе данных') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = QueryFailedError;

  const factory DatabaseError.archiveFailed({
    @Default('DB_ARCHIVE_FAILED') String code,
    @Default('Не удалось создать архив') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = ArchiveFailedError;

  const factory DatabaseError.unarchiveFailed({
    @Default('DB_UNARCHIVE_FAILED') String code,
    @Default('Не удалось распаковать архив') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = UnarchiveFailedError;

  const factory DatabaseError.recordNotFound({
    @Default('DB_RECORD_NOT_FOUND') String code,
    @Default('Запись не найдена в базе данных') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = RecordNotFoundError;

  const factory DatabaseError.insertFailed({
    @Default('DB_INSERT_FAILED') String code,
    @Default('Не удалось добавить запись в базу данных') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = InsertFailedError;

  const factory DatabaseError.updateFailed({
    @Default('DB_UPDATE_FAILED') String code,
    @Default('Не удалось обновить запись в базе данных') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = UpdateFailedError;

  const factory DatabaseError.deleteFailed({
    @Default('DB_DELETE_FAILED') String code,
    @Default('Не удалось удалить запись из базы данных') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = DeleteFailedError;

  const factory DatabaseError.migrationFailed({
    @Default('DB_MIGRATION_FAILED') String code,
    @Default('Не удалось выполнить миграцию базы данных') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = MigrationFailedError;

  const factory DatabaseError.corruptedDatabase({
    @Default('DB_CORRUPTED') String code,
    @Default('База данных повреждена') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = CorruptedDatabaseError;

  const factory DatabaseError.encryptionFailed({
    @Default('DB_ENCRYPTION_FAILED') String code,
    @Default('Не удалось зашифровать базу данных') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = EncryptionFailedError;

  const factory DatabaseError.decryptionFailed({
    @Default('DB_DECRYPTION_FAILED') String code,
    @Default('Не удалось расшифровать базу данных') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = DecryptionFailedError;

  const factory DatabaseError.transactionFailed({
    @Default('DB_TRANSACTION_FAILED') String code,
    @Default('Не удалось выполнить транзакцию') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = TransactionFailedError;

  //validation error
  const factory DatabaseError.validationError({
    @Default('DB_VALIDATION_ERROR') String code,
    @Default('Ошибка валидации данных для базы данных') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = ValidationError;

  const factory DatabaseError.unknown({
    @Default('DB_UNKNOWN_ERROR') String code,
    @Default('Неизвестная ошибка базы данных') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = UnknownDatabaseError;

  String get description => '$code — $message';

  DatabaseError dbErrorFromException(Object e, [StackTrace? st]) {
    if (e is SqliteException) {
      if (e.message.contains('file is not a database') ?? false) {
        return DatabaseError.corruptedDatabase(
          message: e.message ?? 'Corrupted DB',
          data: {'original': e.toString()},
          stackTrace: st,
          timestamp: DateTime.now(),
        );
      }
      // маппинг кодов/сообщений -> варианты
    }

    return DatabaseError.unknown(
      message: e.toString(),
      data: {'exception': e.runtimeType.toString()},
      stackTrace: st,
      timestamp: DateTime.now(),
    );
  }
}
