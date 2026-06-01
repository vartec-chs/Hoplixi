import 'package:hoplixi/vault_db/core/api/items/vault_items_api.dart';
import 'package:hoplixi/vault_db/core/api/system/vault_system_api.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';
import 'package:hoplixi/vault_db/core/services/entities/vault_card_filter_service.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

/// Root public API facade for `lib/vault_db/core`.
class VaultCoreApi {
  VaultCoreApi({required VaultRepositories repositories})
    : system = VaultSystemApi(repositories: repositories),
      items = VaultItemsApi(
        cardFilters: VaultCardFilterService(repositories.db),
      );

  factory VaultCoreApi.fromDb(VaultDB db) {
    return VaultCoreApi(repositories: VaultRepositories(db));
  }

  final VaultSystemApi system;
  final VaultItemsApi items;
}
