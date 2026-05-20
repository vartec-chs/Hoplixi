import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/vault_db/providers/main_store_manager_provider.dart';
import 'package:hoplixi/vault_db/services/main_store_storage_service.dart';
import 'package:hoplixi/vault_db/services/other/document_storage_service.dart';
import 'package:hoplixi/vault_db/services/other/file_storage_service.dart';
import 'package:hoplixi/vault_db/usecases/perform_store_cleanup.dart';

final fileStorageServiceProvider = FutureProvider<FileStorageService>((
  ref,
) async {
  final state = await ref.watch(mainStoreManagerStateProvider.future);
  final manager = ref.read(mainStoreManagerStateProvider.notifier);
  final store = manager.currentStore;
  final storePath = state.path;
  if (store == null || storePath == null || storePath.isEmpty) {
    throw AppError.mainDatabase(
      code: MainDatabaseErrorCode.notInitialized,
      message: 'Хранилище не открыто',
      timestamp: DateTime.now(),
    );
  }

  const storageService = VaultDBFileService();
  return FileStorageService(
    store,
    storageService.getAttachmentsPath(storePath),
    storageService.getDecryptedAttachmentsPath(storePath),
  );
});

final documentStorageServiceProvider = FutureProvider<DocumentStorageService>((
  ref,
) async {
  await ref.watch(mainStoreManagerStateProvider.future);
  final manager = ref.read(mainStoreManagerStateProvider.notifier);
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

final performStoreCleanupProvider =
    FutureProvider.autoDispose<PerformStoreCleanup>((ref) async {
      final fileStorageService = await ref.watch(
        fileStorageServiceProvider.future,
      );

      await ref.watch(mainStoreManagerStateProvider.future);
      final manager = ref.read(mainStoreManagerStateProvider.notifier);

      return PerformStoreCleanup(
        manager.currentDatabase.storeSettingsDao,
        fileStorageService,
      );
    });
