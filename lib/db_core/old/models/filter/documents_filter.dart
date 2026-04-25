import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_filter.dart';

part 'documents_filter.freezed.dart';
part 'documents_filter.g.dart';

enum DocumentsSortField {
  title,
  documentType,
  pageCount,
  createdAt,
  modifiedAt,
  lastUsedAt,
}

@freezed
abstract class DocumentsFilter with _$DocumentsFilter {
  const factory DocumentsFilter({
    required BaseFilter base,
    @Default(<String>[]) List<String> documentTypes,
    int? minPageCount,
    int? maxPageCount,
    String? titleQuery,
    String? descriptionQuery,
    String? aggregatedTextQuery,
    DocumentsSortField? sortField,
  }) = _DocumentsFilter;

  factory DocumentsFilter.create({
    BaseFilter? base,
    List<String>? documentTypes,
    int? minPageCount,
    int? maxPageCount,
    String? titleQuery,
    String? descriptionQuery,
    String? aggregatedTextQuery,
    DocumentsSortField? sortField,
  }) {
    final normalizedTitleQuery = titleQuery?.trim();
    final normalizedDescriptionQuery = descriptionQuery?.trim();
    final normalizedAggregatedTextQuery = aggregatedTextQuery?.trim();
    final normalizedDocumentTypes = (documentTypes ?? <String>[])
        .map((type) => type.trim().toLowerCase())
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList();

    return DocumentsFilter(
      base: base ?? const BaseFilter(),
      documentTypes: normalizedDocumentTypes,
      minPageCount: minPageCount,
      maxPageCount: maxPageCount,
      titleQuery: normalizedTitleQuery?.isEmpty == true
          ? null
          : normalizedTitleQuery,
      descriptionQuery: normalizedDescriptionQuery?.isEmpty == true
          ? null
          : normalizedDescriptionQuery,
      aggregatedTextQuery: normalizedAggregatedTextQuery?.isEmpty == true
          ? null
          : normalizedAggregatedTextQuery,
      sortField: sortField,
    );
  }

  factory DocumentsFilter.fromJson(Map<String, dynamic> json) =>
      _$DocumentsFilterFromJson(json);
}

extension DocumentsFilterHelpers on DocumentsFilter {
  /// Проверяет наличие активных ограничений фильтра
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (documentTypes.isNotEmpty) return true;
    if (minPageCount != null) return true;
    if (maxPageCount != null) return true;
    if (titleQuery != null) return true;
    if (descriptionQuery != null) return true;
    if (aggregatedTextQuery != null) return true;
    return false;
  }

  /// Проверка валидности диапазона страниц
  bool get isValidPageCountRange {
    if (minPageCount != null && maxPageCount != null) {
      return minPageCount! >= 0 && maxPageCount! >= minPageCount!;
    }
    if (minPageCount != null) {
      return minPageCount! >= 0;
    }
    if (maxPageCount != null) {
      return maxPageCount! >= 0;
    }
    return true;
  }
}
