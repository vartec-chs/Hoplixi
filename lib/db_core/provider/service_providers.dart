import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/db_core/models/db_errors.dart';
import 'package:hoplixi/db_core/provider/dao_providers.dart';
import 'package:hoplixi/db_core/provider/main_store_provider.dart';
import 'package:hoplixi/db_core/services/document_storage_service.dart';
import 'package:hoplixi/db_core/services/file_storage_service.dart';
import 'package:hoplixi/db_core/services/main_store_storage_service.dart';
import 'package:hoplixi/db_core/services/store_cleanup_service.dart';

/// Провайдер для FileStorageService
final fileStorageServiceProvider = FutureProvider<FileStorageService>((
  ref,
) async {
  final manager = await ref.watch(mainStoreManagerProvider.future);
  final store = manager?.currentStore;
  if (store == null || manager == null) {
    throw DatabaseError.notInitialized(timestamp: DateTime.now());
  }

  final storePath = manager.currentStorePath;
  if (storePath == null || storePath.isEmpty) {
    throw DatabaseError.notInitialized(timestamp: DateTime.now());
  }

  final storageService = MainStoreStorageService();
  final attachmentsPath = storageService.getAttachmentsPath(storePath);
  final decryptedAttachmentsPath = storageService.getDecryptedAttachmentsPath(
    storePath,
  );

  return FileStorageService(store, attachmentsPath, decryptedAttachmentsPath);
});

/// Провайдер для DocumentStorageService
final documentStorageServiceProvider = FutureProvider<DocumentStorageService>((
  ref,
) async {
  final manager = await ref.watch(mainStoreManagerProvider.future);
  final store = manager?.currentStore;
  if (store == null || manager == null) {
    throw DatabaseError.notInitialized(timestamp: DateTime.now());
  }

  final fileStorageService = await ref.watch(fileStorageServiceProvider.future);

  return DocumentStorageService(store, fileStorageService);
});

/// Провайдер для StoreCleanupService
final storeCleanupServiceProvider = FutureProvider<StoreCleanupService>((
  ref,
) async {
  final settingsDao = await ref.watch(storeSettingsDaoProvider.future);
  final fileStorageService = await ref.watch(fileStorageServiceProvider.future);

  return StoreCleanupService(settingsDao, fileStorageService);
});
