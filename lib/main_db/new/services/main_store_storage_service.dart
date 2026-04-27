import 'dart:io';

import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:path/path.dart' as p;

class MainStoreFileService {
  static const String _logTag = 'MainStoreFileService';

  static const String attachmentsFolder = 'attachments';
  static const String decryptedAttachmentsFolder = 'attachments_decrypted';

  const MainStoreFileService();

  String getAttachmentsPath(String storePath) {
    return p.join(storePath, attachmentsFolder);
  }

  String getDecryptedAttachmentsPath(String storePath) {
    return p.join(storePath, decryptedAttachmentsFolder);
  }

  Future<String> createSubfolder({
    required String storePath,
    required String folderName,
  }) async {
    final normalizedStorePath = storePath.trim();
    final normalizedFolderName = folderName.trim();

    if (normalizedStorePath.isEmpty || normalizedFolderName.isEmpty) {
      throw AppError.validation(
        code: ValidationErrorCode.invalidInput,
        message: 'Путь хранилища или имя папки не указаны',
        timestamp: DateTime.now(),
      );
    }

    final directory = Directory(p.join(normalizedStorePath, normalizedFolderName));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  Future<bool> storageDirectoryExists(String path) {
    return Directory(path).exists();
  }

  Future<void> deleteStorageDirectory(String path) async {
    await Directory(path).delete(recursive: true);
  }

  Future<String> resolveExistingStoragePath(String path) async {
    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty) {
      throw AppError.validation(
        code: ValidationErrorCode.invalidInput,
        message: 'Путь к хранилищу не указан',
        timestamp: DateTime.now(),
      );
    }

    final storageDir = Directory(normalizedPath);
    if (await storageDir.exists()) {
      return storageDir.path;
    }

    final dbFile = File(normalizedPath);
    if (await dbFile.exists() &&
        normalizedPath.endsWith(MainConstants.dbExtension)) {
      return p.dirname(dbFile.path);
    }

    throw AppError.mainDatabase(
      code: MainDatabaseErrorCode.recordNotFound,
      message: 'Директория хранилища или файл БД не найдены',
      data: {'path': normalizedPath},
      timestamp: DateTime.now(),
    );
  }

  Future<String?> findDatabaseFile(String storagePath) async {
    try {
      final dir = Directory(storagePath);
      final files = await dir.list().toList();

      for (final file in files) {
        if (file is File && file.path.endsWith(MainConstants.dbExtension)) {
          return file.path;
        }
      }

      return null;
    } catch (error, stackTrace) {
      logError(
        'Failed to find database file',
        error: error,
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return null;
    }
  }
}
