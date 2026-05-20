import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../tables/tables.dart';
import '../sort.dart';

part 'vault_snapshot_history_filter.freezed.dart';
part 'vault_snapshot_history_filter.g.dart';

enum SnapshotHistorySortBy {
  historyCreatedAt,
  createdAt,
  modifiedAt,
  lastUsedAt,
  archivedAt,
  deletedAt,
  name,
  usedCount,
  recentScore,
}

@freezed
sealed class VaultSnapshotHistoryFilter with _$VaultSnapshotHistoryFilter {
  const factory VaultSnapshotHistoryFilter({
    /// Поиск по name / description.
    @Default('') String query,

    /// Конкретный vault item.
    String? itemId,

    /// Несколько itemId, если надо получить историю пачкой.
    @Default(<String>[]) List<String> itemIds,

    /// Тип сущности: password, otp, note и т.д.
    @Default(<VaultItemType>[]) List<VaultItemType> types,

    /// Действия, из-за которых был создан snapshot.
    @Default(<VaultEventHistoryAction>[]) List<VaultEventHistoryAction> actions,

    /// Категория на момент snapshot.
    @Default(<String>[]) List<String> categoryIds,

    /// Snapshot категории.
    @Default(<String>[]) List<String> categoryHistoryIds,

    /// Состояния item на момент snapshot.
    bool? isFavorite,
    bool? isArchived,
    bool? isDeleted,
    bool? isPinned,

    /// Фильтр по времени создания исходного item.
    DateTime? createdAfter,
    DateTime? createdBefore,

    /// Фильтр по времени изменения исходного item.
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,

    /// Фильтр по времени последнего использования.
    DateTime? lastUsedAfter,
    DateTime? lastUsedBefore,

    /// Фильтр по времени архивации.
    DateTime? archivedAfter,
    DateTime? archivedBefore,

    /// Фильтр по времени мягкого удаления.
    DateTime? deletedAfter,
    DateTime? deletedBefore,

    /// Фильтр по времени создания самой history-записи.
    DateTime? historyCreatedAfter,
    DateTime? historyCreatedBefore,

    /// Использования на момент snapshot.
    int? minUsedCount,
    int? maxUsedCount,

    /// EWMA/recentScore на момент snapshot.
    double? minRecentScore,
    double? maxRecentScore,

    @Default(SortDirection.desc) SortDirection sortDirection,
    @Default(SnapshotHistorySortBy.historyCreatedAt)
    SnapshotHistorySortBy sortBy,

    int? limit,
    @Default(0) int offset,
  }) = _VaultSnapshotHistoryFilter;

  factory VaultSnapshotHistoryFilter.create({
    String? query,
    String? itemId,
    List<String>? itemIds,
    List<VaultItemType>? types,
    List<VaultEventHistoryAction>? actions,
    List<String>? categoryIds,
    List<String>? categoryHistoryIds,
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
    DateTime? archivedAfter,
    DateTime? archivedBefore,
    DateTime? deletedAfter,
    DateTime? deletedBefore,
    DateTime? historyCreatedAfter,
    DateTime? historyCreatedBefore,
    int? minUsedCount,
    int? maxUsedCount,
    double? minRecentScore,
    double? maxRecentScore,
    SortDirection? sortDirection,
    SnapshotHistorySortBy? sortBy,
    int? limit,
    int? offset,
  }) {
    final normalizedQuery = (query ?? '').trim();
    final normalizedItemId = itemId?.trim();

    final normalizedItemIds = (itemIds ?? <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final normalizedCategoryIds = (categoryIds ?? <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final normalizedCategoryHistoryIds = (categoryHistoryIds ?? <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    return VaultSnapshotHistoryFilter(
      query: normalizedQuery,
      itemId: normalizedItemId == null || normalizedItemId.isEmpty
          ? null
          : normalizedItemId,
      itemIds: normalizedItemIds,
      types: (types ?? <VaultItemType>[]).toSet().toList(),
      actions: (actions ?? <VaultEventHistoryAction>[]).toSet().toList(),
      categoryIds: normalizedCategoryIds,
      categoryHistoryIds: normalizedCategoryHistoryIds,
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
      archivedAfter: archivedAfter,
      archivedBefore: archivedBefore,
      deletedAfter: deletedAfter,
      deletedBefore: deletedBefore,
      historyCreatedAfter: historyCreatedAfter,
      historyCreatedBefore: historyCreatedBefore,
      minUsedCount: minUsedCount,
      maxUsedCount: maxUsedCount,
      minRecentScore: minRecentScore,
      maxRecentScore: maxRecentScore,
      sortDirection: sortDirection ?? SortDirection.desc,
      sortBy: sortBy ?? SnapshotHistorySortBy.historyCreatedAt,
      limit: limit,
      offset: offset ?? 0,
    );
  }

  factory VaultSnapshotHistoryFilter.fromJson(Map<String, dynamic> json) =>
      _$VaultSnapshotHistoryFilterFromJson(json);
}

extension VaultSnapshotHistoryFilterHelpers on VaultSnapshotHistoryFilter {
  bool get hasActiveConstraints {
    if (query.isNotEmpty) return true;
    if (itemId != null) return true;
    if (itemIds.isNotEmpty) return true;
    if (types.isNotEmpty) return true;
    if (actions.isNotEmpty) return true;
    if (categoryIds.isNotEmpty) return true;
    if (categoryHistoryIds.isNotEmpty) return true;

    if (isFavorite != null) return true;
    if (isArchived != null) return true;
    if (isDeleted != null) return true;
    if (isPinned != null) return true;

    if (createdAfter != null || createdBefore != null) return true;
    if (modifiedAfter != null || modifiedBefore != null) return true;
    if (lastUsedAfter != null || lastUsedBefore != null) return true;
    if (archivedAfter != null || archivedBefore != null) return true;
    if (deletedAfter != null || deletedBefore != null) return true;
    if (historyCreatedAfter != null || historyCreatedBefore != null) {
      return true;
    }

    if (minUsedCount != null || maxUsedCount != null) return true;
    if (minRecentScore != null || maxRecentScore != null) return true;

    return false;
  }
}
