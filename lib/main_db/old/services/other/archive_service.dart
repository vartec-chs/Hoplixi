import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/old/models/db_errors.dart';
import 'package:hoplixi/main_db/old/models/store_manifest.dart';
import 'package:hoplixi/main_db/old/services/store_manifest_service.dart';
import 'package:path/path.dart' as p;
import 'package:result_dart/result_dart.dart' as rd;

typedef ArchiveProgressCallback =
    void Function(int current, int total, String fileName);

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

class _ProgressMessage {
  final int current;
  final int total;
  final String fileName;

  _ProgressMessage(this.current, this.total, this.fileName);
}

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
  static const String _logTag = 'ArchiveService';
  static const String storeArchiveFileSuffix = ' (store).zip';

  static bool isStoreArchiveFile(String archivePath) {
    final fileName = p.basename(archivePath).toLowerCase();
    return fileName.endsWith(storeArchiveFileSuffix.toLowerCase());
  }

  static String suggestedStoreFolderName(String archivePath) {
    final fileName = p.basename(archivePath);
    if (isStoreArchiveFile(archivePath)) {
      return fileName.substring(
        0,
        fileName.length - storeArchiveFileSuffix.length,
      );
    }

    return p.basenameWithoutExtension(archivePath);
  }

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
        logInfo('Store archived: $outputPath', tag: _logTag);
        return rd.Success(outputPath);
      }

      return rd.Failure(
        DatabaseError.archiveFailed(
          message: result?.error ?? 'Неизвестная ошибка архивации',
        ),
      );
    } catch (e, s) {
      logError('Archive failed: $e', stackTrace: s, tag: _logTag);
      return rd.Failure(
        DatabaseError.archiveFailed(message: e.toString(), stackTrace: s),
      );
    }
  }

  Future<rd.ResultDart<String, DatabaseError>> unarchiveStore(
    String archivePath, {
    String? password,
    String? basePath,
    bool replaceExistingIfNewer = false,
    ArchiveProgressCallback? onProgress,
  }) async {
    String? stagingPath;
    String? backupPath;
    String? backupRestoreTargetPath;

    try {
      final archiveFile = File(archivePath);
      if (!await archiveFile.exists()) {
        return rd.Failure(
          DatabaseError.unarchiveFailed(
            message: 'Файл архива не найден: $archivePath',
          ),
        );
      }

      final storagesPath = basePath ?? await AppPaths.appStoragesPath;
      final rawStoreName = suggestedStoreFolderName(archivePath).trim();
      final storeName = rawStoreName.isEmpty ? 'imported_store' : rawStoreName;

      stagingPath = await _buildTemporaryStoreTargetPath(
        storagesPath,
        storeName,
      );
      await Directory(stagingPath).create(recursive: true);

      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _unarchiveInIsolate,
        _UnarchiveParams(
          archivePath: archivePath,
          password: password,
          targetPath: stagingPath,
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

      if (result?.success != true) {
        await _cleanupDirectory(stagingPath);

        if (result?.isInvalidPassword == true) {
          return rd.Failure(
            DatabaseError.archiveInvalidPassword(
              message: result?.error ?? 'Неверный пароль для архива',
            ),
          );
        }

        return rd.Failure(
          DatabaseError.unarchiveFailed(
            message: result?.error ?? 'Неизвестная ошибка разархивации',
          ),
        );
      }

      final finalTargetPath = await _resolveFinalTargetPath(
        storagesPath: storagesPath,
        storeName: storeName,
        stagingPath: stagingPath,
        replaceExistingIfNewer: replaceExistingIfNewer,
      );

      if (p.normalize(finalTargetPath) != p.normalize(stagingPath)) {
        final existingTargetDir = Directory(finalTargetPath);
        if (await existingTargetDir.exists()) {
          backupRestoreTargetPath = finalTargetPath;
          backupPath = await _moveStoreToBackups(finalTargetPath);
        }

        await _promoteUnarchivedStore(
          stagingPath: stagingPath,
          targetPath: finalTargetPath,
        );
      }

      logInfo('Store unarchived: $finalTargetPath', tag: _logTag);
      return rd.Success(finalTargetPath);
    } catch (e, s) {
      if (backupPath != null && backupRestoreTargetPath != null) {
        await _restoreStoreFromBackup(
          backupPath: backupPath,
          targetPath: backupRestoreTargetPath,
        );
      }

      if (stagingPath != null) {
        await _cleanupDirectory(stagingPath);
      }

      logError('Unarchive failed: $e', stackTrace: s, tag: _logTag);
      return rd.Failure(
        DatabaseError.unarchiveFailed(message: e.toString(), stackTrace: s),
      );
    }
  }

  static Future<void> _cleanupDirectory(String path) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e, s) {
      logError(
        'Failed to delete directory $path: $e',
        stackTrace: s,
        tag: _logTag,
      );
    }
  }

  static Future<void> _writeFileContentStreaming(
    ArchiveFile file,
    String outputPath,
  ) async {
    final outputStream = OutputFileStream(outputPath);

    try {
      file.writeContent(outputStream, freeMemory: true);
    } finally {
      await outputStream.close();
    }
  }

  static Future<String> _resolveFinalTargetPath({
    required String storagesPath,
    required String storeName,
    required String stagingPath,
    required bool replaceExistingIfNewer,
  }) async {
    if (!replaceExistingIfNewer) {
      return _buildUniqueStoreTargetPath(storagesPath, storeName);
    }

    final importedManifest = await StoreManifestService.readFrom(stagingPath);
    if (importedManifest == null) {
      return _buildUniqueStoreTargetPath(storagesPath, storeName);
    }

    final existingStore = await StoreManifestService.findLatestByStoreId(
      storagesPath,
      importedManifest.storeId,
      excludedPaths: {stagingPath},
    );

    if (existingStore == null) {
      return _buildUniqueStoreTargetPath(storagesPath, storeName);
    }

    if (!_shouldReplaceExistingStore(
      importedManifest: importedManifest,
      existingManifest: existingStore.manifest,
    )) {
      return _buildUniqueStoreTargetPath(storagesPath, storeName);
    }

    logInfo(
      'Replacing existing store ${existingStore.storagePath} with newer archive '
      'version for storeId=${importedManifest.storeId}',
      tag: _logTag,
    );

    return existingStore.storagePath;
  }

  static bool _shouldReplaceExistingStore({
    required StoreManifest importedManifest,
    required StoreManifest existingManifest,
  }) {
    return importedManifest.lastModified > existingManifest.lastModified;
  }

  static Future<void> _promoteUnarchivedStore({
    required String stagingPath,
    required String targetPath,
  }) async {
    final stagingDir = Directory(stagingPath);
    if (!await stagingDir.exists()) {
      throw StateError('Staging directory does not exist: $stagingPath');
    }

    final targetDir = Directory(targetPath);
    if (await targetDir.exists()) {
      throw StateError('Target directory already exists: $targetPath');
    }

    await targetDir.parent.create(recursive: true);
    await stagingDir.rename(targetPath);
  }

  static Future<String> _moveStoreToBackups(String storePath) async {
    final backupsPath = await AppPaths.backupsPath;
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final storeFolderName = p.basename(storePath);
    var backupPath = p.join(
      backupsPath,
      '${storeFolderName}_backup_$timestamp',
    );
    var suffix = 1;

    while (await Directory(backupPath).exists()) {
      backupPath = p.join(
        backupsPath,
        '${storeFolderName}_backup_${timestamp}_$suffix',
      );
      suffix++;
    }

    await Directory(storePath).rename(backupPath);
    logInfo('Store moved to backups: $backupPath', tag: _logTag);
    return backupPath;
  }

  static Future<void> _restoreStoreFromBackup({
    required String backupPath,
    required String targetPath,
  }) async {
    try {
      final backupDir = Directory(backupPath);
      if (!await backupDir.exists()) {
        return;
      }

      final targetDir = Directory(targetPath);
      if (await targetDir.exists()) {
        return;
      }

      await backupDir.rename(targetPath);
      logWarning(
        'Restored store from backup after failed replacement: $targetPath',
        tag: _logTag,
      );
    } catch (e, s) {
      logError(
        'Failed to restore store from backup $backupPath: $e',
        stackTrace: s,
        tag: _logTag,
      );
    }
  }

  static Future<String> _buildTemporaryStoreTargetPath(
    String storagesPath,
    String storeName,
  ) async {
    var suffix = 0;

    while (true) {
      final candidateName = suffix == 0
          ? '.__unarchive_$storeName'
          : '.__unarchive_${storeName}_$suffix';
      final candidatePath = p.join(storagesPath, candidateName);
      final candidateDir = Directory(candidatePath);

      if (!await candidateDir.exists()) {
        return candidatePath;
      }

      suffix++;
    }
  }

  static Future<String> _buildUniqueStoreTargetPath(
    String storagesPath,
    String storeName,
  ) async {
    var suffix = 0;

    while (true) {
      final candidateName = suffix == 0 ? storeName : '${storeName}_$suffix';
      final candidatePath = p.join(storagesPath, candidateName);
      final candidateDir = Directory(candidatePath);

      if (!await candidateDir.exists()) {
        return candidatePath;
      }

      suffix++;
    }
  }
}

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
    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      final relativePath = p.relative(file.path, from: storePath);
      sendPort.send(_ProgressMessage(index + 1, totalFiles, relativePath));
      await encoder.addFile(file);
    }
  } finally {
    encoder.close();
  }
}

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

    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      final relativePath = p.relative(file.path, from: storePath);
      sendPort.send(_ProgressMessage(index + 1, totalFiles, relativePath));

      final inputStream = InputFileStream(file.path);
      final archiveFile = ArchiveFile.stream(relativePath, inputStream);
      archive.add(archiveFile);
    }

    ZipEncoder(password: password).encode(archive, output: outputStream);
  } finally {
    await outputStream.close();
  }
}

void _unarchiveInIsolate(_UnarchiveParams params) async {
  try {
    final inputStream = InputFileStream(params.archivePath);

    try {
      final archive = ZipDecoder().decodeStream(
        inputStream,
        password: params.password,
      );

      final fileEntries = archive.where((file) => file.isFile).toList();
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
    final isInvalidPassword = _isPasswordError(errorMessage);
    params.sendPort.send(
      _IsolateResult.error(errorMessage, isInvalidPassword: isInvalidPassword),
    );
  }
}

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
