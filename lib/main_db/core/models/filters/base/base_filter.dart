import 'package:freezed_annotation/freezed_annotation.dart';

import '../sort.dart';

part 'base_filter.freezed.dart';
part 'base_filter.g.dart';

@freezed
sealed class BaseFilter with _$BaseFilter {
  const factory BaseFilter({
    @Default('') String query,

    @Default(<String>[]) List<String> categoryIds,
    @Default(<String>[]) List<String> tagIds,

    bool? isFavorite,
    bool? isArchived,
    bool? isDeleted,
    bool? isPinned,

    DateTime? createdAfter,
    DateTime? createdBefore,

    DateTime? modifiedAfter,
    DateTime? modifiedBefore,

    DateTime? lastUsedAfter,
    DateTime? lastUsedBefore,

    int? minUsedCount,
    int? maxUsedCount,

    bool? isFrequentlyUsed,
    int? frequencyWindowDays,

    @Default(SortDirection.desc) SortDirection sortDirection,
    @Default(BaseSortBy.modifiedAt) BaseSortBy sortBy,

    int? limit,
    @Default(0) int offset,
  }) = _BaseFilter;

  factory BaseFilter.create({
    String? query,
    List<String>? categoryIds,
    List<String>? tagIds,
    bool? isFavorite,
    bool? isArchived,
    bool? isDeleted,
    bool? isPinned,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    DateTime? lastUsedAfter,
    DateTime? lastUsedBefore,
    int? minUsedCount,
    int? maxUsedCount,
    bool? isFrequentlyUsed,
    int? frequencyWindowDays,
    SortDirection? sortDirection,
    BaseSortBy? sortBy,
    int? limit,
    int? offset,
  }) {
    final normalizedQuery = (query ?? '').trim();

    final normalizedCategoryIds = (categoryIds ?? <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final normalizedTagIds = (tagIds ?? <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    return BaseFilter(
      query: normalizedQuery,
      categoryIds: normalizedCategoryIds,
      tagIds: normalizedTagIds,
      isFavorite: isFavorite,
      isArchived: isArchived,
      isDeleted: isDeleted,
      isPinned: isPinned,
      createdAfter: createdAfter,
      createdBefore: createdBefore,
      modifiedAfter: modifiedAfter,
      modifiedBefore: modifiedBefore,
      lastUsedAfter: lastUsedAfter,
      lastUsedBefore: lastUsedBefore,
      minUsedCount: minUsedCount,
      maxUsedCount: maxUsedCount,
      isFrequentlyUsed: isFrequentlyUsed,
      frequencyWindowDays: frequencyWindowDays,
      sortDirection: sortDirection ?? SortDirection.desc,
      sortBy: sortBy ?? BaseSortBy.modifiedAt,
      limit: limit,
      offset: offset ?? 0,
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
    if (isFavorite != null) return true;
    if (isArchived != null) return true;
    if (isDeleted != null) return true;
    if (isPinned != null) return true;
    if (createdAfter != null || createdBefore != null) return true;
    if (modifiedAfter != null || modifiedBefore != null) return true;
    if (lastUsedAfter != null || lastUsedBefore != null) return true;
    if (minUsedCount != null || maxUsedCount != null) return true;
    if (isFrequentlyUsed != null) return true;
    if (frequencyWindowDays != null) return true;
    return false;
  }
}
