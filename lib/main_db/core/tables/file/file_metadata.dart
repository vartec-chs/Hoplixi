import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

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
  ];
}

enum FileMetadataConstraint {
  fileNameNotBlank('chk_file_metadata_file_name_not_blank'),

  fileExtensionNotBlank('chk_file_metadata_file_extension_not_blank'),

  filePathNotBlank('chk_file_metadata_file_path_not_blank'),

  mimeTypeNotBlank('chk_file_metadata_mime_type_not_blank'),

  fileSizeNonNegative('chk_file_metadata_file_size_non_negative'),

  sha256NotBlank('chk_file_metadata_sha256_not_blank'),

  sha256Length('chk_file_metadata_sha256_length');

  const FileMetadataConstraint(this.constraintName);

  final String constraintName;
}

enum FileMetadataIndex {
  fileName('idx_file_metadata_file_name'),
  fileExtension('idx_file_metadata_file_extension'),
  mimeType('idx_file_metadata_mime_type'),
  fileHash('idx_file_metadata_file_hash');

  const FileMetadataIndex(this.indexName);

  final String indexName;
}

final List<String> fileMetadataTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${FileMetadataIndex.fileName.indexName} ON file_metadata(file_name);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataIndex.fileExtension.indexName} ON file_metadata(file_extension);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataIndex.mimeType.indexName} ON file_metadata(mime_type);',
  'CREATE INDEX IF NOT EXISTS ${FileMetadataIndex.fileHash.indexName} ON file_metadata(file_hash);',
];
