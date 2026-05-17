import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../tables/file/file_metadata.dart';
import 'base_filter.dart';

part 'file_filter.freezed.dart';
part 'file_filter.g.dart';

enum FileSortField {
  name,
  fileName,
  fileSize,
  createdAt,
  modifiedAt,
  lastUsedAt,
  usedCount,
  recentScore,
}

@freezed
sealed class FileFilter with _$FileFilter {
  const factory FileFilter({
    @Default(BaseFilter()) BaseFilter base,

    String? fileName,
    String? fileExtension,
    String? mimeType,

    int? minFileSize,
    int? maxFileSize,

    FileAvailabilityStatus? availabilityStatus,
    FileIntegrityStatus? integrityStatus,

    DateTime? missingDetectedAfter,
    DateTime? deletedAfter,
    DateTime? lastIntegrityCheckAfter,
    DateTime? lastIntegrityCheckBefore,

    bool? hasSha256,

    FileSortField? sortField,
  }) = _FileFilter;

  factory FileFilter.create({
    BaseFilter? base,
    String? fileName,
    String? fileExtension,
    String? mimeType,
    int? minFileSize,
    int? maxFileSize,
    FileAvailabilityStatus? availabilityStatus,
    FileIntegrityStatus? integrityStatus,
    DateTime? missingDetectedAfter,
    DateTime? deletedAfter,
    DateTime? lastIntegrityCheckAfter,
    DateTime? lastIntegrityCheckBefore,
    bool? hasSha256,
    FileSortField? sortField,
  }) {
    final normalizedFileName = fileName?.trim();
    final normalizedFileExtension = fileExtension?.trim();
    final normalizedMimeType = mimeType?.trim();

    return FileFilter(
      base: base ?? const BaseFilter(),
      fileName: normalizedFileName?.isEmpty == true ? null : normalizedFileName,
      fileExtension: normalizedFileExtension?.isEmpty == true
          ? null
          : normalizedFileExtension,
      mimeType: normalizedMimeType?.isEmpty == true ? null : normalizedMimeType,
      minFileSize: minFileSize,
      maxFileSize: maxFileSize,
      availabilityStatus: availabilityStatus,
      integrityStatus: integrityStatus,
      missingDetectedAfter: missingDetectedAfter,
      deletedAfter: deletedAfter,
      lastIntegrityCheckAfter: lastIntegrityCheckAfter,
      lastIntegrityCheckBefore: lastIntegrityCheckBefore,
      hasSha256: hasSha256,
      sortField: sortField,
    );
  }

  factory FileFilter.fromJson(Map<String, dynamic> json) =>
      _$FileFilterFromJson(json);
}

extension FileFilterHelpers on FileFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (fileName != null) return true;
    if (fileExtension != null) return true;
    if (mimeType != null) return true;
    if (minFileSize != null || maxFileSize != null) return true;
    if (availabilityStatus != null) return true;
    if (integrityStatus != null) return true;
    if (missingDetectedAfter != null) return true;
    if (deletedAfter != null) return true;
    if (lastIntegrityCheckAfter != null || lastIntegrityCheckBefore != null) {
      return true;
    }
    if (hasSha256 != null) return true;
    return false;
  }
}
