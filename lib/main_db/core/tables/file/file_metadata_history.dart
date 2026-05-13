import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../vault_items/vault_snapshots_history.dart';

enum FileMetadataHistoryOwnerKind {
  fileItemHistory,
  documentVersionPage,
  attachmentSnapshot,
  standalone,
}

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
      .withDefault(const Constant('standalone'))();

  /// ID владельца snapshot-записи, если ownerKind не standalone.
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

  /// UUID снимка для группировки связанных записей.
  TextColumn get snapshotId => text().nullable()();

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
    CONSTRAINT ${FileMetadataHistoryConstraint.fileNameNotBlank.constraintName}
    CHECK (
      length(trim(file_name)) > 0
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
    CONSTRAINT ${FileMetadataHistoryConstraint.filePathNotBlank.constraintName}
    CHECK (
      file_path IS NULL
      OR length(trim(file_path)) > 0
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.mimeTypeNotBlank.constraintName}
    CHECK (
      length(trim(mime_type)) > 0
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
    CONSTRAINT ${FileMetadataHistoryConstraint.sha256Length.constraintName}
    CHECK (
      sha256 IS NULL
      OR length(sha256) = 64
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.ownerKindKnown.constraintName}
    CHECK (
      owner_kind IN (
        'fileItemHistory',
        'documentVersionPage',
        'attachmentSnapshot',
        'standalone'
      )
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.ownerIdRequired.constraintName}
    CHECK (
      owner_kind = 'standalone'
      OR (
        owner_id IS NOT NULL
        AND length(trim(owner_id)) > 0
      )
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.ownerIdMustBeNullForStandalone.constraintName}
    CHECK (
      owner_kind != 'standalone'
      OR owner_id IS NULL
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataHistoryConstraint.historyIdMustBeNullForStandalone.constraintName}
    CHECK (
      owner_kind != 'standalone'
      OR history_id IS NULL
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
  ];
}

enum FileMetadataHistoryConstraint {
  fileNameNotBlank('chk_file_metadata_history_file_name_not_blank'),
  fileExtensionNotBlank('chk_file_metadata_history_file_extension_not_blank'),
  filePathNotBlank('chk_file_metadata_history_file_path_not_blank'),
  mimeTypeNotBlank('chk_file_metadata_history_mime_type_not_blank'),
  fileSizeNonNegative('chk_file_metadata_history_file_size_non_negative'),
  sha256NotBlank('chk_file_metadata_history_sha256_not_blank'),
  sha256Length('chk_file_metadata_history_sha256_length'),
  ownerKindKnown('chk_file_metadata_history_owner_kind_known'),
  ownerIdRequired('chk_file_metadata_history_owner_id_required'),
  ownerIdMustBeNullForStandalone(
    'chk_file_metadata_history_owner_id_must_be_null_for_standalone',
  ),
  historyIdMustBeNullForStandalone(
    'chk_file_metadata_history_history_id_must_be_null_for_standalone',
  ),
  fileItemHistoryOwnerMatchesHistory(
    'chk_file_metadata_history_file_item_owner_matches_history',
  );

  const FileMetadataHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum FileMetadataHistoryIndex {
  snapshotId('idx_file_metadata_history_snapshot_id'),
  historyId('idx_file_metadata_history_history_id'),
  ownerKind('idx_file_metadata_history_owner_kind'),
  ownerId('idx_file_metadata_history_owner_id'),
  owner('idx_file_metadata_history_owner'),
  metadataId('idx_file_metadata_history_metadata_id'),
  mimeType('idx_file_metadata_history_mime_type'),
  sha256('idx_file_metadata_history_sha256'),
  snapshotCreatedAt('idx_file_metadata_history_snapshot_created_at');

  const FileMetadataHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> fileMetadataHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.snapshotId.indexName} ON file_metadata_history(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.historyId.indexName} ON file_metadata_history(history_id);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.ownerKind.indexName} ON file_metadata_history(owner_kind);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.ownerId.indexName} ON file_metadata_history(owner_id);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.owner.indexName} ON file_metadata_history(owner_kind, owner_id);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.metadataId.indexName} ON file_metadata_history(metadata_id);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.mimeType.indexName} ON file_metadata_history(mime_type);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.sha256.indexName} ON file_metadata_history(sha256);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataHistoryIndex.snapshotCreatedAt.indexName} ON file_metadata_history(snapshot_created_at);',
];
