import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/models/db_errors.dart';
import 'package:path/path.dart' as p;
import 'package:result_dart/result_dart.dart' as rd;

/// Callback для отслеживания прогресса архивации/разархивации
/// [current] - текущий обработанный файл
/// [total] - общее количество файлов
/// [fileName] - имя текущего обрабатываемого файла
typedef ArchiveProgressCallback =
    void Function(int current, int total, String fileName);

/// Параметры для архивации в изоляте
class _ArchiveParams {
  final String storePath;
  final String outputPath;
  final String? password;
  final SendPort sendPort;

  _ArchiveParams({
    required this.storePath,
    required this.outputPath,
    this.password,
    required this.sendPort,
  });
}

/// Параметры для разархивации в изоляте
class _UnarchiveParams {
  final String archivePath;
  final String? password;
  final String targetPath;
  final SendPort sendPort;

  _UnarchiveParams({
    required this.archivePath,
    this.password,
    required this.targetPath,
    required this.sendPort,
  });
}

/// Сообщение о прогрессе
class _ProgressMessage {
  final int current;
  final int total;
  final String fileName;

  _ProgressMessage(this.current, this.total, this.fileName);
}

/// Результат работы изолята
class _IsolateResult {
  final bool success;
  final String? data;
  final String? error;
  final bool isInvalidPassword;

  _IsolateResult.success(this.data)
    : success = true,
      error = null,
      isInvalidPassword = false;

  _IsolateResult.error(this.error, {this.isInvalidPassword = false})
    : success = false,
      data = null;
}

class ArchiveService {
  /// Архивация хранилища
  /// [storePath] - путь к папке хранилища
  /// [outputPath] - путь куда сохранить архив (включая имя файла)
  /// [password] - пароль для архива (опционально)
  /// [onProgress] - callback для отслеживания прогресса
  Future<rd.ResultDart<String, DatabaseError>> archiveStore(
    String storePath,
    String outputPath, {
    String? password,
    ArchiveProgressCallback? onProgress,
  }) async {
    try {
      final storeDir = Directory(storePath);
      if (!await storeDir.exists()) {
        return rd.Failure(
          DatabaseError.archiveFailed(
            message: 'Папка хранилища не найдена: $storePath',
          ),
        );
      }

      final outFile = File(outputPath);
      await outFile.parent.create(recursive: true);

      // Создаём порт для получения сообщений из изолята
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _archiveInIsolate,
        _ArchiveParams(
          storePath: storePath,
          outputPath: outputPath,
          password: password,
          sendPort: receivePort.sendPort,
        ),
      );

      _IsolateResult? result;

      await for (final message in receivePort) {
        if (message is _ProgressMessage) {
          onProgress?.call(message.current, message.total, message.fileName);
        } else if (message is _IsolateResult) {
          result = message;
          break;
        }
      }

      receivePort.close();
      isolate.kill();

      if (result?.success == true) {
        logInfo('Хранилище заархивировано: $outputPath', tag: 'ArchiveService');
        return rd.Success(outputPath);
      } else {
        return rd.Failure(
          DatabaseError.archiveFailed(
            message: result?.error ?? 'Неизвестная ошибка архивации',
          ),
        );
      }
    } catch (e, s) {
      logError(
        'Ошибка при архивации: $e',
        stackTrace: s,
        tag: 'ArchiveService',
      );
      return rd.Failure(
        DatabaseError.archiveFailed(message: e.toString(), stackTrace: s),
      );
    }
  }

  /// Разархивация хранилища
  /// [archivePath] - путь к файлу архива
  /// [password] - пароль от архива (опционально)
  /// [basePath] - базовый путь для распаковки (по умолчанию AppPaths.appStoragePath)
  /// [onProgress] - callback для отслеживания прогресса
  /// Возвращает путь к папке с разархивированным хранилищем
  Future<rd.ResultDart<String, DatabaseError>> unarchiveStore(
    String archivePath, {
    String? password,
    String? basePath,
    ArchiveProgressCallback? onProgress,
  }) async {
    try {
      final archiveFile = File(archivePath);
      if (!await archiveFile.exists()) {
        return rd.Failure(
          DatabaseError.unarchiveFailed(
            message: 'Файл архива не найден: $archivePath',
          ),
        );
      }

      final storagesPath = basePath ?? await AppPaths.appStoragePath;
      final storeName = p.basenameWithoutExtension(archivePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = p.join(storagesPath, '${storeName}_$timestamp');

      final targetDir = Directory(targetPath);
      await targetDir.create(recursive: true);

      // Создаём порт для получения сообщений из изолята
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _unarchiveInIsolate,
        _UnarchiveParams(
          archivePath: archivePath,
          password: password,
          targetPath: targetPath,
          sendPort: receivePort.sendPort,
        ),
      );

      _IsolateResult? result;

      await for (final message in receivePort) {
        if (message is _ProgressMessage) {
          onProgress?.call(message.current, message.total, message.fileName);
        } else if (message is _IsolateResult) {
          result = message;
          break;
        }
      }

      receivePort.close();
      isolate.kill();

      if (result?.success == true) {
        logInfo(
          'Хранилище разархивировано: $targetPath',
          tag: 'ArchiveService',
        );
        return rd.Success(targetPath);
      } else if (result?.isInvalidPassword == true) {
        // Удаляем созданную папку при ошибке
        await _cleanupDirectory(targetPath);
        return rd.Failure(
          DatabaseError.archiveInvalidPassword(
            message: result?.error ?? 'Неверный пароль для архива',
          ),
        );
      } else {
        // Удаляем созданную папку при ошибке
        await _cleanupDirectory(targetPath);
        return rd.Failure(
          DatabaseError.unarchiveFailed(
            message: result?.error ?? 'Неизвестная ошибка разархивации',
          ),
        );
      }
    } catch (e, s) {
      logError(
        'Ошибка при разархивации: $e',
        stackTrace: s,
        tag: 'ArchiveService',
      );
      return rd.Failure(
        DatabaseError.unarchiveFailed(message: e.toString(), stackTrace: s),
      );
    }
  }

  /// Удаляет директорию если она существует
  static Future<void> _cleanupDirectory(String path) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      logError('Не удалось удалить папку $path: $e', tag: 'ArchiveService');
    }
  }

  /// Записывает содержимое архивного файла на диск потоково
  static Future<void> _writeFileContentStreaming(
    ArchiveFile file,
    String outputPath,
  ) async {
    final outputStream = OutputFileStream(outputPath);

    try {
      // Используем writeContent для потоковой записи
      // freeMemory: true освобождает память после записи
      file.writeContent(outputStream, freeMemory: true);
    } finally {
      await outputStream.close();
    }
  }
}

/// Top-level функция для архивации в изоляте
void _archiveInIsolate(_ArchiveParams params) async {
  try {
    final storeDir = Directory(params.storePath);
    final files = storeDir.listSync(recursive: true).whereType<File>().toList();
    final totalFiles = files.length;

    if (params.password != null && params.password!.isNotEmpty) {
      await _archiveWithPasswordStreamingIsolate(
        files: files,
        storePath: params.storePath,
        outputPath: params.outputPath,
        password: params.password!,
        totalFiles: totalFiles,
        sendPort: params.sendPort,
      );
    } else {
      await _archiveWithoutPasswordStreamingIsolate(
        files: files,
        storePath: params.storePath,
        outputPath: params.outputPath,
        totalFiles: totalFiles,
        sendPort: params.sendPort,
      );
    }

    params.sendPort.send(_IsolateResult.success(params.outputPath));
  } catch (e) {
    params.sendPort.send(_IsolateResult.error(e.toString()));
  }
}

/// Архивация без пароля в изоляте
Future<void> _archiveWithoutPasswordStreamingIsolate({
  required List<File> files,
  required String storePath,
  required String outputPath,
  required int totalFiles,
  required SendPort sendPort,
}) async {
  final encoder = ZipFileEncoder();
  encoder.create(outputPath);

  try {
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final relativePath = p.relative(file.path, from: storePath);
      sendPort.send(_ProgressMessage(i + 1, totalFiles, relativePath));
      await encoder.addFile(file);
    }
  } finally {
    encoder.close();
  }
}

/// Архивация с паролем в изоляте
Future<void> _archiveWithPasswordStreamingIsolate({
  required List<File> files,
  required String storePath,
  required String outputPath,
  required String password,
  required int totalFiles,
  required SendPort sendPort,
}) async {
  final outputStream = OutputFileStream(outputPath);

  try {
    final archive = Archive();

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final relativePath = p.relative(file.path, from: storePath);
      sendPort.send(_ProgressMessage(i + 1, totalFiles, relativePath));

      final inputStream = InputFileStream(file.path);
      final archiveFile = ArchiveFile.stream(relativePath, inputStream);
      archive.add(archiveFile);
    }

    ZipEncoder(password: password).encode(archive, output: outputStream);
  } finally {
    await outputStream.close();
  }
}

/// Top-level функция для разархивации в изоляте
void _unarchiveInIsolate(_UnarchiveParams params) async {
  try {
    final inputStream = InputFileStream(params.archivePath);

    try {
      final archive = ZipDecoder().decodeStream(
        inputStream,
        password: params.password,
      );

      final fileEntries = archive.where((f) => f.isFile).toList();
      final totalFiles = fileEntries.length;
      var currentFile = 0;

      for (final file in archive) {
        final filename = file.name;

        if (file.isFile) {
          currentFile++;
          params.sendPort.send(
            _ProgressMessage(currentFile, totalFiles, filename),
          );

          final outFilePath = p.join(params.targetPath, filename);
          final outFile = File(outFilePath);
          await outFile.parent.create(recursive: true);

          await ArchiveService._writeFileContentStreaming(file, outFilePath);
        } else {
          await Directory(
            p.join(params.targetPath, filename),
          ).create(recursive: true);
        }
      }
    } finally {
      await inputStream.close();
    }

    params.sendPort.send(_IsolateResult.success(params.targetPath));
  } catch (e) {
    final errorMessage = e.toString();
    // Определяем ошибку неверного пароля по характерным сообщениям
    final isInvalidPassword = _isPasswordError(errorMessage);
    params.sendPort.send(
      _IsolateResult.error(errorMessage, isInvalidPassword: isInvalidPassword),
    );
  }
}

/// Определяет, является ли ошибка ошибкой неверного пароля
/// При неверном пароле библиотека archive выбрасывает FormatException
/// с характерными сообщениями о CRC, checksum или corrupted данных
/// При отсутствии пароля для защищённого архива может быть Null check ошибка
bool _isPasswordError(String errorMessage) {
  final lowerMessage = errorMessage.toLowerCase();
  return lowerMessage.contains('crc') ||
      lowerMessage.contains('checksum') ||
      lowerMessage.contains('invalid') ||
      lowerMessage.contains('corrupted') ||
      lowerMessage.contains('password') ||
      lowerMessage.contains('decrypt') ||
      lowerMessage.contains('null');
}
