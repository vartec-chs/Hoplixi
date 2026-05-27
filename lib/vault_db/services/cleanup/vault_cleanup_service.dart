import 'package:hoplixi/vault_db/core/vault_db.dart';

class VaultCleanupService {
  final Future<void> Function(VaultDB db, String storePath)?
  _performStoreCleanup;

  const VaultCleanupService({
    Future<void> Function(VaultDB db, String storePath)? performStoreCleanup,
  }) : _performStoreCleanup = performStoreCleanup;

  Future<void> cleanup(VaultDB db, String storePath) async {
    final cleanupFn = _performStoreCleanup;
    if (cleanupFn != null) {
      await cleanupFn(db, storePath);
    }
  }
}
