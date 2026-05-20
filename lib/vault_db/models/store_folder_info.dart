import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_folder_info.freezed.dart';

/// Информация о папке хранилища для экспорта/импорта
@freezed
sealed class StoreFolderInfo with _$StoreFolderInfo {
  const factory StoreFolderInfo({
    /// Имя хранилища (из имени файла .hplxdb)
    required String storeName,

    /// Полный путь к папке хранилища
    required String folderPath,

    /// Путь к файлу базы данных
    required String dbFilePath,

    /// Размер папки в байтах
    required int sizeInBytes,

    /// Дата последнего изменения
    required DateTime lastModified,
  }) = _StoreFolderInfo;

  const StoreFolderInfo._();

  /// Размер в читаемом формате
  String get sizeFormatted {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
