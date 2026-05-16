import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../tables/tables.dart';
import '../sort.dart';

part 'vault_event_history_filter.freezed.dart';
part 'vault_event_history_filter.g.dart';

enum EventHistorySortBy { eventCreatedAt, name, action, type, actorType }

@freezed
sealed class VaultEventHistoryFilter with _$VaultEventHistoryFilter {
  const factory VaultEventHistoryFilter({
    /// Поиск по name / description.
    @Default('') String query,

    /// Конкретный vault item.
    String? itemId,

    /// Несколько itemId.
    @Default(<String>[]) List<String> itemIds,

    /// Действия.
    @Default(<VaultEventHistoryAction>[]) List<VaultEventHistoryAction> actions,

    /// Типы сущностей.
    @Default(<VaultItemType>[]) List<VaultItemType> types,

    /// Источники событий: user, system, sync, import и т.д.
    @Default(<VaultHistoryActorType>[]) List<VaultHistoryActorType> actorTypes,

    /// Категория на момент события.
    @Default(<String>[]) List<String> categoryIds,

    /// Привязанные snapshot history.
    @Default(<String>[]) List<String> snapshotHistoryIds,

    /// Есть ли связанный snapshot.
    ///
    /// true  -> snapshot_history_id IS NOT NULL
    /// false -> snapshot_history_id IS NULL
    bool? hasSnapshot,

    /// Есть ли имя у события.
    ///
    /// Может пригодиться для технических событий.
    bool? hasName,

    /// Время создания event-записи.
    DateTime? eventCreatedAfter,
    DateTime? eventCreatedBefore,

    @Default(SortDirection.desc) SortDirection sortDirection,
    @Default(EventHistorySortBy.eventCreatedAt) EventHistorySortBy sortBy,

    int? limit,
    @Default(0) int offset,
  }) = _VaultEventHistoryFilter;

  factory VaultEventHistoryFilter.create({
    String? query,
    String? itemId,
    List<String>? itemIds,
    List<VaultEventHistoryAction>? actions,
    List<VaultItemType>? types,
    List<VaultHistoryActorType>? actorTypes,
    List<String>? categoryIds,
    List<String>? snapshotHistoryIds,
    bool? hasSnapshot,
    bool? hasName,
    DateTime? eventCreatedAfter,
    DateTime? eventCreatedBefore,
    SortDirection? sortDirection,
    EventHistorySortBy? sortBy,
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

    final normalizedSnapshotHistoryIds = (snapshotHistoryIds ?? <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    return VaultEventHistoryFilter(
      query: normalizedQuery,
      itemId: normalizedItemId == null || normalizedItemId.isEmpty
          ? null
          : normalizedItemId,
      itemIds: normalizedItemIds,
      actions: (actions ?? <VaultEventHistoryAction>[]).toSet().toList(),
      types: (types ?? <VaultItemType>[]).toSet().toList(),
      actorTypes: (actorTypes ?? <VaultHistoryActorType>[]).toSet().toList(),
      categoryIds: normalizedCategoryIds,
      snapshotHistoryIds: normalizedSnapshotHistoryIds,
      hasSnapshot: hasSnapshot,
      hasName: hasName,
      eventCreatedAfter: eventCreatedAfter,
      eventCreatedBefore: eventCreatedBefore,
      sortDirection: sortDirection ?? SortDirection.desc,
      sortBy: sortBy ?? EventHistorySortBy.eventCreatedAt,
      limit: limit,
      offset: offset ?? 0,
    );
  }

  factory VaultEventHistoryFilter.fromJson(Map<String, dynamic> json) =>
      _$VaultEventHistoryFilterFromJson(json);
}

extension VaultEventHistoryFilterHelpers on VaultEventHistoryFilter {
  bool get hasActiveConstraints {
    if (query.isNotEmpty) return true;
    if (itemId != null) return true;
    if (itemIds.isNotEmpty) return true;
    if (actions.isNotEmpty) return true;
    if (types.isNotEmpty) return true;
    if (actorTypes.isNotEmpty) return true;
    if (categoryIds.isNotEmpty) return true;
    if (snapshotHistoryIds.isNotEmpty) return true;
    if (hasSnapshot != null) return true;
    if (hasName != null) return true;
    if (eventCreatedAfter != null || eventCreatedBefore != null) return true;

    return false;
  }
}
