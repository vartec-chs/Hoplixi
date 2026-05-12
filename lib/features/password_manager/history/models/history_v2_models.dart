import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/main_db/core/old/models/enums/index.dart';

const int kHistoryPageSize = 20;

enum HistoryActionFilter { all, modified, deleted }

enum HistoryDatePreset { all, last7Days, last30Days }

enum HistoryCompareTargetKind { newerRevision, currentLive, deletedState }

enum HistoryFieldChangeType { added, removed, changed }

class HistoryScope {
  const HistoryScope({required this.entityType, required this.entityId});

  final EntityType entityType;
  final String entityId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HistoryScope &&
            other.entityType == entityType &&
            other.entityId == entityId;
  }

  @override
  int get hashCode => Object.hash(entityType, entityId);
}

class HistoryQueryState {
  const HistoryQueryState({
    required this.entityType,
    required this.entityId,
    this.search = '',
    this.actionFilter = HistoryActionFilter.all,
    this.datePreset = HistoryDatePreset.all,
    this.page = 1,
    this.pageSize = kHistoryPageSize,
  });

  final EntityType entityType;
  final String entityId;
  final String search;
  final HistoryActionFilter actionFilter;
  final HistoryDatePreset datePreset;
  final int page;
  final int pageSize;

  bool get hasActiveFilters =>
      search.trim().isNotEmpty ||
      actionFilter != HistoryActionFilter.all ||
      datePreset != HistoryDatePreset.all;

  HistoryQueryState copyWith({
    String? search,
    HistoryActionFilter? actionFilter,
    HistoryDatePreset? datePreset,
    int? page,
    int? pageSize,
    bool resetPage = false,
  }) {
    return HistoryQueryState(
      entityType: entityType,
      entityId: entityId,
      search: search ?? this.search,
      actionFilter: actionFilter ?? this.actionFilter,
      datePreset: datePreset ?? this.datePreset,
      page: resetPage ? 1 : page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class HistoryCustomFieldValue {
  const HistoryCustomFieldValue({
    required this.key,
    required this.label,
    required this.value,
    required this.fieldType,
    required this.sortOrder,
  });

  final String key;
  final String label;
  final String? value;
  final CustomFieldType fieldType;
  final int sortOrder;
}

class HistoryTimelineItem {
  const HistoryTimelineItem({
    required this.revisionId,
    required this.originalEntityId,
    required this.action,
    required this.title,
    required this.subtitle,
    required this.actionAt,
    required this.changedFieldsCount,
    required this.changedFieldLabels,
    required this.isRestorable,
    required this.restoreWarnings,
  });

  final String revisionId;
  final String originalEntityId;
  final String action;
  final String title;
  final String? subtitle;
  final DateTime actionAt;
  final int changedFieldsCount;
  final List<String> changedFieldLabels;
  final bool isRestorable;
  final List<String> restoreWarnings;
}

class HistoryFieldDiff {
  const HistoryFieldDiff({
    required this.fieldKey,
    required this.label,
    required this.oldValue,
    required this.newValue,
    required this.changeType,
    required this.isSensitive,
  });

  final String fieldKey;
  final String label;
  final String? oldValue;
  final String? newValue;
  final HistoryFieldChangeType changeType;
  final bool isSensitive;
}

class HistoryRevisionDetail {
  const HistoryRevisionDetail({
    required this.revisionId,
    required this.snapshotTitle,
    required this.snapshotSubtitle,
    required this.action,
    required this.actionAt,
    required this.compareTargetKind,
    required this.fieldDiffs,
    required this.customFieldDiffs,
    required this.metadata,
    required this.restoreWarnings,
    required this.isRestorable,
  });

  final String revisionId;
  final String snapshotTitle;
  final String? snapshotSubtitle;
  final String action;
  final DateTime actionAt;
  final HistoryCompareTargetKind compareTargetKind;
  final List<HistoryFieldDiff> fieldDiffs;
  final List<HistoryFieldDiff> customFieldDiffs;
  final Map<String, String?> metadata;
  final List<String> restoreWarnings;
  final bool isRestorable;
}

class HistoryScreenState {
  const HistoryScreenState({
    required this.query,
    required this.timelineItems,
    required this.totalCount,
    required this.selectedRevisionId,
    required this.selectedDetail,
    required this.isRefreshing,
    required this.isRestoring,
    required this.canLoadMore,
    required this.hasLiveEntity,
    this.error,
  });

  final HistoryQueryState query;
  final List<HistoryTimelineItem> timelineItems;
  final int totalCount;
  final String? selectedRevisionId;
  final HistoryRevisionDetail? selectedDetail;
  final bool isRefreshing;
  final bool isRestoring;
  final bool canLoadMore;
  final bool hasLiveEntity;
  final String? error;

  bool get isEmpty => timelineItems.isEmpty;

  HistoryScreenState copyWith({
    HistoryQueryState? query,
    List<HistoryTimelineItem>? timelineItems,
    int? totalCount,
    Object? selectedRevisionId = _sentinel,
    Object? selectedDetail = _sentinel,
    bool? isRefreshing,
    bool? isRestoring,
    bool? canLoadMore,
    bool? hasLiveEntity,
    Object? error = _sentinel,
  }) {
    return HistoryScreenState(
      query: query ?? this.query,
      timelineItems: timelineItems ?? this.timelineItems,
      totalCount: totalCount ?? this.totalCount,
      selectedRevisionId: identical(selectedRevisionId, _sentinel)
          ? this.selectedRevisionId
          : selectedRevisionId as String?,
      selectedDetail: identical(selectedDetail, _sentinel)
          ? this.selectedDetail
          : selectedDetail as HistoryRevisionDetail?,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isRestoring: isRestoring ?? this.isRestoring,
      canLoadMore: canLoadMore ?? this.canLoadMore,
      hasLiveEntity: hasLiveEntity ?? this.hasLiveEntity,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}
