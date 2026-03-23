import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_service_errors.freezed.dart';

/// Ошибки TokenService
@freezed
abstract class TokenServiceError with _$TokenServiceError implements Exception {
  const TokenServiceError._();

  /// Ошибка хранилища
  const factory TokenServiceError.storageError({
    @Default('TOKEN_STORAGE_ERROR') String code,
    @Default('Ошибка работы с хранилищем токенов') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = StorageError;

  /// Токен не найден
  const factory TokenServiceError.tokenNotFound({
    @Default('TOKEN_NOT_FOUND') String code,
    @Default('Токен не найден') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = TokenNotFoundError;

  /// Токен уже существует
  const factory TokenServiceError.tokenAlreadyExists({
    @Default('TOKEN_ALREADY_EXISTS') String code,
    @Default('Токен с таким ID уже существует') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = TokenAlreadyExistsError;

  /// Невалидные данные
  const factory TokenServiceError.invalidData({
    @Default('INVALID_TOKEN_DATA') String code,
    @Default('Невалидные данные токена') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = InvalidDataError;

  /// Сервис не инициализирован
  const factory TokenServiceError.notInitialized({
    @Default('TOKEN_SERVICE_NOT_INITIALIZED') String code,
    @Default('TokenService не инициализирован') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = NotInitializedError;

  /// Операция не разрешена
  const factory TokenServiceError.operationNotAllowed({
    @Default('OPERATION_NOT_ALLOWED') String code,
    @Default('Операция не разрешена') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = OperationNotAllowedError;

  /// Неизвестная ошибка
  const factory TokenServiceError.unknown({
    @Default('UNKNOWN_TOKEN_ERROR') String code,
    @Default('Неизвестная ошибка') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = UnknownTokenError;
}
