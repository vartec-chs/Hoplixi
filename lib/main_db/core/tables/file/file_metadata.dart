import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

enum FileIntegrityStatus { unknown, ok, missing, corrupted, deleted }

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

  /// Файл не найден по ожидаемому пути.
  BoolColumn get isMissing => boolean().withDefault(const Constant(false))();

  /// Файл штатно удалён через приложение.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// Когда впервые обнаружено отсутствие файла.
  DateTimeColumn get missingDetectedAt => dateTime().nullable()();

  /// Когда файл штатно удалён через приложение.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Последний известный путь, если текущий `filePath` уже невалиден.
  TextColumn get lastKnownPath => text().nullable()();

  /// Время последней проверки наличия и SHA-256.
  DateTimeColumn get lastIntegrityCheckAt => dateTime().nullable()();

  /// Последний известный результат проверки физического файла.
  TextColumn get integrityStatus =>
      textEnum<FileIntegrityStatus>().withDefault(const Constant('unknown'))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'file_metadata';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${FileMetadataConstraint.fileNameNotBlank.constraintName}
    CHECK (
      length(trim(file_name)) > 0
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
    CONSTRAINT ${FileMetadataConstraint.filePathNotBlank.constraintName}
    CHECK (
      file_path IS NULL
      OR length(trim(file_path)) > 0
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.mimeTypeNotBlank.constraintName}
    CHECK (
      length(trim(mime_type)) > 0
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
    CONSTRAINT ${FileMetadataConstraint.lastKnownPathNotBlank.constraintName}
    CHECK (
      last_known_path IS NULL
      OR length(trim(last_known_path)) > 0
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.integrityStatusKnown.constraintName}
    CHECK (
      integrity_status IN (
        'unknown',
        'ok',
        'missing',
        'corrupted',
        'deleted'
      )
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.missingDetectedAtRequired.constraintName}
    CHECK (
      is_missing = 0
      OR missing_detected_at IS NOT NULL
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.deletedAtRequired.constraintName}
    CHECK (
      is_deleted = 0
      OR deleted_at IS NOT NULL
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.integrityStatusMatchesMissing.constraintName}
    CHECK (
      (integrity_status = 'missing' AND is_missing = 1 AND is_deleted = 0)
      OR (integrity_status != 'missing' AND is_missing = 0)
    )
    ''',

    '''
    CONSTRAINT ${FileMetadataConstraint.integrityStatusMatchesDeleted.constraintName}
    CHECK (
      (integrity_status = 'deleted' AND is_deleted = 1 AND is_missing = 0)
      OR (integrity_status != 'deleted' AND is_deleted = 0)
    )
    ''',
  ];
}

enum FileMetadataConstraint {
  fileNameNotBlank('chk_file_metadata_file_name_not_blank'),

  fileExtensionNotBlank('chk_file_metadata_file_extension_not_blank'),

  filePathNotBlank('chk_file_metadata_file_path_not_blank'),

  mimeTypeNotBlank('chk_file_metadata_mime_type_not_blank'),

  fileSizeNonNegative('chk_file_metadata_file_size_non_negative'),

  sha256NotBlank('chk_file_metadata_sha256_not_blank'),

  sha256Length('chk_file_metadata_sha256_length'),

  sha256Hex('chk_file_metadata_sha256_hex'),

  lastKnownPathNotBlank('chk_file_metadata_last_known_path_not_blank'),

  integrityStatusKnown('chk_file_metadata_integrity_status_known'),

  missingDetectedAtRequired('chk_file_metadata_missing_detected_at_required'),

  deletedAtRequired('chk_file_metadata_deleted_at_required'),

  integrityStatusMatchesMissing(
    'chk_file_metadata_integrity_status_matches_missing',
  ),

  integrityStatusMatchesDeleted(
    'chk_file_metadata_integrity_status_matches_deleted',
  );

  const FileMetadataConstraint(this.constraintName);

  final String constraintName;
}

enum FileMetadataIndex {
  fileName('idx_file_metadata_file_name'),
  fileExtension('idx_file_metadata_file_extension'),
  mimeType('idx_file_metadata_mime_type'),
  sha256('idx_file_metadata_sha256'),
  integrityStatus('idx_file_metadata_integrity_status'),
  lastIntegrityCheckAt('idx_file_metadata_last_integrity_check_at');

  const FileMetadataIndex(this.indexName);

  final String indexName;
}

final List<String> fileMetadataTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${FileMetadataIndex.fileName.indexName} ON file_metadata(file_name);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataIndex.fileExtension.indexName} ON file_metadata(file_extension);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataIndex.mimeType.indexName} ON file_metadata(mime_type);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataIndex.sha256.indexName} ON file_metadata(sha256);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataIndex.integrityStatus.indexName} ON file_metadata(integrity_status);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataIndex.lastIntegrityCheckAt.indexName} ON file_metadata(last_integrity_check_at);',
];
