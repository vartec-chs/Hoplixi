import 'dart:convert';
import 'dart:io';

import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/db_core/old/models/store_manifest.dart';
import 'package:path/path.dart' as p;

typedef StoreManifestEntry = ({String storagePath, StoreManifest manifest});

/// Файловый сервис для чтения и записи [StoreManifest].
class StoreManifestService {
  static const String manifestFileName = 'store_manifest.json';

  const StoreManifestService._();

  /// Путь к файлу манифеста для директории хранилища.
  static String manifestFilePath(String storageDir) =>
      p.join(storageDir, manifestFileName);

  /// Записать манифест на диск в директорию [storageDir].
  static Future<void> writeTo(String storageDir, StoreManifest manifest) async {
    final file = File(manifestFilePath(storageDir));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );
  }

  /// Прочитать манифест из директории [storageDir].
  ///
  /// Возвращает `null`, если файл отсутствует.
  static Future<StoreManifest?> readFrom(String storageDir) async {
    final file = File(manifestFilePath(storageDir));
    if (!await file.exists()) {
      return null;
    }

    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return StoreManifest.fromJson(json);
  }

  /// Прочитать все валидные манифесты из директории хранилищ [storagesPath].
  static Future<List<StoreManifestEntry>> readAllFromStorages(
    String storagesPath, {
    Set<String> excludedPaths = const {},
  }) async {
    final storagesDir = Directory(storagesPath);
    if (!await storagesDir.exists()) {
      return [];
    }

    final normalizedExcludedPaths = excludedPaths.map(p.normalize).toSet();
    final manifests = <StoreManifestEntry>[];

    await for (final entity in storagesDir.list(
      recursive: false,
      followLinks: false,
    )) {
      if (entity is! Directory) {
        continue;
      }

      final storagePath = p.normalize(entity.path);
      if (normalizedExcludedPaths.contains(storagePath)) {
        continue;
      }

      try {
        final manifest = await readFrom(entity.path);
        if (manifest == null) {
          continue;
        }

        manifests.add((storagePath: entity.path, manifest: manifest));
      } catch (error) {
        logWarning(
          'Failed to read store manifest from ${entity.path}: $error',
          tag: 'StoreManifestService',
        );
      }
    }

    return manifests;
  }

  /// Найти самое свежее хранилище с указанным [storeId].
  static Future<StoreManifestEntry?> findLatestByStoreId(
    String storagesPath,
    String storeId, {
    Set<String> excludedPaths = const {},
  }) async {
    final manifests = await readAllFromStorages(
      storagesPath,
      excludedPaths: excludedPaths,
    );

    StoreManifestEntry? latestEntry;
    for (final entry in manifests) {
      if (entry.manifest.storeId != storeId) {
        continue;
      }

      if (latestEntry == null ||
          entry.manifest.lastModified > latestEntry.manifest.lastModified) {
        latestEntry = entry;
      }
    }

    return latestEntry;
  }

  /// Удалить файл манифеста из директории [storageDir].
  static Future<void> deleteFrom(String storageDir) async {
    final file = File(manifestFilePath(storageDir));
    if (await file.exists()) {
      await file.delete();
    }
  }
}

extension StoreManifestPersistence on StoreManifest {
  /// Сохранить манифест в директории [storageDir].
  Future<void> writeTo(String storageDir) =>
      StoreManifestService.writeTo(storageDir, this);
}
