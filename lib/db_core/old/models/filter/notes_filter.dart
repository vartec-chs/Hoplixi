import 'package:freezed_annotation/freezed_annotation.dart';
import 'base_filter.dart';

part 'notes_filter.freezed.dart';
part 'notes_filter.g.dart';

enum NotesSortField {
  title,
  description,
  contentLength,
  createdAt,
  modifiedAt,
  lastAccessed,
}

@freezed
abstract class NotesFilter with _$NotesFilter {
  const factory NotesFilter({
    required BaseFilter base,
    String? title,
    String? content,
    bool? hasDescription,
    bool? hasDeltaJson,
    int? minContentLength,
    int? maxContentLength,
    NotesSortField? sortField,
  }) = _NotesFilter;

  factory NotesFilter.create({
    BaseFilter? base,
    String? title,
    String? content,
    bool? hasDescription,
    bool? hasDeltaJson,
    int? minContentLength,
    int? maxContentLength,
    NotesSortField? sortField,
  }) {
    final normalizedTitle = title?.trim();
    final normalizedContent = content?.trim();

    return NotesFilter(
      base: base ?? const BaseFilter(),
      title: normalizedTitle?.isEmpty == true ? null : normalizedTitle,
      content: normalizedContent?.isEmpty == true ? null : normalizedContent,
      hasDescription: hasDescription,
      hasDeltaJson: hasDeltaJson,
      minContentLength: minContentLength,
      maxContentLength: maxContentLength,
      sortField: sortField,
    );
  }

  factory NotesFilter.fromJson(Map<String, dynamic> json) =>
      _$NotesFilterFromJson(json);
}

extension NotesFilterHelpers on NotesFilter {
  /// Проверяет наличие активных ограничений фильтра
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (title != null) return true;
    if (content != null) return true;
    if (hasDescription != null) return true;
    if (hasDeltaJson != null) return true;
    if (minContentLength != null) return true;
    if (maxContentLength != null) return true;
    return false;
  }

  /// Проверка валидности диапазона длины контента
  bool get isValidContentLengthRange {
    if (minContentLength != null && maxContentLength != null) {
      return minContentLength! >= 0 && maxContentLength! >= minContentLength!;
    }
    if (minContentLength != null) {
      return minContentLength! >= 0;
    }
    if (maxContentLength != null) {
      return maxContentLength! >= 0;
    }
    return true;
  }
}
