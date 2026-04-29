import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/main_db/providers/dao_providers.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';
import 'package:hoplixi/main_db/services/main_store_storage_service.dart';
import 'package:hoplixi/main_db/services/other/document_storage_service.dart';
import 'package:hoplixi/main_db/services/other/file_storage_service.dart';
import 'package:hoplixi/main_db/services/store_cleanup_service.dart';

final fileStorageServiceProvider = FutureProvider<FileStorageService>((
  ref,
) async {
  final manager = await ref.watch(mainStoreManagerProvider.future);
  final store = manager.currentStore;
  final storePath = manager.currentStorePath;
  if (store == null || storePath == null || storePath.isEmpty) {
    throw AppError.mainDatabase(
      code: MainDatabaseErrorCode.notInitialized,
      message: 'Хранилище не открыто',
      timestamp: DateTime.now(),
    );
  }

  const storageService = MainStoreFileService();
  return FileStorageService(
    store,
    storageService.getAttachmentsPath(storePath),
    storageService.getDecryptedAttachmentsPath(storePath),
  );
});

final documentStorageServiceProvider = FutureProvider<DocumentStorageService>((
  ref,
) async {
  final manager = await ref.watch(mainStoreManagerProvider.future);
  final store = manager.currentStore;
  if (store == null) {
    throw AppError.mainDatabase(
      code: MainDatabaseErrorCode.notInitialized,
      message: 'Хранилище не открыто',
      timestamp: DateTime.now(),
    );
  }

  final fileStorageService = await ref.watch(fileStorageServiceProvider.future);
  return DocumentStorageService(store, fileStorageService);
});

final storeCleanupServiceProvider = FutureProvider<StoreCleanupService>((
  ref,
) async {
  final settingsDao = await ref.watch(storeSettingsDaoProvider.future);
  final fileStorageService = await ref.watch(fileStorageServiceProvider.future);

  return StoreCleanupService(settingsDao, fileStorageService);
});
