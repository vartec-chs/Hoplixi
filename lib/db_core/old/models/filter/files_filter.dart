import 'package:freezed_annotation/freezed_annotation.dart';
import 'base_filter.dart';

part 'files_filter.freezed.dart';
part 'files_filter.g.dart';

enum FilesSortField {
  name,
  fileName,
  fileSize,
  fileExtension,
  mimeType,
  createdAt,
  modifiedAt,
  lastAccessed,
}

@freezed
abstract class FilesFilter with _$FilesFilter {
  const factory FilesFilter({
    required BaseFilter base,
    @Default(<String>[]) List<String> fileExtensions,
    @Default(<String>[]) List<String> mimeTypes,
    int? minFileSize, // в байтах
    int? maxFileSize, // в байтах
    String? fileName,
    FilesSortField? sortField,
  }) = _FilesFilter;

  factory FilesFilter.create({
    BaseFilter? base,
    List<String>? fileExtensions,
    List<String>? mimeTypes,
    int? minFileSize,
    int? maxFileSize,
    String? fileName,
    FilesSortField? sortField,
  }) {
    final normalizedFileName = fileName?.trim();
    final normalizedExtensions = (fileExtensions ?? <String>[])
        .map((ext) => ext.trim().toLowerCase())
        .where((ext) => ext.isNotEmpty)
        .toSet()
        .toList();
    final normalizedMimeTypes = (mimeTypes ?? <String>[])
        .map((mime) => mime.trim().toLowerCase())
        .where((mime) => mime.isNotEmpty)
        .toSet()
        .toList();

    return FilesFilter(
      base: base ?? const BaseFilter(),
      fileExtensions: normalizedExtensions,
      mimeTypes: normalizedMimeTypes,
      minFileSize: minFileSize,
      maxFileSize: maxFileSize,
      fileName: normalizedFileName?.isEmpty == true ? null : normalizedFileName,
      sortField: sortField,
    );
  }

  factory FilesFilter.fromJson(Map<String, dynamic> json) =>
      _$FilesFilterFromJson(json);
}

extension FilesFilterHelpers on FilesFilter {
  /// Проверяет наличие активных ограничений фильтра
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (fileExtensions.isNotEmpty) return true;
    if (mimeTypes.isNotEmpty) return true;
    if (minFileSize != null) return true;
    if (maxFileSize != null) return true;
    if (fileName != null) return true;
    return false;
  }

  /// Проверка валидности размера файла
  bool get isValidFileSizeRange {
    if (minFileSize != null && maxFileSize != null) {
      return minFileSize! >= 0 && maxFileSize! >= minFileSize!;
    }
    if (minFileSize != null) {
      return minFileSize! >= 0;
    }
    if (maxFileSize != null) {
      return maxFileSize! >= 0;
    }
    return true;
  }
}
