import 'package:drift/drift.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/db_core/db/migrations/main_store_migration_types.dart';
import 'package:hoplixi/db_core/db/migrations/versions/migration_v2.dart';

final Map<int, MainStoreMigration> _mainStoreMigrationsByVersion = {
  2: migrateToV2,
};

/// Runs known, versioned migrations in ascending order.
///
/// Returns the last applied schema version. If no migration is registered for a
/// next version, execution stops so the caller can decide on fallback strategy.
Future<int> runMainStoreKnownMigrations({
  required Migrator migrator,
  required int from,
  required int to,
  required MainStoreMigrationRuntime runtime,
  required String logTag,
}) async {
  var currentVersion = from;

  while (currentVersion < to) {
    final nextVersion = currentVersion + 1;
    final migration = _mainStoreMigrationsByVersion[nextVersion];

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
