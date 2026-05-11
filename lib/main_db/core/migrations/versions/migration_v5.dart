import 'package:drift/drift.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/core/migrations/main_store_migration_types.dart';

Future<void> migrateToV5(
  Migrator migrator,
  MainStoreMigrationRuntime runtime,
) async {
  const logTag = 'MainStoreMigration';
  logInfo('Running migration to schema version 5', tag: logTag);

  await runtime.customStatement('''
    CREATE TABLE IF NOT EXISTS file_metadata_history (
      id TEXT NOT NULL PRIMARY KEY,
      history_id TEXT NULL REFERENCES vault_item_history(id) ON DELETE CASCADE,
      metadata_id TEXT NULL,
      file_name TEXT NOT NULL,
      file_extension TEXT NULL,
      file_path TEXT NULL,
      mime_type TEXT NOT NULL,
      file_size INTEGER NOT NULL,
      sha256 TEXT NULL,
      snapshot_created_at INTEGER NOT NULL,
      CONSTRAINT chk_file_metadata_history_file_name_not_blank CHECK (
        length(trim(file_name)) > 0
      ),
      CONSTRAINT chk_file_metadata_history_file_extension_not_blank CHECK (
        file_extension IS NULL
        OR length(trim(file_extension)) > 0
      ),
      CONSTRAINT chk_file_metadata_history_file_path_not_blank CHECK (
        file_path IS NULL
        OR length(trim(file_path)) > 0
      ),
      CONSTRAINT chk_file_metadata_history_mime_type_not_blank CHECK (
        length(trim(mime_type)) > 0
      ),
      CONSTRAINT chk_file_metadata_history_file_size_non_negative CHECK (
        file_size >= 0
      ),
      CONSTRAINT chk_file_metadata_history_sha256_not_blank CHECK (
        sha256 IS NULL
        OR length(trim(sha256)) > 0
      ),
      CONSTRAINT chk_file_metadata_history_sha256_length CHECK (
        sha256 IS NULL
        OR length(sha256) = 64
      )
    );
  ''');

  await runtime.customStatement('''
    CREATE TABLE IF NOT EXISTS document_versions (
      id TEXT NOT NULL PRIMARY KEY,
      document_id TEXT NOT NULL REFERENCES vault_items(id) ON DELETE CASCADE,
      version_number INTEGER NOT NULL,
      document_type TEXT NULL,
      document_type_other TEXT NULL,
      aggregated_text TEXT NULL,
      aggregate_hash TEXT NULL,
      page_count INTEGER NOT NULL DEFAULT 0,
      is_current INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      modified_at INTEGER NOT NULL,
      UNIQUE(document_id, version_number),
      CONSTRAINT chk_document_versions_version_number_positive CHECK (
        version_number > 0
      ),
      CONSTRAINT chk_document_versions_document_type_other_required CHECK (
        document_type IS NULL
        OR document_type != 'other'
        OR (
          document_type_other IS NOT NULL
          AND length(trim(document_type_other)) > 0
        )
      ),
      CONSTRAINT chk_document_versions_document_type_other_must_be_null CHECK (
        document_type = 'other'
        OR document_type_other IS NULL
      ),
      CONSTRAINT chk_document_versions_aggregated_text_not_blank CHECK (
        aggregated_text IS NULL
        OR length(trim(aggregated_text)) > 0
      ),
      CONSTRAINT chk_document_versions_aggregate_hash_not_blank CHECK (
        aggregate_hash IS NULL
        OR length(trim(aggregate_hash)) > 0
      ),
      CONSTRAINT chk_document_versions_page_count_non_negative CHECK (
        page_count >= 0
      )
    );
  ''');

  await runtime.customStatement('''
    CREATE TABLE IF NOT EXISTS document_version_pages (
      id TEXT NOT NULL PRIMARY KEY,
      version_id TEXT NOT NULL REFERENCES document_versions(id) ON DELETE CASCADE,
      metadata_history_id TEXT NULL
        REFERENCES file_metadata_history(id) ON DELETE SET NULL,
      page_number INTEGER NOT NULL,
      extracted_text TEXT NULL,
      page_hash TEXT NULL,
      is_primary INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      UNIQUE(version_id, page_number),
      CONSTRAINT chk_document_version_pages_page_number_positive CHECK (
        page_number > 0
      ),
      CONSTRAINT chk_document_version_pages_extracted_text_not_blank CHECK (
        extracted_text IS NULL
        OR length(trim(extracted_text)) > 0
      ),
      CONSTRAINT chk_document_version_pages_page_hash_not_blank CHECK (
        page_hash IS NULL
        OR length(trim(page_hash)) > 0
      )
    );
  ''');

  for (final sql in _documentVersioningIndexes) {
    await runtime.customStatement(sql);
  }

  await runtime.reinstallHistoryTriggers();

  logInfo('Schema version 5 migration completed', tag: logTag);
}

const List<String> _documentVersioningIndexes = [
  'CREATE INDEX IF NOT EXISTS idx_file_metadata_history_history_id ON file_metadata_history(history_id);',
  'CREATE INDEX IF NOT EXISTS idx_file_metadata_history_metadata_id ON file_metadata_history(metadata_id);',
  'CREATE INDEX IF NOT EXISTS idx_file_metadata_history_mime_type ON file_metadata_history(mime_type);',
  'CREATE INDEX IF NOT EXISTS idx_file_metadata_history_sha256 ON file_metadata_history(sha256);',
  'CREATE INDEX IF NOT EXISTS idx_file_metadata_history_snapshot_created_at ON file_metadata_history(snapshot_created_at);',
  'CREATE INDEX IF NOT EXISTS idx_document_versions_document_id ON document_versions(document_id);',
  'CREATE INDEX IF NOT EXISTS idx_document_versions_document_type ON document_versions(document_type);',
  'CREATE INDEX IF NOT EXISTS idx_document_versions_aggregate_hash ON document_versions(aggregate_hash);',
  'CREATE INDEX IF NOT EXISTS idx_document_versions_created_at ON document_versions(created_at);',
  'CREATE UNIQUE INDEX IF NOT EXISTS uq_document_versions_one_current_per_document ON document_versions(document_id) WHERE is_current = 1;',
  'CREATE INDEX IF NOT EXISTS idx_document_version_pages_version_id ON document_version_pages(version_id);',
  'CREATE INDEX IF NOT EXISTS idx_document_version_pages_metadata_history_id ON document_version_pages(metadata_history_id);',
  'CREATE INDEX IF NOT EXISTS idx_document_version_pages_page_hash ON document_version_pages(page_hash);',
  'CREATE UNIQUE INDEX IF NOT EXISTS uq_document_version_pages_one_primary_per_version ON document_version_pages(version_id) WHERE is_primary = 1;',
  'CREATE INDEX IF NOT EXISTS idx_doc_versions_current ON document_versions(document_id, is_current);',
  'CREATE INDEX IF NOT EXISTS idx_doc_version_pages_version_page ON document_version_pages(version_id, page_number);',
  'CREATE INDEX IF NOT EXISTS idx_fmh_metadata_id ON file_metadata_history(metadata_id);',
];
