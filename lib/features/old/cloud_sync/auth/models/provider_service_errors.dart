import 'package:freezed_annotation/freezed_annotation.dart';

part 'provider_service_errors.freezed.dart';

@freezed
abstract class ProviderServiceError
    with _$ProviderServiceError
    implements Exception {
  const ProviderServiceError._();

  const factory ProviderServiceError.initializationFailed({
    @Default('PROVIDER_INIT_FAILED') String code,
    @Default('Не удалось инициализировать ProviderService') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = InitializationFailedError;

  const factory ProviderServiceError.unsupportedProvider({
    @Default('PROVIDER_UNSUPPORTED') String code,
    @Default('Провайдер не поддерживается') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = UnsupportedProviderError;

  const factory ProviderServiceError.registrationFailed({
    @Default('PROVIDER_REGISTRATION_FAILED') String code,
    @Default('Не удалось зарегистрировать провайдер') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = RegistrationFailedError;

  const factory ProviderServiceError.loginFailed({
    @Default('PROVIDER_LOGIN_FAILED') String code,
    @Default('Не удалось выполнить вход') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = LoginFailedError;

  const factory ProviderServiceError.autoLoginFailed({
    @Default('PROVIDER_AUTO_LOGIN_FAILED') String code,
    @Default('Не удалось выполнить автоматический вход') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = AutoLoginFailedError;

  const factory ProviderServiceError.reloginFailed({
    @Default('PROVIDER_RELOGIN_FAILED') String code,
    @Default('Не удалось выполнить повторный вход') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = ReloginFailedError;

  const factory ProviderServiceError.refreshFailed({
    @Default('PROVIDER_REFRESH_FAILED') String code,
    @Default('Не удалось обновить токен') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = RefreshFailedError;

  const factory ProviderServiceError.operationFailed({
    @Default('PROVIDER_OPERATION_FAILED') String code,
    @Default('Операция не удалась') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = OperationFailedError;

  const factory ProviderServiceError.notInitialized({
    @Default('PROVIDER_NOT_INITIALIZED') String code,
    @Default('ProviderService не инициализирован') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = NotInitializedError;

  const factory ProviderServiceError.noTokenFound({
    @Default('PROVIDER_NO_TOKEN_FOUND') String code,
    @Default('Токен не найден') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = NoTokenFoundError;

  const factory ProviderServiceError.providerNotFound({
    @Default('PROVIDER_NOT_FOUND') String code,
    @Default('Провайдер не найден') String message,
    String? provider,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = ProviderNotFoundError;

  const factory ProviderServiceError.unknown({
    @Default('PROVIDER_UNKNOWN_ERROR') String code,
    @Default('Неизвестная ошибка') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = UnknownError;
}
