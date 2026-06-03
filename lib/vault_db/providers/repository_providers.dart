import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';
import 'package:hoplixi/vault_db/providers/api_providers.dart';

final vaultRepositories = FutureProvider<VaultRepositories>((ref) async {
  final api = await ref.watch(vaultApiProvider.future);
  return api.repositories;
});
