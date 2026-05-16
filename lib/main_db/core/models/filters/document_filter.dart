import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/document/document_types.dart';
import 'base_filter.dart';

part 'document_filter.freezed.dart';
part 'document_filter.g.dart';

enum DocumentSortField {
  name,
  createdAt,
  modifiedAt,
  lastUsedAt,
  usedCount,
  recentScore,
}

@freezed
sealed class DocumentFilter with _$DocumentFilter {
  const factory DocumentFilter({
    @Default(BaseFilter()) BaseFilter base,

    bool? hasCurrentVersion,
    DocumentType? documentType,
    int? versionNumber,

    int? minPageCount,
    int? maxPageCount,

    bool? hasAggregateHash,

    DocumentSortField? sortField,
  }) = _DocumentFilter;

  factory DocumentFilter.create({
    BaseFilter? base,
    bool? hasCurrentVersion,
    DocumentType? documentType,
    int? versionNumber,
    int? minPageCount,
    int? maxPageCount,
    bool? hasAggregateHash,
    DocumentSortField? sortField,
  }) {
    return DocumentFilter(
      base: base ?? const BaseFilter(),
      hasCurrentVersion: hasCurrentVersion,
      documentType: documentType,
      versionNumber: versionNumber,
      minPageCount: minPageCount,
      maxPageCount: maxPageCount,
      hasAggregateHash: hasAggregateHash,
      sortField: sortField,
    );
  }

  factory DocumentFilter.fromJson(Map<String, dynamic> json) =>
      _$DocumentFilterFromJson(json);
}

extension DocumentFilterHelpers on DocumentFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (hasCurrentVersion != null) return true;
    if (documentType != null) return true;
    if (versionNumber != null) return true;
    if (minPageCount != null || maxPageCount != null) return true;
    if (hasAggregateHash != null) return true;
    return false;
  }
}
