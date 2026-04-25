import 'dart:io';

import '../app_error.dart';
import '../error_enums/error_enums.dart';

extension FileErrorToAppErrorExtension on Object {
  AppError toFileSystemAppError({
    String? message,
    Map<String, dynamic> data = const <String, dynamic>{},
    String? debugMessage,
    StackTrace? stackTrace,
    DateTime? timestamp,
  }) {
    if (this is AppError) {
      final appError = this as AppError;
      if (appError.isFileSystem) {
        return appError;
      }
    }

    if (this is FileSystemException) {
      final exception = this as FileSystemException;
      final resolvedCode = _resolveFileSystemErrorCode(exception);
      final resolvedData = <String, dynamic>{
        ...data,
        if (exception.path != null) 'path': exception.path!,
        if (exception.osError?.errorCode != null)
          'osErrorCode': exception.osError!.errorCode,
        if (exception.osError?.message != null)
          'osErrorMessage': exception.osError!.message,
      };

      return AppError.fileSystem(
        code: resolvedCode,
        message: message ?? _resolveFileSystemMessage(exception),
        data: resolvedData,
        debugMessage: debugMessage ?? exception.message,
        cause: exception,
        stackTrace: stackTrace,
        timestamp: timestamp ?? DateTime.now(),
      );
    }

    if (this is IOException) {
      final exception = this as IOException;
      return AppError.fileSystem(
        code: FileSystemErrorCode.unknown,
        message: message ?? exception.toString(),
        data: <String, dynamic>{
          ...data,
          'exceptionType': exception.runtimeType.toString(),
        },
        debugMessage: debugMessage,
        cause: exception,
        stackTrace: stackTrace,
        timestamp: timestamp ?? DateTime.now(),
      );
    }

    return AppError.fileSystem(
      code: FileSystemErrorCode.unknown,
      message: message ?? toString(),
      data: <String, dynamic>{...data, 'exceptionType': runtimeType.toString()},
      debugMessage: debugMessage,
      cause: this,
      stackTrace: stackTrace,
      timestamp: timestamp ?? DateTime.now(),
    );
  }
}

const Set<int> _notFoundOsCodes = <int>{2, 3};
const Set<int> _permissionDeniedOsCodes = <int>{5, 13};
const Set<int> _alreadyExistsOsCodes = <int>{17, 183};
const Set<int> _insufficientSpaceOsCodes = <int>{28, 112};

FileSystemErrorCode _resolveFileSystemErrorCode(FileSystemException exception) {
  final lowerMessage = exception.message.toLowerCase();
  final osCode = exception.osError?.errorCode;

  if (_notFoundOsCodes.contains(osCode) ||
      lowerMessage.contains('no such file') ||
      lowerMessage.contains('cannot find the path') ||
      lowerMessage.contains('not found')) {
    return FileSystemErrorCode.notFound;
  }

  if (_permissionDeniedOsCodes.contains(osCode) ||
      lowerMessage.contains('permission denied') ||
      lowerMessage.contains('access is denied')) {
    return FileSystemErrorCode.permissionDenied;
  }

  if (_alreadyExistsOsCodes.contains(osCode) ||
      lowerMessage.contains('already exists') ||
      lowerMessage.contains('file exists')) {
    return FileSystemErrorCode.alreadyExists;
  }

  if (_insufficientSpaceOsCodes.contains(osCode) ||
      lowerMessage.contains('no space left') ||
      lowerMessage.contains('not enough space') ||
      lowerMessage.contains('disk full')) {
    return FileSystemErrorCode.insufficientSpace;
  }

  if (lowerMessage.contains('invalid path') ||
      lowerMessage.contains('invalid argument') ||
      lowerMessage.contains('volume label syntax is incorrect')) {
    return FileSystemErrorCode.invalidPath;
  }

  if (lowerMessage.contains('read')) {
    return FileSystemErrorCode.readFailed;
  }

  if (lowerMessage.contains('write')) {
    return FileSystemErrorCode.writeFailed;
  }

  if (lowerMessage.contains('delete') || lowerMessage.contains('remove')) {
    return FileSystemErrorCode.deleteFailed;
  }

  if (lowerMessage.contains('create') || lowerMessage.contains('mkdir')) {
    return FileSystemErrorCode.createFailed;
  }

  return FileSystemErrorCode.unknown;
}

String _resolveFileSystemMessage(FileSystemException exception) {
  final sourceMessage = exception.message.trim();
  if (sourceMessage.isNotEmpty) {
    return sourceMessage;
  }

  final osMessage = exception.osError?.message?.trim();
  if (osMessage != null && osMessage.isNotEmpty) {
    return osMessage;
  }

  return 'File system operation failed';
}
