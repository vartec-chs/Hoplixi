import 'package:freezed_annotation/freezed_annotation.dart';

import 'error_enums/error_enums.dart';

part 'app_error.freezed.dart';
part 'app_error.g.dart';

@freezed
sealed class AppError with _$AppError implements Exception {
  const AppError._();

  const factory AppError.mainDatabase({
    @JsonKey(unknownEnumValue: MainDatabaseErrorCode.unknown)
    required MainDatabaseErrorCode code,
    required String message,
    @Default(<String, dynamic>{}) Map<String, dynamic> data,
    String? debugMessage,
    @JsonKey(includeFromJson: false, includeToJson: false) Object? cause,
    @JsonKey(includeFromJson: false, includeToJson: false)
    StackTrace? stackTrace,
    DateTime? timestamp,
  }) = DatabaseAppError;

  const factory AppError.fileSystem({
    @JsonKey(unknownEnumValue: FileSystemErrorCode.unknown)
    required FileSystemErrorCode code,
    required String message,
    @Default(<String, dynamic>{}) Map<String, dynamic> data,
    String? debugMessage,
    @JsonKey(includeFromJson: false, includeToJson: false) Object? cause,
    @JsonKey(includeFromJson: false, includeToJson: false)
    StackTrace? stackTrace,
    DateTime? timestamp,
  }) = FileSystemAppError;

  const factory AppError.network({
    @JsonKey(unknownEnumValue: NetworkErrorCode.unknown)
    required NetworkErrorCode code,
    required String message,
    @Default(<String, dynamic>{}) Map<String, dynamic> data,
    String? debugMessage,
    @JsonKey(includeFromJson: false, includeToJson: false) Object? cause,
    @JsonKey(includeFromJson: false, includeToJson: false)
    StackTrace? stackTrace,
    DateTime? timestamp,
  }) = NetworkAppError;

  const factory AppError.validation({
    @JsonKey(unknownEnumValue: ValidationErrorCode.unknown)
    required ValidationErrorCode code,
    required String message,
    @Default(<String, dynamic>{}) Map<String, dynamic> data,
    String? debugMessage,
    @JsonKey(includeFromJson: false, includeToJson: false) Object? cause,
    @JsonKey(includeFromJson: false, includeToJson: false)
    StackTrace? stackTrace,
    DateTime? timestamp,
  }) = ValidationAppError;

  const factory AppError.auth({
    @JsonKey(unknownEnumValue: AuthErrorCode.unknown)
    required AuthErrorCode code,
    required String message,
    @Default(<String, dynamic>{}) Map<String, dynamic> data,
    String? debugMessage,
    @JsonKey(includeFromJson: false, includeToJson: false) Object? cause,
    @JsonKey(includeFromJson: false, includeToJson: false)
    StackTrace? stackTrace,
    DateTime? timestamp,
  }) = AuthAppError;

  const factory AppError.archive({
    @JsonKey(unknownEnumValue: ArchiveErrorCode.unknown)
    required ArchiveErrorCode code,
    required String message,
    @Default(<String, dynamic>{}) Map<String, dynamic> data,
    String? debugMessage,
    @JsonKey(includeFromJson: false, includeToJson: false) Object? cause,
    @JsonKey(includeFromJson: false, includeToJson: false)
    StackTrace? stackTrace,
    DateTime? timestamp,
  }) = ArchiveAppError;

  const factory AppError.unknown({
    @Default('UNKNOWN_ERROR') String code,
    @Default('Произошла неизвестная ошибка') String message,
    @Default(<String, dynamic>{}) Map<String, dynamic> data,
    String? debugMessage,
    @JsonKey(includeFromJson: false, includeToJson: false) Object? cause,
    @JsonKey(includeFromJson: false, includeToJson: false)
    StackTrace? stackTrace,
    DateTime? timestamp,
  }) = UnknownAppError;

  factory AppError.fromJson(Map<String, dynamic> json) =>
      _$AppErrorFromJson(json);

  String get description => '[$codeString] $message';

  DateTime get createdAt => timestamp ?? DateTime.now();

  String get codeString => when(
    mainDatabase:
        (code, message, data, debugMessage, cause, stackTrace, timestamp) =>
            code.value,
    fileSystem:
        (code, message, data, debugMessage, cause, stackTrace, timestamp) =>
            code.value,
    network:
        (code, message, data, debugMessage, cause, stackTrace, timestamp) =>
            code.value,
    validation:
        (code, message, data, debugMessage, cause, stackTrace, timestamp) =>
            code.value,
    auth: (code, message, data, debugMessage, cause, stackTrace, timestamp) =>
        code.value,
    archive:
        (code, message, data, debugMessage, cause, stackTrace, timestamp) =>
            code.value,
    unknown:
        (code, message, data, debugMessage, cause, stackTrace, timestamp) =>
            code,
  );

  bool get isDatabase => maybeWhen(
    mainDatabase: (_, __, ___, ____, _____, ______, _______) => true,
    orElse: () => false,
  );

  bool get isFileSystem => maybeWhen(
    fileSystem: (_, __, ___, ____, _____, ______, _______) => true,
    orElse: () => false,
  );

  bool get isNetwork => maybeWhen(
    network: (_, __, ___, ____, _____, ______, _______) => true,
    orElse: () => false,
  );

  bool get isValidation => maybeWhen(
    validation: (_, __, ___, ____, _____, ______, _______) => true,
    orElse: () => false,
  );

  bool get isAuth => maybeWhen(
    auth: (_, __, ___, ____, _____, ______, _______) => true,
    orElse: () => false,
  );

  bool get isArchive => maybeWhen(
    archive: (_, __, ___, ____, _____, ______, _______) => true,
    orElse: () => false,
  );

  bool get isUnknown => maybeWhen(
    unknown: (_, __, ___, ____, _____, ______, _______) => true,
    orElse: () => false,
  );
}
