import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/history/models/history_v2_models.dart';
import 'package:hoplixi/vault_db/core/models/dto_history/cards/cards_exports.dart'
    as history_dto;
import 'package:hoplixi/vault_db/core/models/filters/history/vault_snapshot_history_filter.dart';
import 'package:hoplixi/vault_db/core/models/filters/sort.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart'
    as vault_schema;
import 'package:hoplixi/vault_db/core/services/history/facades/vault_history_timeline_service.dart';
import 'package:hoplixi/vault_db/core/services/history/models/vault_history_timeline_diff_mode.dart';
import 'package:hoplixi/vault_db/core/services/history/vault_history_service_assembly.dart';

class HistoryRepository {
  HistoryRepository(this.historyAssembly)
    : _timelineService = VaultHistoryTimelineService(
        readService: historyAssembly.readService,
        detailService: historyAssembly.detailService,
        restorePolicyService: historyAssembly.restorePolicy,
      );

  final VaultHistoryServiceAssembly historyAssembly;
  final VaultHistoryTimelineService _timelineService;

  Future<_HistoryLoadResult> loadHistory(HistoryQueryState query) async {
    final vaultType = _toVaultItemType(query.entityType);
    final filter = _filterFor(query, limit: query.page * query.pageSize);
    final countFilter = _filterFor(query);

    final timelineItems = (await _timelineService.getTimeline(
      filter,
      diffMode: VaultHistoryTimelineDiffMode.full,
    )).getOrThrow().map(_mapTimelineItem).toList();

    final totalCount = (await historyAssembly.db.vaultSnapshotHistoryFilterDao
        .countFiltered(countFilter));

    final current = (await historyAssembly.loader.loadCurrentSnapshot(
      itemId: query.entityId,
      type: vaultType,
    )).getOrThrow().getOrNull();

    return _HistoryLoadResult(
      timelineItems: timelineItems,
      totalCount: totalCount,
      canLoadMore: timelineItems.length < totalCount,
      hasLiveEntity: current != null,
    );
  }

  Future<HistoryRevisionDetail?> buildDetail({
    required EntityType entityType,
    required String revisionId,
  }) async {
    final detail = (await historyAssembly.detailService.getRevisionDetail(
      historyId: revisionId,
    )).getOrThrow();

    return _mapRevisionDetail(detail);
  }

  Future<void> restoreRevision({
    required EntityType entityType,
    required String revisionId,
  }) async {
    final current = (await historyAssembly.loader.loadCurrentSnapshot(
      itemId: await _itemIdForRevision(revisionId),
      type: _toVaultItemType(entityType),
    )).getOrThrow().getOrNull();

    (await historyAssembly.restoreService.restoreRevision(
      historyId: revisionId,
      recreate: current == null,
    )).getOrThrow();
  }

  Future<bool> deleteRevision({
    required EntityType entityType,
    required String revisionId,
  }) async {
    (await historyAssembly.deleteService.deleteRevision(
      revisionId,
    )).getOrThrow();
    return true;
  }

  Future<bool> clearAllHistory({
    required EntityType entityType,
    required String entityId,
  }) async {
    (await historyAssembly.deleteService.clearItemHistory(
      itemId: entityId,
      type: _toVaultItemType(entityType),
    )).getOrThrow();
    return true;
  }

  VaultSnapshotHistoryFilter _filterFor(HistoryQueryState query, {int? limit}) {
    return VaultSnapshotHistoryFilter.create(
      itemId: query.entityId,
      types: [_toVaultItemType(query.entityType)],
      actions: _actionsFor(query.actionFilter),
      query: query.search,
      historyCreatedAfter: _historyCreatedAfter(query.datePreset),
      sortBy: SnapshotHistorySortBy.historyCreatedAt,
      sortDirection: SortDirection.desc,
      limit: limit,
      offset: 0,
    );
  }

  HistoryTimelineItem _mapTimelineItem(
    history_dto.VaultHistoryTimelineItemDto item,
  ) {
    return HistoryTimelineItem(
      revisionId: item.historyId,
      originalEntityId: item.itemId,
      action: _actionId(item.action),
      title: item.title,
      subtitle: item.subtitle,
      actionAt: item.actionAt,
      changedFieldsCount: item.changedFieldsCount,
      changedFieldLabels: item.changedFieldLabels,
      isRestorable: item.isRestorable,
      restoreWarnings: item.restoreWarnings,
    );
  }

  HistoryRevisionDetail _mapRevisionDetail(
    history_dto.VaultHistoryRevisionDetailDto detail,
  ) {
    final selected = detail.selected;
    return HistoryRevisionDetail(
      revisionId: selected.historyId,
      snapshotTitle: selected.name,
      snapshotSubtitle: selected.description,
      action: _actionId(selected.action),
      actionAt: selected.historyCreatedAt,
      compareTargetKind: _compareTargetKind(detail.compareTargetKind),
      fieldDiffs: detail.fieldDiffs.map(_mapFieldDiff).toList(),
      customFieldDiffs: detail.customFieldDiffs.map(_mapFieldDiff).toList(),
      metadata: {
        'itemId': selected.itemId,
        'type': selected.type.name,
        'categoryId': selected.categoryId,
        'createdAt': selected.createdAt.toIso8601String(),
        'modifiedAt': selected.modifiedAt.toIso8601String(),
      },
      restoreWarnings: detail.restoreWarnings,
      isRestorable: detail.isRestorable,
    );
  }

  HistoryFieldDiff _mapFieldDiff(history_dto.VaultHistoryFieldDiffDto diff) {
    return HistoryFieldDiff(
      fieldKey: diff.fieldKey,
      label: diff.label,
      oldValue: _normalizeValue(diff.oldValue),
      newValue: _normalizeValue(diff.newValue),
      changeType: _fieldChangeType(diff.changeType),
      isSensitive: diff.isSensitive,
    );
  }

  Future<String> _itemIdForRevision(String revisionId) async {
    final snapshot = await historyAssembly.db.vaultSnapshotsHistoryDao
        .getSnapshotById(revisionId);
    if (snapshot == null) {
      throw StateError('History revision not found.');
    }
    return snapshot.itemId;
  }
}

class _HistoryLoadResult {
  const _HistoryLoadResult({
    required this.timelineItems,
    required this.totalCount,
    required this.canLoadMore,
    required this.hasLiveEntity,
  });

  final List<HistoryTimelineItem> timelineItems;
  final int totalCount;
  final bool canLoadMore;
  final bool hasLiveEntity;
}

vault_schema.VaultItemType _toVaultItemType(EntityType type) {
  return switch (type) {
    EntityType.password => vault_schema.VaultItemType.password,
    EntityType.note => vault_schema.VaultItemType.note,
    EntityType.bankCard => vault_schema.VaultItemType.bankCard,
    EntityType.file => vault_schema.VaultItemType.file,
    EntityType.otp => vault_schema.VaultItemType.otp,
    EntityType.document => vault_schema.VaultItemType.document,
    EntityType.contact => vault_schema.VaultItemType.contact,
    EntityType.apiKey => vault_schema.VaultItemType.apiKey,
    EntityType.sshKey => vault_schema.VaultItemType.sshKey,
    EntityType.certificate => vault_schema.VaultItemType.certificate,
    EntityType.cryptoWallet => vault_schema.VaultItemType.cryptoWallet,
    EntityType.wifi => vault_schema.VaultItemType.wifi,
    EntityType.identity => vault_schema.VaultItemType.identity,
    EntityType.licenseKey => vault_schema.VaultItemType.licenseKey,
    EntityType.recoveryCodes => vault_schema.VaultItemType.recoveryCodes,
    EntityType.loyaltyCard => vault_schema.VaultItemType.loyaltyCard,
  };
}

List<VaultEventHistoryAction>? _actionsFor(HistoryActionFilter filter) {
  return switch (filter) {
    HistoryActionFilter.all => null,
    HistoryActionFilter.deleted => const [VaultEventHistoryAction.deleted],
    HistoryActionFilter.modified => const [
      VaultEventHistoryAction.updated,
      VaultEventHistoryAction.archived,
      VaultEventHistoryAction.restored,
      VaultEventHistoryAction.recovered,
      VaultEventHistoryAction.favorited,
      VaultEventHistoryAction.unfavorited,
      VaultEventHistoryAction.pinned,
      VaultEventHistoryAction.unpinned,
      VaultEventHistoryAction.movedToCategory,
      VaultEventHistoryAction.categoryRemoved,
      VaultEventHistoryAction.iconChanged,
      VaultEventHistoryAction.iconRemoved,
      VaultEventHistoryAction.customFieldAdded,
      VaultEventHistoryAction.customFieldUpdated,
      VaultEventHistoryAction.customFieldDeleted,
      VaultEventHistoryAction.customFieldReordered,
    ],
  };
}

DateTime? _historyCreatedAfter(HistoryDatePreset preset) {
  final now = DateTime.now();
  return switch (preset) {
    HistoryDatePreset.all => null,
    HistoryDatePreset.last7Days => now.subtract(const Duration(days: 7)),
    HistoryDatePreset.last30Days => now.subtract(const Duration(days: 30)),
  };
}

String _actionId(VaultEventHistoryAction action) {
  return switch (action) {
    VaultEventHistoryAction.created => 'created',
    VaultEventHistoryAction.deleted => 'deleted',
    _ => 'modified',
  };
}

HistoryCompareTargetKind _compareTargetKind(
  history_dto.HistoryCompareTargetKind kind,
) {
  return switch (kind) {
    history_dto.HistoryCompareTargetKind.newerRevision =>
      HistoryCompareTargetKind.newerRevision,
    history_dto.HistoryCompareTargetKind.currentLive =>
      HistoryCompareTargetKind.currentLive,
    history_dto.HistoryCompareTargetKind.deletedState =>
      HistoryCompareTargetKind.deletedState,
  };
}

HistoryFieldChangeType _fieldChangeType(
  history_dto.HistoryFieldChangeType type,
) {
  return switch (type) {
    history_dto.HistoryFieldChangeType.added => HistoryFieldChangeType.added,
    history_dto.HistoryFieldChangeType.removed =>
      HistoryFieldChangeType.removed,
    history_dto.HistoryFieldChangeType.changed =>
      HistoryFieldChangeType.changed,
  };
}

String? _normalizeValue(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  if (value is Iterable) return value.join(', ');
  return value.toString();
}
