import 'package:drift/drift.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/core/migrations/main_store_migration_types.dart';

Future<void> migrateToV5(
  Migrator migrator,
  MainStoreMigrationRuntime runtime,
) async {
  const logTag = 'MainStoreMigration';
  logInfo('Running migration to schema version 5', tag: logTag);

  for (final sql in _documentSnapshotTables) {
    await runtime.customStatement(sql);
  }

  for (final sql in _schemaChanges) {
    await runtime.customStatement(sql);
  }

  for (final sql in _documentSnapshotIndexes) {
    await runtime.customStatement(sql);
  }

  await runtime.reinstallHistoryTriggers();

  logInfo('Schema version 5 migration completed', tag: logTag);
}

const List<String> _schemaChanges = [
  'ALTER TABLE document_items ADD COLUMN current_version_id TEXT NULL REFERENCES document_versions(id) ON DELETE SET NULL;',
  'ALTER TABLE document_pages ADD COLUMN current_version_page_id TEXT NULL REFERENCES document_version_pages(id) ON DELETE SET NULL;',
  'ALTER TABLE vault_item_history ADD COLUMN snapshot_id TEXT NULL;',
  'ALTER TABLE password_history ADD COLUMN snapshot_id TEXT NULL;',
  'ALTER TABLE api_key_history ADD COLUMN snapshot_id TEXT NULL;',
  'ALTER TABLE bank_card_history ADD COLUMN snapshot_id TEXT NULL;',
  'ALTER TABLE certificate_history ADD COLUMN snapshot_id TEXT NULL;',
  'ALTER TABLE contact_history ADD COLUMN snapshot_id TEXT NULL;',
  'ALTER TABLE crypto_wallet_history ADD COLUMN snapshot_id TEXT NULL;',
  'ALTER TABLE file_history ADD COLUMN snapshot_id TEXT NULL;',
  'ALTER TABLE file_history ADD COLUMN metadata_history_id TEXT NULL REFERENCES file_metadata_history(id) ON DELETE SET NULL;',
  'ALTER TABLE identity_history ADD COLUMN snapshot_id TEXT NULL;',
  'ALTER TABLE license_key_history ADD COLUMN snapshot_id TEXT NULL;',
  'ALTER TABLE loyalty_card_history ADD COLUMN snapshot_id TEXT NULL;',
  'ALTER TABLE note_history ADD COLUMN snapshot_id TEXT NULL;',
  'ALTER TABLE otp_history ADD COLUMN snapshot_id TEXT NULL;',
  'ALTER TABLE recovery_codes_history ADD COLUMN snapshot_id TEXT NULL;',
  'ALTER TABLE ssh_key_history ADD COLUMN snapshot_id TEXT NULL;',
  'ALTER TABLE wifi_history ADD COLUMN snapshot_id TEXT NULL;',
  'ALTER TABLE vault_item_custom_fields_history ADD COLUMN snapshot_id TEXT NULL;',
];

const List<String> _documentSnapshotTables = [
  '''
    CREATE TABLE IF NOT EXISTS file_metadata_history (
      id TEXT NOT NULL PRIMARY KEY,
      history_id TEXT NULL REFERENCES vault_item_history(id) ON DELETE CASCADE,
      owner_kind TEXT NOT NULL DEFAULT 'standalone',
      owner_id TEXT NULL,
      metadata_id TEXT NULL,
      file_name TEXT NOT NULL,
      file_extension TEXT NULL,
      file_path TEXT NULL,
      mime_type TEXT NOT NULL,
      file_size INTEGER NOT NULL,
      sha256 TEXT NULL,
      snapshot_id TEXT NULL,
      snapshot_created_at INTEGER NOT NULL,
      CONSTRAINT chk_file_metadata_history_file_name_not_blank CHECK (length(trim(file_name)) > 0),
      CONSTRAINT chk_file_metadata_history_file_extension_not_blank CHECK (file_extension IS NULL OR length(trim(file_extension)) > 0),
      CONSTRAINT chk_file_metadata_history_file_path_not_blank CHECK (file_path IS NULL OR length(trim(file_path)) > 0),
      CONSTRAINT chk_file_metadata_history_mime_type_not_blank CHECK (length(trim(mime_type)) > 0),
      CONSTRAINT chk_file_metadata_history_file_size_non_negative CHECK (file_size >= 0),
      CONSTRAINT chk_file_metadata_history_sha256_not_blank CHECK (sha256 IS NULL OR length(trim(sha256)) > 0),
      CONSTRAINT chk_file_metadata_history_sha256_length CHECK (sha256 IS NULL OR length(sha256) = 64),
      CONSTRAINT chk_file_metadata_history_owner_kind_known CHECK (owner_kind IN ('fileItemHistory', 'documentVersionPage', 'attachmentSnapshot', 'standalone')),
      CONSTRAINT chk_file_metadata_history_owner_id_required CHECK (owner_kind = 'standalone' OR (owner_id IS NOT NULL AND length(trim(owner_id)) > 0)),
      CONSTRAINT chk_file_metadata_history_owner_id_must_be_null_for_standalone CHECK (owner_kind != 'standalone' OR owner_id IS NULL),
      CONSTRAINT chk_file_metadata_history_history_id_must_be_null_for_standalone CHECK (owner_kind != 'standalone' OR history_id IS NULL),
      CONSTRAINT chk_file_metadata_history_file_item_owner_matches_history CHECK (owner_kind != 'fileItemHistory' OR (history_id IS NOT NULL AND owner_id = history_id))
    );
  ''',
  '''
    CREATE TABLE IF NOT EXISTS document_versions (
      id TEXT NOT NULL PRIMARY KEY,
      document_id TEXT NOT NULL REFERENCES vault_items(id) ON DELETE CASCADE,
      item_history_id TEXT NULL REFERENCES vault_item_history(id) ON DELETE SET NULL,
      version_number INTEGER NOT NULL,
      document_type TEXT NULL,
      document_type_other TEXT NULL,
      aggregate_sha256_hash TEXT NULL,
      page_count INTEGER NOT NULL DEFAULT 0,
      snapshot_id TEXT NULL,
      created_at INTEGER NOT NULL,
      modified_at INTEGER NOT NULL,
      UNIQUE(document_id, version_number),
      CONSTRAINT chk_document_versions_version_number_positive CHECK (version_number > 0),
      CONSTRAINT chk_document_versions_document_type_other_required CHECK (
        document_type IS NULL OR document_type != 'other' OR (
          document_type_other IS NOT NULL AND length(trim(document_type_other)) > 0
        )
      ),
      CONSTRAINT chk_document_versions_document_type_other_must_be_null CHECK (
        document_type = 'other' OR document_type_other IS NULL
      ),
      CONSTRAINT chk_document_versions_aggregate_sha256_hash_not_blank CHECK (
        aggregate_sha256_hash IS NULL OR length(trim(aggregate_sha256_hash)) > 0
      ),
      CONSTRAINT chk_document_versions_page_count_non_negative CHECK (page_count >= 0)
    );
  ''',
  '''
    CREATE TABLE IF NOT EXISTS document_version_pages (
      id TEXT NOT NULL PRIMARY KEY,
      version_id TEXT NOT NULL REFERENCES document_versions(id) ON DELETE CASCADE,
      metadata_history_id TEXT NULL REFERENCES file_metadata_history(id) ON DELETE SET NULL,
      page_number INTEGER NOT NULL,
      page_sha256_hash TEXT NULL,
      is_primary INTEGER NOT NULL DEFAULT 0,
      snapshot_id TEXT NULL,
      created_at INTEGER NOT NULL,
      UNIQUE(version_id, page_number),
      CONSTRAINT chk_document_version_pages_page_number_positive CHECK (page_number > 0),
      CONSTRAINT chk_document_version_pages_page_sha256_hash_not_blank CHECK (
        page_sha256_hash IS NULL OR length(trim(page_sha256_hash)) > 0
      )
    );
  ''',
  '''
    CREATE TABLE IF NOT EXISTS item_category_history (
      id TEXT NOT NULL PRIMARY KEY,
      history_id TEXT NULL REFERENCES vault_item_history(id) ON DELETE CASCADE,
      snapshot_id TEXT NULL,
      item_id TEXT NULL,
      category_id TEXT NULL,
      name TEXT NOT NULL,
      description TEXT NULL,
      icon_ref_id TEXT NULL,
      color TEXT NOT NULL,
      type TEXT NOT NULL,
      parent_id TEXT NULL,
      category_created_at INTEGER NULL,
      category_modified_at INTEGER NULL,
      snapshot_created_at INTEGER NOT NULL,
      CONSTRAINT chk_item_category_history_name_not_blank CHECK (length(trim(name)) > 0),
      CONSTRAINT chk_item_category_history_description_not_blank CHECK (description IS NULL OR length(trim(description)) > 0),
      CONSTRAINT chk_item_category_history_color_argb_hex CHECK (
        color GLOB '[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'
      )
    );
  ''',
  '''
    CREATE TABLE IF NOT EXISTS vault_item_tag_history (
      id TEXT NOT NULL PRIMARY KEY,
      history_id TEXT NULL REFERENCES vault_item_history(id) ON DELETE CASCADE,
      snapshot_id TEXT NULL,
      item_id TEXT NULL,
      tag_id TEXT NULL,
      name TEXT NOT NULL,
      color TEXT NOT NULL,
      type TEXT NOT NULL,
      tag_created_at INTEGER NULL,
      tag_modified_at INTEGER NULL,
      snapshot_created_at INTEGER NOT NULL,
      CONSTRAINT chk_vault_item_tag_history_name_not_blank CHECK (length(trim(name)) > 0),
      CONSTRAINT chk_vault_item_tag_history_color_argb_hex CHECK (
        color GLOB '[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'
      )
    );
  ''',
];

const List<String> _documentSnapshotIndexes = [
  'CREATE INDEX IF NOT EXISTS idx_document_items_current_version_id ON document_items(current_version_id);',
  'CREATE INDEX IF NOT EXISTS idx_document_pages_current_version_page_id ON document_pages(current_version_page_id);',
  'CREATE INDEX IF NOT EXISTS idx_doc_pages_current_version_page ON document_pages(current_version_page_id);',
  'CREATE UNIQUE INDEX IF NOT EXISTS uq_document_pages_document_id_current_version_page_id ON document_pages(document_id, current_version_page_id);',
  'CREATE INDEX IF NOT EXISTS idx_vault_item_history_snapshot_id ON vault_item_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_password_history_snapshot_id ON password_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_api_key_history_snapshot_id ON api_key_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_bank_card_history_snapshot_id ON bank_card_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_certificate_history_snapshot_id ON certificate_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_contact_history_snapshot_id ON contact_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_crypto_wallet_history_snapshot_id ON crypto_wallet_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_file_history_snapshot_id ON file_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_identity_history_snapshot_id ON identity_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_license_key_history_snapshot_id ON license_key_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_loyalty_card_history_snapshot_id ON loyalty_card_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_note_history_snapshot_id ON note_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_otp_history_snapshot_id ON otp_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_recovery_codes_history_snapshot_id ON recovery_codes_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_ssh_key_history_snapshot_id ON ssh_key_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_wifi_history_snapshot_id ON wifi_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_vault_item_custom_fields_history_snapshot_id ON vault_item_custom_fields_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_file_metadata_history_snapshot_id ON file_metadata_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_file_metadata_history_history_id ON file_metadata_history(history_id);',
  'CREATE INDEX IF NOT EXISTS idx_file_metadata_history_owner_kind ON file_metadata_history(owner_kind);',
  'CREATE INDEX IF NOT EXISTS idx_file_metadata_history_owner_id ON file_metadata_history(owner_id);',
  'CREATE INDEX IF NOT EXISTS idx_file_metadata_history_owner ON file_metadata_history(owner_kind, owner_id);',
  'CREATE INDEX IF NOT EXISTS idx_file_metadata_history_metadata_id ON file_metadata_history(metadata_id);',
  'CREATE INDEX IF NOT EXISTS idx_file_metadata_history_mime_type ON file_metadata_history(mime_type);',
  'CREATE INDEX IF NOT EXISTS idx_file_metadata_history_sha256 ON file_metadata_history(sha256);',
  'CREATE INDEX IF NOT EXISTS idx_file_metadata_history_snapshot_created_at ON file_metadata_history(snapshot_created_at);',
  'CREATE INDEX IF NOT EXISTS idx_document_versions_snapshot_id ON document_versions(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_document_versions_document_id ON document_versions(document_id);',
  'CREATE INDEX IF NOT EXISTS idx_document_versions_document_type ON document_versions(document_type);',
  'CREATE INDEX IF NOT EXISTS idx_document_versions_aggregate_sha256_hash ON document_versions(aggregate_sha256_hash);',
  'CREATE INDEX IF NOT EXISTS idx_document_versions_created_at ON document_versions(created_at);',
  'CREATE INDEX IF NOT EXISTS idx_document_version_pages_snapshot_id ON document_version_pages(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_document_version_pages_version_id ON document_version_pages(version_id);',
  'CREATE INDEX IF NOT EXISTS idx_document_version_pages_metadata_history_id ON document_version_pages(metadata_history_id);',
  'CREATE INDEX IF NOT EXISTS idx_document_version_pages_page_sha256_hash ON document_version_pages(page_sha256_hash);',
  'CREATE UNIQUE INDEX IF NOT EXISTS uq_document_version_pages_one_primary_per_version ON document_version_pages(version_id) WHERE is_primary = 1;',
  'CREATE INDEX IF NOT EXISTS idx_item_category_history_snapshot_id ON item_category_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_item_category_history_history_id ON item_category_history(history_id);',
  'CREATE INDEX IF NOT EXISTS idx_item_category_history_item_id ON item_category_history(item_id);',
  'CREATE INDEX IF NOT EXISTS idx_item_category_history_category_id ON item_category_history(category_id);',
  'CREATE INDEX IF NOT EXISTS idx_item_category_history_type ON item_category_history(type);',
  'CREATE INDEX IF NOT EXISTS idx_item_category_history_snapshot_created_at ON item_category_history(snapshot_created_at);',
  'CREATE INDEX IF NOT EXISTS idx_vault_item_tag_history_snapshot_id ON vault_item_tag_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS idx_vault_item_tag_history_history_id ON vault_item_tag_history(history_id);',
  'CREATE INDEX IF NOT EXISTS idx_vault_item_tag_history_item_id ON vault_item_tag_history(item_id);',
  'CREATE INDEX IF NOT EXISTS idx_vault_item_tag_history_tag_id ON vault_item_tag_history(tag_id);',
  'CREATE INDEX IF NOT EXISTS idx_vault_item_tag_history_type ON vault_item_tag_history(type);',
  'CREATE INDEX IF NOT EXISTS idx_vault_item_tag_history_snapshot_created_at ON vault_item_tag_history(snapshot_created_at);',
];
