import 'dart:convert';
import 'dart:io';

import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:path/path.dart' as p;

/// Сервис резервного копирования хранилища MainStore.
class MainStoreBackupService {
  Future<({String backupPath, DateTime createdAt})> createBackup({
    required String storeDirPath,
    required String storeName,
    required bool includeDatabase,
    required bool includeEncryptedFiles,
    required bool periodic,
    String? attachmentsPath,
    String? outputDirPath,
    int maxBackupsPerStore = 10,
  }) async {
    final backupRootPath = outputDirPath ?? await AppPaths.backupsPath;
    final backupRootDir = Directory(backupRootPath);
    if (!await backupRootDir.exists()) {
      await backupRootDir.create(recursive: true);
    }

    final retentionLimit = maxBackupsPerStore <= 0 ? 1 : maxBackupsPerStore;
    final now = DateTime.now();
    final timestamp = now
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final normalizedStoreName = storeName.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );

    final backupDir = Directory(
      p.join(backupRootPath, '${normalizedStoreName}_backup_$timestamp'),
    );
    await backupDir.create(recursive: true);

    if (includeDatabase) {
      final dbFilePath = await _findDatabaseFileInStoreDir(storeDirPath);
      if (dbFilePath == null) {
        throw Exception('Database file not found for backup');
      }

      final dbFile = File(dbFilePath);
      await dbFile.copy(p.join(backupDir.path, p.basename(dbFile.path)));
    }

    if (includeEncryptedFiles) {
      if (attachmentsPath == null || attachmentsPath.isEmpty) {
        throw Exception('Encrypted attachments path not found for backup');
      }

      await _copyDirectoryRecursive(
        source: Directory(attachmentsPath),
        destination: Directory(p.join(backupDir.path, 'attachments')),
      );
    }

    final manifestFile = File(p.join(backupDir.path, 'backup_manifest.json'));
    await manifestFile.writeAsString(
      jsonEncode({
        'createdAt': now.toIso8601String(),
        'storeName': storeName,
        'storePath': storeDirPath,
        'includeDatabase': includeDatabase,
        'includeEncryptedFiles': includeEncryptedFiles,
        'periodic': periodic,
      }),
    );

    await _enforceBackupRetention(
      backupRootPath: backupRootPath,
      storeName: normalizedStoreName,
      maxBackupsPerStore: retentionLimit,
    );

    return (backupPath: backupDir.path, createdAt: now);
  }

  Future<String?> _findDatabaseFileInStoreDir(String storeDirPath) async {
    final storeDir = Directory(storeDirPath);
    if (!await storeDir.exists()) {
      return null;
    }

    await for (final entity in storeDir.list(recursive: false)) {
      if (entity is File && entity.path.endsWith(MainConstants.dbExtension)) {
        return entity.path;
      }
    }

    return null;
  }

  Future<void> _copyDirectoryRecursive({
    required Directory source,
    required Directory destination,
  }) async {
    if (!await source.exists()) return;
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    await for (final entity in source.list(recursive: false)) {
      final name = p.basename(entity.path);
      final targetPath = p.join(destination.path, name);

      if (entity is File) {
        await entity.copy(targetPath);
      } else if (entity is Directory) {
        await _copyDirectoryRecursive(
          source: entity,
          destination: Directory(targetPath),
        );
      }
    }
  }

  Future<void> _enforceBackupRetention({
    required String backupRootPath,
    required String storeName,
    required int maxBackupsPerStore,
  }) async {
    if (maxBackupsPerStore <= 0) return;

    final rootDir = Directory(backupRootPath);
    if (!await rootDir.exists()) return;

    final prefix = '${storeName}_backup_';
    final backups = <Directory>[];

    await for (final entity in rootDir.list(recursive: false)) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (name.startsWith(prefix)) {
        backups.add(entity);
      }
    }

    if (backups.length <= maxBackupsPerStore) return;

    backups.sort((a, b) {
      final aName = p.basename(a.path);
      final bName = p.basename(b.path);
      return aName.compareTo(bName);
    });

    final toDeleteCount = backups.length - maxBackupsPerStore;
    for (var index = 0; index < toDeleteCount; index++) {
      await backups[index].delete(recursive: true);
    }
  }
}
