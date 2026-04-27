import 'dart:io';

import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:path/path.dart' as p;

class MainStoreFileService {
  static const String _logTag = 'MainStoreFileService';
  static const Set<String> _reservedWindowsNames = {
    'con',
    'prn',
    'aux',
    'nul',
    'com1',
    'com2',
    'com3',
    'com4',
    'com5',
    'com6',
    'com7',
    'com8',
    'com9',
    'lpt1',
    'lpt2',
    'lpt3',
    'lpt4',
    'lpt5',
    'lpt6',
    'lpt7',
    'lpt8',
    'lpt9',
  };

  static const String attachmentsFolder = 'attachments';
  static const String decryptedAttachmentsFolder = 'attachments_decrypted';

  const MainStoreFileService();

  String getAttachmentsPath(String storePath) {
    return p.join(storePath, attachmentsFolder);
  }

  String getDecryptedAttachmentsPath(String storePath) {
    return p.join(storePath, decryptedAttachmentsFolder);
  }

  String getDatabaseFilePath(String storePath, String normalizedName) {
    return p.join(storePath, '$normalizedName${MainConstants.dbExtension}');
  }

  Future<({String normalizedName, Directory storageDir})>
  prepareNewStorageDirectory({
    required String baseStoragePath,
    required String storeName,
  }) async {
    final normalizedName = normalizeStorageName(storeName);
    final normalizedBasePath = baseStoragePath.trim();
    if (normalizedBasePath.isEmpty) {
      throw AppError.validation(
        code: ValidationErrorCode.invalidInput,
        message: 'Базовый путь хранилищ не указан',
        timestamp: DateTime.now(),
      );
    }

    final storageDir = Directory(p.join(normalizedBasePath, normalizedName));
    if (await storageDir.exists()) {
      final existingDbFile = await findDatabaseFile(storageDir.path);
      if (existingDbFile != null) {
        throw AppError.validation(
          code: ValidationErrorCode.alreadyExists,
          message: 'Хранилище с таким именем уже существует',
          data: {'path': storageDir.path},
          timestamp: DateTime.now(),
        );
      }

      await _moveDirectoryWithoutDatabase(
        baseStoragePath: normalizedBasePath,
        normalizedStoreName: normalizedName,
        storageDir: storageDir,
      );
    }

    await storageDir.create(recursive: true);
    await Directory(getAttachmentsPath(storageDir.path)).create(
      recursive: true,
    );

    return (normalizedName: normalizedName, storageDir: storageDir);
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

    final directory = Directory(
      p.join(normalizedStorePath, normalizedFolderName),
    );
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

  String normalizeStorageName(String name) {
    var normalized = name.trim();
    normalized = normalized.replaceAll(RegExp(r'\s+'), '_');
    normalized = normalized.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
    normalized = normalized.replaceAll(RegExp(r'^\.+|\.+$'), '');

    if (normalized.isEmpty ||
        normalized == '.' ||
        normalized == '..' ||
        _reservedWindowsNames.contains(normalized.toLowerCase())) {
      throw AppError.validation(
        code: ValidationErrorCode.invalidInput,
        message: 'Имя хранилища содержит только недопустимые символы',
        data: {'originalName': name},
        timestamp: DateTime.now(),
      );
    }

    return normalized;
  }

  Future<void> _moveDirectoryWithoutDatabase({
    required String baseStoragePath,
    required String normalizedStoreName,
    required Directory storageDir,
  }) async {
    final backupName = 'do_not_contain_db_file_$normalizedStoreName';
    var backupPath = p.join(baseStoragePath, backupName);

    var backupDir = Directory(backupPath);
    var counter = 1;
    while (await backupDir.exists()) {
      backupPath = p.join(baseStoragePath, '${backupName}_$counter');
      backupDir = Directory(backupPath);
      counter++;
    }

    await storageDir.rename(backupPath);
    logInfo(
      'Renamed directory without db file to: $backupPath',
      tag: _logTag,
    );
  }
}
