import 'dart:io';

import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/db_core/models/db_errors.dart';
import 'package:path/path.dart' as p;

/// Сервис файловой системы для хранилищ MainStore.
class MainStoreStorageService {
  static const String _logTag = 'MainStoreStorageService';
  static const String _dbExtension = MainConstants.dbExtension;
  static const String attachmentsFolder = 'attachments';
  static const String decryptedAttachmentsFolder = 'attachments_decrypted';

  Future<({String normalizedName, Directory storageDir})>
  prepareNewStorageDirectory({
    required String baseStoragePath,
    required String storeName,
  }) async {
    final normalizedName = normalizeStorageName(storeName);
    final storageDir = Directory(p.join(baseStoragePath, normalizedName));

    if (await storageDir.exists()) {
      final existingDbFile = await findDatabaseFile(storageDir.path);
      if (existingDbFile != null) {
        throw DatabaseError.validationError(
          message: 'Хранилище с таким именем уже существует',
          data: {'path': storageDir.path},
          timestamp: DateTime.now(),
        );
      }

      await _moveDirectoryWithoutDatabase(
        baseStoragePath: baseStoragePath,
        storeName: storeName,
        storageDir: storageDir,
      );
    }

    await storageDir.create(recursive: true);
    logInfo('Created storage directory: ${storageDir.path}', tag: _logTag);

    await Directory(
      getAttachmentsPath(storageDir.path),
    ).create(recursive: true);
    logInfo('Created attachments directory', tag: _logTag);

    return (normalizedName: normalizedName, storageDir: storageDir);
  }

  Future<String> resolveExistingStoragePath(String path) async {
    final storageDir = Directory(path);
    final dbFile = File(path);

    if (await storageDir.exists()) {
      return path;
    }

    if (await dbFile.exists() && path.endsWith(_dbExtension)) {
      return p.dirname(path);
    }

    throw DatabaseError.recordNotFound(
      message: 'Директория хранилища или файл БД не найдены',
      data: {'path': path},
      timestamp: DateTime.now(),
    );
  }

  String normalizeStorageName(String name) {
    var normalized = name.trim();
    normalized = normalized.replaceAll(RegExp(r'\s+'), '_');
    normalized = normalized.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');

    if (normalized.isEmpty) {
      throw DatabaseError.validationError(
        message: 'Имя хранилища содержит только недопустимые символы',
        data: {'originalName': name},
        timestamp: DateTime.now(),
      );
    }

    return normalized;
  }

  String getDatabaseFilePath(String storagePath, String storageName) {
    return p.join(storagePath, '$storageName$_dbExtension');
  }

  Future<String?> findDatabaseFile(String storagePath) async {
    try {
      final dir = Directory(storagePath);
      final files = await dir.list().toList();

      for (final file in files) {
        if (file is File && file.path.endsWith(_dbExtension)) {
          return file.path;
        }
      }

      return null;
    } catch (e) {
      logError('Failed to find database file: $e', tag: _logTag);
      return null;
    }
  }

  Future<String> createSubfolder({
    required String storePath,
    required String folderName,
  }) async {
    final normalizedName = normalizeStorageName(folderName);
    final subfolderPath = p.join(storePath, normalizedName);
    final subfolder = Directory(subfolderPath);

    if (await subfolder.exists()) {
      throw DatabaseError.validationError(
        message: 'Папка с таким именем уже существует',
        data: {'path': subfolderPath},
        timestamp: DateTime.now(),
      );
    }

    await subfolder.create(recursive: true);
    logInfo('Created subfolder: $normalizedName', tag: _logTag);

    return subfolderPath;
  }

  String getAttachmentsPath(String storePath) {
    return p.join(storePath, attachmentsFolder);
  }

  String getDecryptedAttachmentsPath(String storePath) {
    return p.join(storePath, decryptedAttachmentsFolder);
  }

  Future<bool> storageDirectoryExists(String path) async {
    return Directory(path).exists();
  }

  Future<void> deleteStorageDirectory(String path) async {
    await Directory(path).delete(recursive: true);
  }

  Future<void> _moveDirectoryWithoutDatabase({
    required String baseStoragePath,
    required String storeName,
    required Directory storageDir,
  }) async {
    final noSpacesName = storeName.replaceAll(RegExp(r'\s+'), '');
    final backupName = 'do_not_contain_db_file_$noSpacesName';
    var backupPath = p.join(baseStoragePath, backupName);

    var backupDir = Directory(backupPath);
    var counter = 1;
    while (await backupDir.exists()) {
      backupPath = p.join(baseStoragePath, '${backupName}_$counter');
      backupDir = Directory(backupPath);
      counter++;
    }

    await storageDir.rename(backupPath);
    logInfo('Renamed directory without db file to: $backupPath', tag: _logTag);
  }
}
