import 'package:drift/drift.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/core/migrations/main_store_migration_types.dart';

Future<void> migrateToV3(
  Migrator migrator,
  MainStoreMigrationRuntime runtime,
) async {
  const logTag = 'MainStoreMigration';
  logInfo('Running migration to schema version 3', tag: logTag);

  await runtime.reinstallHistoryTriggers();

  logInfo('Schema version 3 migration completed', tag: logTag);
}
