import 'dart:io';

import 'package:hoplixi/main_store/dao/index.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/services/file_storage_service.dart';
import 'package:hoplixi/main_store/services/main_store_storage_service.dart';
import 'package:hoplixi/main_store/services/store_cleanup_service.dart';

/// Сервис файлового обслуживания и стартовой чистки MainStore.
class MainStoreMaintenanceService {
  final MainStoreStorageService _storageService;

  MainStoreMaintenanceService({MainStoreStorageService? storageService})
    : _storageService = storageService ?? MainStoreStorageService();

  String? getAttachmentsPath(String? storePath) {
    if (storePath == null || storePath.isEmpty) {
      return null;
    }

    return _storageService.getAttachmentsPath(storePath);
  }

  String? getDecryptedAttachmentsPath(String? storePath) {
    if (storePath == null || storePath.isEmpty) {
      return null;
    }

    return _storageService.getDecryptedAttachmentsPath(storePath);
  }

  Future<String> createSubfolder({
    required String storePath,
    required String folderName,
  }) {
    return _storageService.createSubfolder(
      storePath: storePath,
      folderName: folderName,
    );
  }

  Future<bool> storageDirectoryExists(String path) {
    return _storageService.storageDirectoryExists(path);
  }

  Future<void> deleteStorageDirectory(String path) {
    return _storageService.deleteStorageDirectory(path);
  }

  Future<void> cleanupDecryptedAttachmentsDir(String? dirPath) async {
    if (dirPath == null || dirPath.isEmpty) return;

    final directory = Directory(dirPath);
    if (!await directory.exists()) return;

    await for (final entity in directory.list(recursive: false)) {
      await entity.delete(recursive: true);
    }
  }

  Future<void> runStartupCleanup({
    required MainStore store,
    required String storePath,
  }) async {
    final attachmentsPath = _storageService.getAttachmentsPath(storePath);
    final decryptedPath = _storageService.getDecryptedAttachmentsPath(
      storePath,
    );

    final fileStorageService = FileStorageService(
      store,
      attachmentsPath,
      decryptedPath,
    );
    final settingsDao = StoreSettingsDao(store);
    final cleanupService = StoreCleanupService(settingsDao, fileStorageService);

    await cleanupService.performFullCleanup(ignoreInterval: false);
  }
}
