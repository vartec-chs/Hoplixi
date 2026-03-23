import 'package:freezed_annotation/freezed_annotation.dart';

part 'oauth_apps_errors.freezed.dart';

@freezed
abstract class OAuthAppsError with _$OAuthAppsError implements Exception {
  const OAuthAppsError._();

  const factory OAuthAppsError.notFound({
    @Default('OAUTH_APP_NOT_FOUND') String code,
    @Default('OAuth приложение не найдено') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = OAuthAppNotFoundError;

  const factory OAuthAppsError.alreadyExists({
    @Default('OAUTH_APP_ALREADY_EXISTS') String code,
    @Default('OAuth приложение с таким ID уже существует') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = OAuthAppAlreadyExistsError;

  const factory OAuthAppsError.storageError({
    @Default('OAUTH_APP_STORAGE_ERROR') String code,
    @Default('Ошибка при работе с хранилищем OAuth приложений') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = OAuthAppStorageError;

  const factory OAuthAppsError.serializationError({
    @Default('OAUTH_APP_SERIALIZATION_ERROR') String code,
    @Default('Ошибка при сериализации/десериализации OAuth приложения')
    String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = OAuthAppSerializationError;

  const factory OAuthAppsError.invalidData({
    @Default('OAUTH_APP_INVALID_DATA') String code,
    @Default('Некорректные данные OAuth приложения') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = OAuthAppInvalidDataError;
}
