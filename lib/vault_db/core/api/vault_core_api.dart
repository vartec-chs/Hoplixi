import 'package:hoplixi/vault_db/core/api/documents/vault_documents_api.dart';
import 'package:hoplixi/vault_db/core/api/entities/vault_entities_api.dart';
import 'package:hoplixi/vault_db/core/api/history/vault_history_api.dart';
import 'package:hoplixi/vault_db/core/api/items/vault_items_api.dart';
import 'package:hoplixi/vault_db/core/api/relations/vault_relations_api.dart';
import 'package:hoplixi/vault_db/core/api/store/vault_store_api.dart';
import 'package:hoplixi/vault_db/core/api/system/vault_system_api.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';
import 'package:hoplixi/vault_db/core/services/document_versions/document_version_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/vault_card_filter_service.dart';
import 'package:hoplixi/vault_db/core/services/history/vault_history_service_assembly.dart';
import 'package:hoplixi/vault_db/core/services/relations/vault_item_relations_service.dart';
import 'package:hoplixi/vault_db/core/services/system/store_meta_service.dart';
import 'package:hoplixi/vault_db/core/services/vault_entity_services.dart';
import 'package:hoplixi/vault_db/core/services/vault_item_mutation_service.dart';
import 'package:hoplixi/vault_db/core/services/vault_items_state_service.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

/// NOT STABLE!
///
/// Root public API facade for `lib/vault_db/core`.
class VaultCoreApi {
  VaultCoreApi({required VaultRepositories repositories})
    : _repositories = repositories;

  factory VaultCoreApi.fromDb(VaultDB db) {
    return VaultCoreApi(repositories: VaultRepositories(db));
  }

  final VaultRepositories _repositories;

  VaultDB get db => _repositories.db;

  late final VaultHistoryServiceAssembly _historyAssembly =
      VaultHistoryServiceAssembly(db: db, repos: _repositories);

  late final VaultItemsStateService _itemsStateService = VaultItemsStateService(
    db: db,
    viewResolver: _historyAssembly.viewResolver,
    historyService: _historyAssembly.historyService,
  );

  late final VaultEntityServices _entityServices = VaultEntityServices(
    db: db,
    repositories: _repositories,
    historyService: _historyAssembly.historyService,
    vaultItemsStateService: _itemsStateService,
  );

  late final VaultItemRelationsService _relationsService =
      VaultItemRelationsService(db);

  late final VaultItemMutationService _itemMutationService =
      VaultItemMutationService(
        db: db,
        viewResolver: _historyAssembly.viewResolver,
        relationsService: _relationsService,
        historyService: _historyAssembly.historyService,
      );

  late final VaultSystemApi system = VaultSystemApi(
    repositories: _repositories,
  );
  late final VaultItemsApi items = VaultItemsApi(
    cardFilters: VaultCardFilterService(db),
  );
  late final VaultEntitiesApi entities = VaultEntitiesApi(
    services: _entityServices,
    repositories: _repositories,
  );
  late final VaultHistoryApi history = VaultHistoryApi(
    assembly: _historyAssembly,
  );
  late final VaultDocumentsApi documents = VaultDocumentsApi(
    versionService: DocumentVersionService(db),
  );
  late final VaultRelationsApi relations = VaultRelationsApi(
    relationsService: _relationsService,
    mutationService: _itemMutationService,
  );
  late final VaultStoreApi store = VaultStoreApi(
    metaService: StoreMetaService(db: db, repository: _repositories.storeMeta),
    settingsRepository: _repositories.storeSettings,
  );
}
