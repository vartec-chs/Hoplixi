import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/core/services/document_versions/document_version_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/vault_card_filter_service.dart';
import 'package:hoplixi/vault_db/core/services/history/vault_history_service_assembly.dart';
import 'package:hoplixi/vault_db/core/services/relations/vault_item_relations_service.dart';
import 'package:hoplixi/vault_db/core/services/system/store_meta_service.dart';
import 'package:hoplixi/vault_db/core/services/vault_entity_services.dart';
import 'package:hoplixi/vault_db/core/services/vault_items_state_service.dart';
import 'package:hoplixi/vault_db/services/archive_service/archive_service.dart';
import 'package:hoplixi/vault_db/services/db_history_services/db_history_services.dart';
import 'package:hoplixi/vault_db/services/main_store_storage_service.dart';
import 'package:hoplixi/vault_db/services/other/document_storage_service.dart';
import 'package:hoplixi/vault_db/services/other/file_storage_service.dart';

import 'api_providers.dart';
import 'session_providers.dart';
import 'vault_ui_state_provider.dart';

/// Провайдер для сервиса архивации хранилищ
final archiveServiceProvider = Provider<ArchiveService>((ref) {
  return ArchiveService();
});

final dbHistoryProvider = FutureProvider<DatabaseHistoryService>((ref) async {
  final databaseHistoryService = DatabaseHistoryService();
  await databaseHistoryService.initialize();
  return databaseHistoryService;
});

final storeMetaServiceProvider = FutureProvider<StoreMetaService>((ref) async {
  final db = ref.watch(requiredVaultDBProvider);
  final repos = await ref.watch(vaultRepositories.future);
  return StoreMetaService(db: db, repository: repos.storeMeta);
});

final documentVersionServiceProvider = FutureProvider<DocumentVersionService>((
  ref,
) async {
  final db = ref.watch(requiredVaultDBProvider);
  return DocumentVersionService(db);
});

final vaultCardFilterServiceProvider = FutureProvider<VaultCardFilterService>((
  ref,
) async {
  final db = ref.watch(requiredVaultDBProvider);
  return VaultCardFilterService(db);
});

final vaultItemRelationsServiceProvider =
    FutureProvider<VaultItemRelationsService>((ref) async {
      final db = ref.watch(requiredVaultDBProvider);
      return VaultItemRelationsService(db);
    });

final vaultHistoryServiceAssemblyProvider =
    FutureProvider<VaultHistoryServiceAssembly>((ref) async {
      final db = ref.watch(requiredVaultDBProvider);
      final repos = await ref.watch(vaultRepositories.future);
      return VaultHistoryServiceAssembly(db: db, repos: repos);
    });

final vaultItemsStateServiceProvider = FutureProvider<VaultItemsStateService>((
  ref,
) async {
  final db = ref.watch(requiredVaultDBProvider);
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
  final db = ref.watch(requiredVaultDBProvider);
  final repositories = await ref.watch(vaultRepositories.future);

  final vaultHistoryServiceAssembly = await ref.watch(
    vaultHistoryServiceAssemblyProvider.future,
  );
  final vaultItemsStateService = await ref.watch(
    vaultItemsStateServiceProvider.future,
  );
  return VaultEntityServices(
    db: db,
    repositories: repositories,
    historyService: vaultHistoryServiceAssembly.historyService,
    vaultItemsStateService: vaultItemsStateService,
  );
});

final fileStorageServiceProvider = FutureProvider<FileStorageService>((
  ref,
) async {
  final db = ref.watch(requiredVaultDBProvider);
  final state = await ref.watch(vaultDBManagerStateProvider.future);

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
  final db = ref.watch(requiredVaultDBProvider);
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
