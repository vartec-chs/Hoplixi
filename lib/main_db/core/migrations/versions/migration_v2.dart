import 'package:drift/drift.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/core/migrations/main_store_migration_types.dart';

Future<void> migrateTo(
  Migrator migrator,
  MainStoreMigrationRuntime runtime,
) async {
  const logTag = 'MainStoreMigration';
  logInfo('Running migration to schema version 2', tag: logTag);

  await migrator.addColumn(
    runtime.categoriesTable,
    runtime.categoriesIconSource,
  );
  await migrator.addColumn(
    runtime.categoriesTable,
    runtime.categoriesIconValue,
  );
  await migrator.addColumn(
    runtime.vaultItemsTable,
    runtime.vaultItemsIconSource,
  );
  await migrator.addColumn(
    runtime.vaultItemsTable,
    runtime.vaultItemsIconValue,
  );
  await migrator.addColumn(
    runtime.vaultItemHistoryTable,
    runtime.vaultItemHistoryIconSource,
  );
  await migrator.addColumn(
    runtime.vaultItemHistoryTable,
    runtime.vaultItemHistoryIconValue,
  );

  await runtime.customStatement('''
    UPDATE categories
    SET icon_source = 'db',
        icon_value = icon_id
    WHERE icon_id IS NOT NULL
      AND TRIM(icon_id) != ''
      AND (icon_source IS NULL OR TRIM(icon_source) = '')
      AND (icon_value IS NULL OR TRIM(icon_value) = '')
    ''');

  await runtime.reinstallHistoryTriggers();

  logInfo('Schema version 2 migration completed', tag: logTag);
}
