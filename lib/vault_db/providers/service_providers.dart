import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/core/services/document_versions/document_version_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/vault_card_filter_service.dart';
import 'package:hoplixi/vault_db/core/services/history/vault_history_service_assembly.dart';
import 'package:hoplixi/vault_db/core/services/relations/vault_item_relations_service.dart';
import 'package:hoplixi/vault_db/core/services/vault_entity_services.dart';
import 'package:hoplixi/vault_db/core/services/vault_items_state_service.dart';
import 'package:hoplixi/vault_db/providers/main_store_manager_provider.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';
import 'package:hoplixi/vault_db/services/main_store_storage_service.dart';
import 'package:hoplixi/vault_db/services/other/document_storage_service.dart';
import 'package:hoplixi/vault_db/services/other/file_storage_service.dart';
import 'package:hoplixi/vault_db/usecases/perform_store_cleanup.dart';

final documentVersionServiceProvider = FutureProvider<DocumentVersionService>((
  ref,
) async {
  final db = await ref.watch(vaultDBProvider.future);
  return DocumentVersionService(db);
});

final vaultCardFilterServiceProvider = FutureProvider<VaultCardFilterService>((
  ref,
) async {
  final db = await ref.watch(vaultDBProvider.future);
  return VaultCardFilterService(db);
});

final vaultItemRelationsServiceProvider =
    FutureProvider<VaultItemRelationsService>((ref) async {
      final db = await ref.watch(vaultDBProvider.future);
      return VaultItemRelationsService(db);
    });

final vaultHistoryServiceAssemblyProvider =
    FutureProvider<VaultHistoryServiceAssembly>((ref) async {
      final db = await ref.watch(vaultDBProvider.future);
      final repos = await ref.watch(vaultRepositories.future);
      return VaultHistoryServiceAssembly(db: db, repos: repos);
    });

final vaultItemsStateServiceProvider = FutureProvider<VaultItemsStateService>((
  ref,
) async {
  final db = await ref.watch(vaultDBProvider.future);
  final vaultHistoryServiceAssembly = await ref.watch(
    vaultHistoryServiceAssemblyProvider.future,
  );
  return VaultItemsStateService(
    db: db,
    viewResolver: vaultHistoryServiceAssembly.viewResolver,
    historyService: vaultHistoryServiceAssembly.historyService,
  );
});

final vaultEntityServices = FutureProvider<VaultEntityServices>((ref) async {
  final db = await ref.watch(vaultDBProvider.future);
  final repositories = await ref.watch(vaultRepositories.future);
  final relationsService = await ref.watch(
    vaultItemRelationsServiceProvider.future,
  );
  final vaultHistoryServiceAssembly = await ref.watch(
    vaultHistoryServiceAssemblyProvider.future,
  );
  final vaultItemsStateService = await ref.watch(
    vaultItemsStateServiceProvider.future,
  );
  return VaultEntityServices(
    db: db,
    repositories: repositories,
    relationsService: relationsService,
    historyService: vaultHistoryServiceAssembly.historyService,
    vaultItemsStateService: vaultItemsStateService,
  );
});

final fileStorageServiceProvider = FutureProvider<FileStorageService>((
  ref,
) async {
  final db = await ref.watch(vaultDBProvider.future);
  final state = await ref.watch(vaultDBStateProvider.future);

  if (state.path == null) {
    throw Exception('Vault path is null');
  }

  final entityServices = await ref.watch(vaultEntityServices.future);
  final repos = await ref.watch(vaultRepositories.future);

  const storageService = VaultDBFileService();
  return FileStorageService(
    db: db,
    attachmentsPath: storageService.getAttachmentsPath(state.path!),
    decryptedAttachmentsPath: storageService.getDecryptedAttachmentsPath(
      state.path!,
    ),
    fileService: entityServices.file,
    fileRepository: repos.file,
    fileMetadataRepository: repos.fileMetadata,
  );
});

final documentStorageServiceProvider = FutureProvider<DocumentStorageService>((
  ref,
) async {
  final db = await ref.watch(vaultDBProvider.future);
  final fileStorageService = await ref.watch(fileStorageServiceProvider.future);
  final entityServices = await ref.watch(vaultEntityServices.future);
  final documentVersionService = await ref.watch(
    documentVersionServiceProvider.future,
  );
  final relationsService = await ref.watch(
    vaultItemRelationsServiceProvider.future,
  );

  return DocumentStorageService(
    db: db,
    fileStorageService: fileStorageService,
    documentService: entityServices.document,
    documentVersionService: documentVersionService,
    relationsService: relationsService,
  );
});

final performStoreCleanupProvider =
    FutureProvider.autoDispose<PerformStoreCleanup>((ref) async {
      final fileStorageService = await ref.watch(
        fileStorageServiceProvider.future,
      );

      final db = await ref.watch(vaultDBProvider.future);

      return PerformStoreCleanup(
        settingsDao: db.storeSettingsDao,
        fileStorageService: fileStorageService,
      );
    });
