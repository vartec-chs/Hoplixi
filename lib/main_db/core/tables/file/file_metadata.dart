import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

enum FileAvailabilityStatus { available, missing, deleted }

enum FileIntegrityStatus { unknown, valid, corrupted }

@DataClassName('FileMetadataData')
class FileMetadata extends Table {
  /// UUID метаданных.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Оригинальное имя файла.
  TextColumn get fileName => text().withLength(min: 1, max: 255)();

  /// Расширение файла: pdf, txt, png и т.д.
  ///
  /// Nullable, потому что файл может не иметь расширения.
  TextColumn get fileExtension =>
      text().withLength(min: 1, max: 32).nullable()();

  /// Относительный путь от директории файлов/attachments.
  TextColumn get filePath => text().withLength(min: 1, max: 2048).nullable()();

  /// MIME тип, например application/pdf.
  TextColumn get mimeType => text().withLength(min: 1, max: 255)();

  /// Размер файла в байтах.
  IntColumn get fileSize => integer()();

  /// SHA-256 хэш для проверки целостности.
  TextColumn get sha256 => text().withLength(min: 64, max: 64).nullable()();

  /// Статус физической доступности файла.
  TextColumn get availabilityStatus => textEnum<FileAvailabilityStatus>()
      .withDefault(const Constant('available'))();

  /// Статус целостности файла.
  TextColumn get integrityStatus => textEnum<FileIntegrityStatus>()
      .withDefault(const Constant('unknown'))();

  /// Когда впервые обнаружено отсутствие файла.
  DateTimeColumn get missingDetectedAt => dateTime().nullable()();

  /// Когда файл штатно удалён через приложение.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Время последней проверки наличия и SHA-256.
  DateTimeColumn get lastIntegrityCheckAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'file_metadata';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${FileMetadataConstraint.idNotBlank.constraintName}
    CHECK (length(trim(id)) > 0)
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.fileNameNotBlank.constraintName}
    CHECK (
      length(trim(file_name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.fileNameNoOuterWhitespace.constraintName}
    CHECK (
      file_name = trim(file_name)
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.fileExtensionNotBlank.constraintName}
    CHECK (
      file_extension IS NULL
      OR length(trim(file_extension)) > 0
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.fileExtensionNoOuterWhitespace.constraintName}
    CHECK (
      file_extension IS NULL
      OR file_extension = trim(file_extension)
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.filePathNotBlank.constraintName}
    CHECK (
      file_path IS NULL
      OR length(trim(file_path)) > 0
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.filePathNoOuterWhitespace.constraintName}
    CHECK (
      file_path IS NULL
      OR file_path = trim(file_path)
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.mimeTypeNotBlank.constraintName}
    CHECK (
      length(trim(mime_type)) > 0
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.mimeTypeNoOuterWhitespace.constraintName}
    CHECK (
      mime_type = trim(mime_type)
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.fileSizeNonNegative.constraintName}
    CHECK (
      file_size >= 0
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.sha256NotBlank.constraintName}
    CHECK (
      sha256 IS NULL
      OR length(trim(sha256)) > 0 
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.sha256NoOuterWhitespace.constraintName}
    CHECK (
      sha256 IS NULL
      OR sha256 = trim(sha256)
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.sha256Length.constraintName}
    CHECK (
      sha256 IS NULL
      OR length(sha256) = 64
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.sha256Hex.constraintName}
    CHECK (
      sha256 IS NULL
      OR sha256 GLOB '[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.availabilityMissingDateConsistent.constraintName}
    CHECK (
      (availability_status != 'missing' AND missing_detected_at IS NULL)
      OR
      (availability_status = 'missing' AND missing_detected_at IS NOT NULL)
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.availabilityDeletedDateConsistent.constraintName}
    CHECK (
      (availability_status != 'deleted' AND deleted_at IS NULL)
      OR
      (availability_status = 'deleted' AND deleted_at IS NOT NULL)
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.availabilityMissingDeletedDatesConflict.constraintName}
    CHECK (
      NOT (
        missing_detected_at IS NOT NULL
        AND deleted_at IS NOT NULL
      )
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.integrityRequiresAvailable.constraintName}
    CHECK (
      integrity_status != 'corrupted'
      OR availability_status = 'available'
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.validIntegrityRequiresCheckDate.constraintName}
    CHECK (
      integrity_status != 'valid'
      OR last_integrity_check_at IS NOT NULL
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.corruptedIntegrityRequiresCheckDate.constraintName}
    CHECK (
      integrity_status != 'corrupted'
      OR last_integrity_check_at IS NOT NULL
    )
    ''',
  ];
}

enum FileMetadataConstraint {
  idNotBlank('chk_file_metadata_id_not_blank'),

  fileNameNotBlank('chk_file_metadata_file_name_not_blank'),

  fileNameNoOuterWhitespace('chk_file_metadata_file_name_no_outer_whitespace'),

  fileExtensionNotBlank('chk_file_metadata_file_extension_not_blank'),

  fileExtensionNoOuterWhitespace('chk_file_metadata_file_extension_no_outer_whitespace'),

  filePathNotBlank('chk_file_metadata_file_path_not_blank'),

  filePathNoOuterWhitespace('chk_file_metadata_file_path_no_outer_whitespace'),

  mimeTypeNotBlank('chk_file_metadata_mime_type_not_blank'),

  mimeTypeNoOuterWhitespace('chk_file_metadata_mime_type_no_outer_whitespace'),

  fileSizeNonNegative('chk_file_metadata_file_size_non_negative'),

  sha256NotBlank('chk_file_metadata_sha256_not_blank'),

  sha256NoOuterWhitespace('chk_file_metadata_sha256_no_outer_whitespace'),

  sha256Length('chk_file_metadata_sha256_length'),

  sha256Hex('chk_file_metadata_sha256_hex'),

  availabilityMissingDateConsistent('chk_file_metadata_availability_missing_date_consistent'),

  availabilityDeletedDateConsistent('chk_file_metadata_availability_deleted_date_consistent'),

  availabilityMissingDeletedDatesConflict('chk_file_metadata_availability_missing_deleted_dates_conflict'),

  integrityRequiresAvailable('chk_file_metadata_integrity_requires_available'),

  validIntegrityRequiresCheckDate('chk_file_metadata_valid_integrity_requires_check_date'),

  corruptedIntegrityRequiresCheckDate('chk_file_metadata_corrupted_integrity_requires_check_date');

  const FileMetadataConstraint(this.constraintName);

  final String constraintName;
}

enum FileMetadataIndex {
  fileName('idx_file_metadata_file_name'),
  fileExtension('idx_file_metadata_file_extension'),
  mimeType('idx_file_metadata_mime_type'),
  sha256('idx_file_metadata_sha256'),
  availabilityStatus('idx_file_metadata_availability_status'),
  integrityStatus('idx_file_metadata_integrity_status'),
  lastIntegrityCheckAt('idx_file_metadata_last_integrity_check_at');

  const FileMetadataIndex(this.indexName);

  final String indexName;
}

final List<String> fileMetadataTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${FileMetadataIndex.fileName.indexName} ON file_metadata(file_name);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataIndex.fileExtension.indexName} ON file_metadata(file_extension) WHERE file_extension IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataIndex.mimeType.indexName} ON file_metadata(mime_type) WHERE mime_type IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataIndex.sha256.indexName} ON file_metadata(sha256) WHERE sha256 IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataIndex.availabilityStatus.indexName} ON file_metadata(availability_status);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataIndex.integrityStatus.indexName} ON file_metadata(integrity_status);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataIndex.lastIntegrityCheckAt.indexName} ON file_metadata(last_integrity_check_at) WHERE last_integrity_check_at IS NOT NULL;',
];
