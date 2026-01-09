import 'package:freezed_annotation/freezed_annotation.dart';

part 'base_filter.freezed.dart';
part 'base_filter.g.dart';

enum SortDirection { asc, desc }

enum SortBy { createdAt, modifiedAt, lastUsedAt, recentScore }

@freezed
sealed class BaseFilter with _$BaseFilter {
  const factory BaseFilter({
    @Default('') String query,
    @Default(<String>[]) List<String> categoryIds,
    @Default(<String>[]) List<String> noteIds,
    @Default(<String>[]) List<String> tagIds,
    bool? isFavorite,
    bool? isArchived,
    bool? isDeleted,
    bool? isFrequentlyUsed,
    int? frequencyWindowDays,
    bool? isPinned,
    bool? hasNotes,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    @Default(SortDirection.desc) SortDirection sortDirection,
    @Default(SortBy.createdAt) SortBy sortBy,
    int? minUsedCount,
    int? maxUsedCount,
    DateTime? lastUsedAfter,
    DateTime? lastUsedBefore,

    @Default(0) int? limit,
    @Default(0) int? offset,
  }) = _BaseFilter;

  factory BaseFilter.create({
    String? query,
    List<String>? categoryIds,
    List<String>? noteIds,
    List<String>? tagIds,
    bool? isFavorite,
    bool? isArchived,
    bool? isDeleted,
    bool? isFrequentlyUsed,
    int? frequencyWindowDays,
    bool? isPinned,
    bool? hasNotes,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    DateTime? lastUsedAfter,
    DateTime? lastUsedBefore,
    int? minUsedCount,
    int? maxUsedCount,
    int? limit,
    int? offset,
    SortDirection? sortDirection,
    SortBy? sortBy,
  }) {
    final normalizedQuery = (query ?? '').trim();
    final normalizedCategoryIds = (categoryIds ?? <String>[])
        .where((s) => s.trim().isNotEmpty)
        .toSet()
        .toList();
    final normalizedTagIds = (tagIds ?? <String>[])
        .where((s) => s.trim().isNotEmpty)
        .toSet()
        .toList();
    final normalizedNoteIds = (noteIds ?? <String>[])
        .where((s) => s.trim().isNotEmpty)
        .toSet()
        .toList();

    return BaseFilter(
      query: normalizedQuery,
      categoryIds: normalizedCategoryIds,
      tagIds: normalizedTagIds,
      noteIds: normalizedNoteIds,
      isFavorite: isFavorite,
      isArchived: isArchived,
      isDeleted: isDeleted,
      isPinned: isPinned,
      isFrequentlyUsed: isFrequentlyUsed,
      frequencyWindowDays: frequencyWindowDays,
      hasNotes: hasNotes,
      createdAfter: createdAfter,
      createdBefore: createdBefore,
      modifiedAfter: modifiedAfter,
      modifiedBefore: modifiedBefore,
      lastUsedAfter: lastUsedAfter,
      lastUsedBefore: lastUsedBefore,
      minUsedCount: minUsedCount,
      maxUsedCount: maxUsedCount,
      limit: limit,
      offset: offset,
      sortDirection: sortDirection ?? SortDirection.desc,
      sortBy: sortBy ?? SortBy.createdAt,
    );
  }

  factory BaseFilter.fromJson(Map<String, dynamic> json) =>
      _$BaseFilterFromJson(json);
}

extension BaseFilterHelpers on BaseFilter {
  bool get hasActiveConstraints {
    if (query.isNotEmpty) return true;
    if (categoryIds.isNotEmpty) return true;
    if (tagIds.isNotEmpty) return true;
    if (noteIds.isNotEmpty) return true;
    if (isFavorite != null) return true;
    if (isArchived != null) return true;
    if (isFrequentlyUsed != null) return true;
    if (frequencyWindowDays != null) return true;
    if (isDeleted != null) return true;
    if (isPinned != null) return true;
    if (hasNotes != null) return true;
    if (createdAfter != null || createdBefore != null) return true;
    if (modifiedAfter != null || modifiedBefore != null) return true;
    if (lastUsedAfter != null || lastUsedBefore != null) return true;
    if (minUsedCount != null || maxUsedCount != null) return true;
    return false;
  }
}
