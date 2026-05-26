import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';

import 'main_store_manager_provider.dart';

final vaultRepositories = FutureProvider<VaultRepositories>((ref) async {
  final db = await ref.watch(vaultDBProvider.future);
  return VaultRepositories(db);
});

