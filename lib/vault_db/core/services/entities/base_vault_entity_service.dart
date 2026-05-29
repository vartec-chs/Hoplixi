import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';
import 'package:hoplixi/vault_db/core/services/history/facades/vault_history_service.dart';
import 'package:hoplixi/vault_db/core/services/vault_items_state_service.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

/// Common dependencies for all vault entity services.
class VaultEntityServiceDeps {
  const VaultEntityServiceDeps({
    required this.db,
    required this.repositories,
    required this.historyService,
    required this.vaultItemsStateService,
  });

  final VaultDB db;
  final VaultRepositories repositories;
  final VaultHistoryService historyService;
  final VaultItemsStateService vaultItemsStateService;
}

/// Base generic class for all vault entity services.
abstract class BaseVaultEntityService<TRepository> {
  const BaseVaultEntityService({required this.deps, required this.repository});

  final VaultEntityServiceDeps deps;
  final TRepository repository;

  VaultDB get db => deps.db;
  VaultRepositories get repositories => deps.repositories;
  VaultHistoryService get historyService => deps.historyService;
  VaultItemsStateService get vaultItemsStateService =>
      deps.vaultItemsStateService;
}
