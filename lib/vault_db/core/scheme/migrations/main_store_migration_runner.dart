import 'package:drift/drift.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/vault_db/core/scheme/migrations/main_store_migration_types.dart';

final Map<int, VaultDBMigration> _vaultDBMigrationsByVersion = {};

/// Runs known, versioned migrations in ascending order.
///
/// Returns the last applied schema version. If no migration is registered for a
/// next version, execution stops so the caller can decide on fallback strategy.
Future<int> runVaultDBKnownMigrations({
  required Migrator migrator,
  required int from,
  required int to,
  required VaultDBMigrationRuntime runtime,
  required String logTag,
}) async {
  var currentVersion = from;

  while (currentVersion < to) {
    final nextVersion = currentVersion + 1;
    final migration = _vaultDBMigrationsByVersion[nextVersion];

    if (migration == null) {
      logWarning(
        'No explicit migration script for schema version $nextVersion',
        tag: logTag,
      );
      break;
    }

    logInfo(
      'Running migration script for schema version $nextVersion',
      tag: logTag,
    );

    await migration(migrator, runtime);
    currentVersion = nextVersion;

    logInfo(
      'Completed migration script for schema version $nextVersion',
      tag: logTag,
    );
  }

  return currentVersion;
}
