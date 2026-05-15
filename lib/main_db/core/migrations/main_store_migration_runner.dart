import 'package:drift/drift.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/core/migrations/main_store_migration_types.dart';
import 'package:hoplixi/main_db/core/migrations/versions/migration_v2.dart';
import 'package:hoplixi/main_db/core/migrations/versions/migration_v3.dart';
import 'package:hoplixi/main_db/core/migrations/versions/migration_v5.dart';
import 'package:hoplixi/main_db/core/migrations/versions/migration_v6.dart';

final Map<int, MainStoreMigration> _mainStoreMigrationsByVersion = {
  2: migrateTo,
  3: migrateToV3,
  5: migrateToV5,
  6: migrateToV6,
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
