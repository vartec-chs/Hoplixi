import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/core/api/api.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';

final vaultApiProvider = FutureProvider<VaultCoreApi>((ref) async {
  final repositories = await ref.watch(vaultRepositories.future);
  return VaultCoreApi(repositories: repositories);
});

final vaultSystemApiProvider = FutureProvider<VaultSystemApi>((ref) async {
  final api = await ref.watch(vaultApiProvider.future);
  return api.system;
});

final vaultItemsApiProvider = FutureProvider<VaultItemsApi>((ref) async {
  final api = await ref.watch(vaultApiProvider.future);
  return api.items;
});

final vaultEntitiesApiProvider = FutureProvider<VaultEntitiesApi>((ref) async {
  final api = await ref.watch(vaultApiProvider.future);
  return api.entities;
});

final vaultHistoryApiProvider = FutureProvider<VaultHistoryApi>((ref) async {
  final api = await ref.watch(vaultApiProvider.future);
  return api.history;
});

final vaultDocumentsApiProvider = FutureProvider<VaultDocumentsApi>((
  ref,
) async {
  final api = await ref.watch(vaultApiProvider.future);
  return api.documents;
});

final vaultRelationsApiProvider = FutureProvider<VaultRelationsApi>((
  ref,
) async {
  final api = await ref.watch(vaultApiProvider.future);
  return api.relations;
});

final vaultStoreApiProvider = FutureProvider<VaultStoreApi>((ref) async {
  final api = await ref.watch(vaultApiProvider.future);
  return api.store;
});

final vaultCategoriesApiProvider = FutureProvider<CategoriesApi>((ref) async {
  final system = await ref.watch(vaultSystemApiProvider.future);
  return system.categories;
});

final vaultTagsApiProvider = FutureProvider<TagsApi>((ref) async {
  final system = await ref.watch(vaultSystemApiProvider.future);
  return system.tags;
});

final vaultIconsApiProvider = FutureProvider<IconsApi>((ref) async {
  final system = await ref.watch(vaultSystemApiProvider.future);
  return system.icons;
});
