import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../vault_items/vault_snapshots_history.dart';
import 'file_metadata.dart';

enum FileMetadataHistoryOwnerKind { fileItemHistory, documentVersionPage }

/// Snapshot технических данных файла.
///
/// Таблица хранит копии `file_metadata` для истории и версий документов.
/// `metadataId` намеренно не является FK: исходная запись `file_metadata`
/// может быть удалена или заменена, а snapshot должен остаться неизменным.
@DataClassName('FileMetadataHistoryData')
class FileMetadataHistory extends Table {
  /// UUID snapshot-записи.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// История vault item, если snapshot создан для history-события.
  TextColumn get historyId => text().nullable().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Тип владельца snapshot-записи.
  TextColumn get ownerKind => textEnum<FileMetadataHistoryOwnerKind>()
      .withDefault(const Constant('fileItemHistory'))();

  /// ID владельца snapshot-записи.
  TextColumn get ownerId => text().nullable()();

  /// ID исходной записи file_metadata на момент создания snapshot.
  TextColumn get metadataId => text().nullable()();

  /// Snapshot оригинального имени файла.
  TextColumn get fileName => text().withLength(min: 1, max: 255)();

  /// Snapshot расширения файла.
  TextColumn get fileExtension =>
      text().withLength(min: 1, max: 32).nullable()();

  /// Snapshot относительного пути от директории файлов/attachments.
  TextColumn get filePath => text().withLength(min: 1, max: 2048).nullable()();

  /// Snapshot MIME-типа, например application/pdf.
  TextColumn get mimeType => text().withLength(min: 1, max: 255)();

  /// Snapshot размера файла в байтах.
  IntColumn get fileSize => integer()();

  /// Snapshot SHA-256 хэша для проверки целостности.
  TextColumn get sha256 => text().withLength(min: 64, max: 64).nullable()();

  /// Snapshot статуса физической доступности файла.
  TextColumn get availabilityStatus => textEnum<FileAvailabilityStatus>()
      .withDefault(const Constant('available'))();

  /// Snapshot статуса целостности файла.
  TextColumn get integrityStatus =>
      textEnum<FileIntegrityStatus>().withDefault(const Constant('unknown'))();

  /// Когда впервые обнаружено отсутствие файла.
  DateTimeColumn get missingDetectedAt => dateTime().nullable()();

  /// Когда файл штатно удалён через приложение.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Время последней проверки наличия и SHA-256.
  DateTimeColumn get lastIntegrityCheckAt => dateTime().nullable()();

  /// Когда создан snapshot.
  DateTimeColumn get snapshotCreatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'file_metadata_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.idNotBlank.constraintName}
    CHECK (length(trim(id)) > 0)
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.historyIdNotBlank.constraintName}
    CHECK (
      history_id IS NULL
      OR length(trim(history_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.ownerIdNotBlank.constraintName}
    CHECK (
      owner_id IS NULL
      OR length(trim(owner_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.metadataIdNotBlank.constraintName}
    CHECK (
      metadata_id IS NULL
      OR length(trim(metadata_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.fileNameNotBlank.constraintName}
    CHECK (
      length(trim(file_name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.fileNameNoOuterWhitespace.constraintName}
    CHECK (
      file_name = trim(file_name)
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.fileExtensionNotBlank.constraintName}
    CHECK (
      file_extension IS NULL
      OR length(trim(file_extension)) > 0
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.fileExtensionNoOuterWhitespace.constraintName}
    CHECK (
      file_extension IS NULL
      OR file_extension = trim(file_extension)
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.filePathNotBlank.constraintName}
    CHECK (
      file_path IS NULL
      OR length(trim(file_path)) > 0
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.filePathNoOuterWhitespace.constraintName}
    CHECK (
      file_path IS NULL
      OR file_path = trim(file_path)
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.mimeTypeNotBlank.constraintName}
    CHECK (
      length(trim(mime_type)) > 0
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.mimeTypeNoOuterWhitespace.constraintName}
    CHECK (
      mime_type = trim(mime_type)
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.fileSizeNonNegative.constraintName}
    CHECK (
      file_size >= 0
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.sha256NotBlank.constraintName}
    CHECK (
      sha256 IS NULL
      OR length(trim(sha256)) > 0
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.sha256NoOuterWhitespace.constraintName}
    CHECK (
      sha256 IS NULL
      OR sha256 = trim(sha256)
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.sha256Length.constraintName}
    CHECK (
      sha256 IS NULL
      OR length(sha256) = 64
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.sha256Hex.constraintName}
    CHECK (
      sha256 IS NULL
      OR sha256 GLOB '[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.availabilityMissingDateConsistent.constraintName}
    CHECK (
      (availability_status != 'missing' AND missing_detected_at IS NULL)
      OR
      (availability_status = 'missing' AND missing_detected_at IS NOT NULL)
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.availabilityDeletedDateConsistent.constraintName}
    CHECK (
      (availability_status != 'deleted' AND deleted_at IS NULL)
      OR
      (availability_status = 'deleted' AND deleted_at IS NOT NULL)
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.availabilityMissingDeletedDatesConflict.constraintName}
    CHECK (
      NOT (
        missing_detected_at IS NOT NULL
        AND deleted_at IS NOT NULL
      )
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.integrityRequiresAvailable.constraintName}
    CHECK (
      integrity_status != 'corrupted'
      OR availability_status = 'available'
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.validIntegrityRequiresCheckDate.constraintName}
    CHECK (
      integrity_status != 'valid'
      OR last_integrity_check_at IS NOT NULL
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.corruptedIntegrityRequiresCheckDate.constraintName}
    CHECK (
      integrity_status != 'corrupted'
      OR last_integrity_check_at IS NOT NULL
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.ownerIdRequired.constraintName}
    CHECK (
      owner_id IS NOT NULL
      AND length(trim(owner_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.fileItemHistoryOwnerMatchesHistory.constraintName}
    CHECK (
      owner_kind != 'fileItemHistory'
      OR (
        history_id IS NOT NULL
        AND owner_id = history_id
      )
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.historyIdRequiredForFileItemHistory.constraintName}
    CHECK (
      owner_kind != 'fileItemHistory'
      OR history_id IS NOT NULL
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.historyIdMustBeNullForNonFileItemHistory.constraintName}
    CHECK (
      owner_kind = 'fileItemHistory'
      OR history_id IS NULL
    )
    ''',
  ];
}


enum FileMetadataHistoryConstraint {
  idNotBlank('chk_file_metadata_history_id_not_blank'),
  historyIdNotBlank('chk_file_metadata_history_history_id_not_blank'),
  ownerIdNotBlank('chk_file_metadata_history_owner_id_not_blank'),
  metadataIdNotBlank('chk_file_metadata_history_metadata_id_not_blank'),
  fileNameNotBlank('chk_file_metadata_history_file_name_not_blank'),
  fileNameNoOuterWhitespace(
    'chk_file_metadata_history_file_name_no_outer_whitespace',
  ),
  fileExtensionNotBlank('chk_file_metadata_history_file_extension_not_blank'),
  fileExtensionNoOuterWhitespace(
    'chk_file_metadata_history_file_extension_no_outer_whitespace',
  ),
  filePathNotBlank('chk_file_metadata_history_file_path_not_blank'),
  filePathNoOuterWhitespace(
    'chk_file_metadata_history_file_path_no_outer_whitespace',
  ),
  mimeTypeNotBlank('chk_file_metadata_history_mime_type_not_blank'),
  mimeTypeNoOuterWhitespace(
    'chk_file_metadata_history_mime_type_no_outer_whitespace',
  ),
  fileSizeNonNegative('chk_file_metadata_history_file_size_non_negative'),
  sha256NotBlank('chk_file_metadata_history_sha256_not_blank'),
  sha256NoOuterWhitespace(
    'chk_file_metadata_history_sha256_no_outer_whitespace',
  ),
  sha256Length('chk_file_metadata_history_sha256_length'),
  sha256Hex('chk_file_metadata_history_sha256_hex'),
  availabilityMissingDateConsistent(
    'chk_file_metadata_history_availability_missing_date_consistent',
  ),
  availabilityDeletedDateConsistent(
    'chk_file_metadata_history_availability_deleted_date_consistent',
  ),
  availabilityMissingDeletedDatesConflict(
    'chk_file_metadata_history_availability_missing_deleted_dates_conflict',
  ),
  integrityRequiresAvailable(
    'chk_file_metadata_history_integrity_requires_available',
  ),
  validIntegrityRequiresCheckDate(
    'chk_file_metadata_history_valid_integrity_requires_check_date',
  ),
  corruptedIntegrityRequiresCheckDate(
    'chk_file_metadata_history_corrupted_integrity_requires_check_date',
  ),
  ownerIdRequired('chk_file_metadata_history_owner_id_required'),
  fileItemHistoryOwnerMatchesHistory(
    'chk_file_metadata_history_file_item_owner_matches_history',
  ),
  historyIdRequiredForFileItemHistory(
    'chk_file_metadata_history_history_id_required_for_file_item_history',
  ),
  historyIdMustBeNullForNonFileItemHistory(
    'chk_file_metadata_history_history_id_must_be_null_for_non_file_item_history',
  );

  const FileMetadataHistoryConstraint(this.constraintName);

  final String constraintName;
}


enum FileMetadataHistoryIndex {
  historyId('idx_file_metadata_history_history_id'),
  ownerKind('idx_file_metadata_history_owner_kind'),
  ownerId('idx_file_metadata_history_owner_id'),
  owner('idx_file_metadata_history_owner'),
  metadataId('idx_file_metadata_history_metadata_id'),
  mimeType('idx_file_metadata_history_mime_type'),
  sha256('idx_file_metadata_history_sha256'),
  availabilityStatus('idx_file_metadata_history_availability_status'),
  integrityStatus('idx_file_metadata_history_integrity_status'),
  snapshotCreatedAt('idx_file_metadata_history_snapshot_created_at');

  const FileMetadataHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> fileMetadataHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.historyId.indexName} ON file_metadata_history(history_id) WHERE history_id IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.ownerKind.indexName} ON file_metadata_history(owner_kind);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.ownerId.indexName} ON file_metadata_history(owner_id) WHERE owner_id IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.owner.indexName} ON file_metadata_history(owner_kind, owner_id);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.metadataId.indexName} ON file_metadata_history(metadata_id) WHERE metadata_id IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.mimeType.indexName} ON file_metadata_history(mime_type) WHERE mime_type IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.sha256.indexName} ON file_metadata_history(sha256) WHERE sha256 IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.availabilityStatus.indexName} ON file_metadata_history(availability_status);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.integrityStatus.indexName} ON file_metadata_history(integrity_status);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.snapshotCreatedAt.indexName} ON file_metadata_history(snapshot_created_at) WHERE snapshot_created_at IS NOT NULL;',
];


enum FileMetadataHistoryTrigger {
  preventUpdate('trg_file_metadata_history_prevent_update');

  const FileMetadataHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum FileMetadataHistoryRaise {
  historyIsImmutable('file_metadata_history rows are immutable');

  const FileMetadataHistoryRaise(this.message);

  final String message;
}

final List<String> fileMetadataHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${FileMetadataHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON file_metadata_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${FileMetadataHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
