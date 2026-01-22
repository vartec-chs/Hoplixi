import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('FileMetadataData')
class FileMetadata extends Table {
  /// UUID метаданных
  TextColumn get id => text().clientDefault(() => Uuid().v4())();

  /// Оригинальное имя файла
  TextColumn get fileName => text()();

  /// Расширение файла (e.g., .pdf, .txt)
  TextColumn get fileExtension => text()();

  /// Относительный путь от директории файлов
  TextColumn get filePath => text().nullable()();

  /// MIME тип (e.g., application/pdf)
  TextColumn get mimeType => text()();

  /// Размер файла в байтах
  IntColumn get fileSize => integer()();

  /// SHA256 хэш для проверки целостности
  TextColumn get fileHash => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'file_metadata';
}
