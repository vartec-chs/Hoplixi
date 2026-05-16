import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_filter.dart';

part 'note_filter.freezed.dart';
part 'note_filter.g.dart';

enum NoteSortField {
  name,
  createdAt,
  modifiedAt,
  lastUsedAt,
  usedCount,
  recentScore,
}

@freezed
sealed class NoteFilter with _$NoteFilter {
  const factory NoteFilter({
    @Default(BaseFilter()) BaseFilter base,

    String? name,
    String? contentQuery,
    bool? hasContent,

    NoteSortField? sortField,
  }) = _NoteFilter;

  factory NoteFilter.create({
    BaseFilter? base,
    String? name,
    String? contentQuery,
    bool? hasContent,
    NoteSortField? sortField,
  }) {
    final normalizedName = name?.trim();
    final normalizedContentQuery = contentQuery?.trim();

    return NoteFilter(
      base: base ?? const BaseFilter(),
      name: normalizedName?.isEmpty == true ? null : normalizedName,
      contentQuery: normalizedContentQuery?.isEmpty == true ? null : normalizedContentQuery,
      hasContent: hasContent,
      sortField: sortField,
    );
  }

  factory NoteFilter.fromJson(Map<String, dynamic> json) =>
      _$NoteFilterFromJson(json);
}

extension NoteFilterHelpers on NoteFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (name != null) return true;
    if (contentQuery != null) return true;
    if (hasContent != null) return true;
    return false;
  }
}
