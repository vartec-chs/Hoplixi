import 'package:drift/drift.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/core/migrations/main_store_migration_types.dart';

Future<void> migrateToV6(
  Migrator migrator,
  MainStoreMigrationRuntime runtime,
) async {
  const logTag = 'MainStoreMigration';
  logInfo('Running migration to schema version 6', tag: logTag);

  await runtime.customStatement(
    "ALTER TABLE contact_items ADD COLUMN first_name TEXT NOT NULL DEFAULT '';",
  );
  await runtime.customStatement(
    'ALTER TABLE contact_items ADD COLUMN middle_name TEXT NULL;',
  );
  await runtime.customStatement(
    'ALTER TABLE contact_items ADD COLUMN last_name TEXT NULL;',
  );
  await runtime.customStatement(
    "ALTER TABLE contact_history ADD COLUMN first_name TEXT NOT NULL DEFAULT '';",
  );
  await runtime.customStatement(
    'ALTER TABLE contact_history ADD COLUMN middle_name TEXT NULL;',
  );
  await runtime.customStatement(
    'ALTER TABLE contact_history ADD COLUMN last_name TEXT NULL;',
  );

  await runtime.customStatement('''
    UPDATE contact_items
    SET first_name = COALESCE(
      NULLIF(trim(first_name), ''),
      (
        SELECT name
        FROM vault_items
        WHERE vault_items.id = contact_items.item_id
      )
    )
    WHERE COALESCE(length(trim(first_name)), 0) = 0;
  ''');

  await runtime.customStatement('''
    UPDATE contact_history
    SET first_name = COALESCE(NULLIF(trim(first_name), ''), (
      SELECT name
      FROM vault_item_history
      WHERE vault_item_history.id = contact_history.history_id
    ))
    WHERE COALESCE(length(trim(first_name)), 0) = 0;
  ''');

  logInfo('Schema version 6 migration completed', tag: logTag);
}