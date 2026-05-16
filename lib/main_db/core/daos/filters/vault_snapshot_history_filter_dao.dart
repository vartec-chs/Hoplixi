import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../models/filters/filters.dart';
import '../../tables/vault_items/vault_events_history.dart';
import '../../tables/vault_items/vault_items.dart';
import '../../tables/vault_items/vault_snapshots_history.dart';
import 'filter_dao.dart';

part 'vault_snapshot_history_filter_dao.g.dart';

@DriftAccessor(tables: [VaultSnapshotsHistory])
class VaultSnapshotHistoryFilterDao extends DatabaseAccessor<MainStore>
    with _$VaultSnapshotHistoryFilterDaoMixin
    implements FilterDao<VaultSnapshotHistoryFilter, VaultSnapshotHistoryData> {
  VaultSnapshotHistoryFilterDao(super.db);

  @override
  Future<List<VaultSnapshotHistoryData>> getFiltered(
    VaultSnapshotHistoryFilter filter,
  ) {
    final whereExpr = _buildWhere(filter);
    final mode = filter.sortDirection == SortDirection.asc
        ? OrderingMode.asc
        : OrderingMode.desc;

    final query = select(vaultSnapshotsHistory)
      ..where((_) => whereExpr)
      ..orderBy([
        (t) => switch (filter.sortBy) {
          SnapshotHistorySortBy.historyCreatedAt => OrderingTerm(
            expression: t.historyCreatedAt,
            mode: mode,
          ),
          SnapshotHistorySortBy.createdAt => OrderingTerm(
            expression: t.createdAt,
            mode: mode,
          ),
          SnapshotHistorySortBy.modifiedAt => OrderingTerm(
            expression: t.modifiedAt,
            mode: mode,
          ),
          SnapshotHistorySortBy.lastUsedAt => OrderingTerm(
            expression: t.lastUsedAt,
            mode: mode,
          ),
          SnapshotHistorySortBy.archivedAt => OrderingTerm(
            expression: t.archivedAt,
            mode: mode,
          ),
          SnapshotHistorySortBy.deletedAt => OrderingTerm(
            expression: t.deletedAt,
            mode: mode,
          ),
          SnapshotHistorySortBy.name => OrderingTerm(
            expression: t.name,
            mode: mode,
          ),
          SnapshotHistorySortBy.usedCount => OrderingTerm(
            expression: t.usedCount,
            mode: mode,
          ),
          SnapshotHistorySortBy.recentScore => OrderingTerm(
            expression: t.recentScore,
            mode: mode,
          ),
        },
      ]);

    if (filter.limit != null && filter.limit! > 0) {
      query.limit(filter.limit!, offset: filter.offset);
    }

    return query.get();
  }

  @override
  Future<int> countFiltered(VaultSnapshotHistoryFilter filter) async {
    final countExp = countAll();
    final query = selectOnly(vaultSnapshotsHistory)
      ..addColumns([countExp])
      ..where(_buildWhere(filter));

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Expression<bool> _buildWhere(VaultSnapshotHistoryFilter filter) {
    Expression<bool> whereExpr = const Constant(true);

    if (filter.query.isNotEmpty) {
      final query = '%${filter.query}%';
      whereExpr &=
          vaultSnapshotsHistory.name.like(query) |
          vaultSnapshotsHistory.description.like(query);
    }

    if (filter.itemId != null) {
      whereExpr &= vaultSnapshotsHistory.itemId.equals(filter.itemId!);
    }
    if (filter.itemIds.isNotEmpty) {
      whereExpr &= vaultSnapshotsHistory.itemId.isIn(filter.itemIds);
    }
    if (filter.types.isNotEmpty) {
      whereExpr &= _matchesAnyType(filter.types);
    }
    if (filter.actions.isNotEmpty) {
      whereExpr &= _matchesAnyAction(filter.actions);
    }
    if (filter.categoryIds.isNotEmpty) {
      whereExpr &= vaultSnapshotsHistory.categoryId.isIn(filter.categoryIds);
    }
    if (filter.categoryHistoryIds.isNotEmpty) {
      whereExpr &= vaultSnapshotsHistory.categoryHistoryId.isIn(
        filter.categoryHistoryIds,
      );
    }

    if (filter.isFavorite != null) {
      whereExpr &= vaultSnapshotsHistory.isFavorite.equals(filter.isFavorite!);
    }
    if (filter.isArchived != null) {
      whereExpr &= vaultSnapshotsHistory.isArchived.equals(filter.isArchived!);
    }
    if (filter.isDeleted != null) {
      whereExpr &= vaultSnapshotsHistory.isDeleted.equals(filter.isDeleted!);
    }
    if (filter.isPinned != null) {
      whereExpr &= vaultSnapshotsHistory.isPinned.equals(filter.isPinned!);
    }

    if (filter.createdAfter != null) {
      whereExpr &= vaultSnapshotsHistory.createdAt.isBiggerOrEqualValue(
        filter.createdAfter!,
      );
    }
    if (filter.createdBefore != null) {
      whereExpr &= vaultSnapshotsHistory.createdAt.isSmallerOrEqualValue(
        filter.createdBefore!,
      );
    }
    if (filter.modifiedAfter != null) {
      whereExpr &= vaultSnapshotsHistory.modifiedAt.isBiggerOrEqualValue(
        filter.modifiedAfter!,
      );
    }
    if (filter.modifiedBefore != null) {
      whereExpr &= vaultSnapshotsHistory.modifiedAt.isSmallerOrEqualValue(
        filter.modifiedBefore!,
      );
    }
    if (filter.lastUsedAfter != null) {
      whereExpr &= vaultSnapshotsHistory.lastUsedAt.isBiggerOrEqualValue(
        filter.lastUsedAfter!,
      );
    }
    if (filter.lastUsedBefore != null) {
      whereExpr &= vaultSnapshotsHistory.lastUsedAt.isSmallerOrEqualValue(
        filter.lastUsedBefore!,
      );
    }
    if (filter.archivedAfter != null) {
      whereExpr &= vaultSnapshotsHistory.archivedAt.isBiggerOrEqualValue(
        filter.archivedAfter!,
      );
    }
    if (filter.archivedBefore != null) {
      whereExpr &= vaultSnapshotsHistory.archivedAt.isSmallerOrEqualValue(
        filter.archivedBefore!,
      );
    }
    if (filter.deletedAfter != null) {
      whereExpr &= vaultSnapshotsHistory.deletedAt.isBiggerOrEqualValue(
        filter.deletedAfter!,
      );
    }
    if (filter.deletedBefore != null) {
      whereExpr &= vaultSnapshotsHistory.deletedAt.isSmallerOrEqualValue(
        filter.deletedBefore!,
      );
    }
    if (filter.historyCreatedAfter != null) {
      whereExpr &= vaultSnapshotsHistory.historyCreatedAt.isBiggerOrEqualValue(
        filter.historyCreatedAfter!,
      );
    }
    if (filter.historyCreatedBefore != null) {
      whereExpr &= vaultSnapshotsHistory.historyCreatedAt.isSmallerOrEqualValue(
        filter.historyCreatedBefore!,
      );
    }

    if (filter.minUsedCount != null) {
      whereExpr &= vaultSnapshotsHistory.usedCount.isBiggerOrEqualValue(
        filter.minUsedCount!,
      );
    }
    if (filter.maxUsedCount != null) {
      whereExpr &= vaultSnapshotsHistory.usedCount.isSmallerOrEqualValue(
        filter.maxUsedCount!,
      );
    }
    if (filter.minRecentScore != null) {
      whereExpr &= vaultSnapshotsHistory.recentScore.isBiggerOrEqualValue(
        filter.minRecentScore!,
      );
    }
    if (filter.maxRecentScore != null) {
      whereExpr &= vaultSnapshotsHistory.recentScore.isSmallerOrEqualValue(
        filter.maxRecentScore!,
      );
    }

    return whereExpr;
  }

  Expression<bool> _matchesAnyAction(List<VaultEventHistoryAction> actions) {
    Expression<bool> expr = const Constant(false);
    for (final action in actions) {
      expr |= vaultSnapshotsHistory.action.equalsValue(action);
    }
    return expr;
  }

  Expression<bool> _matchesAnyType(List<VaultItemType> types) {
    Expression<bool> expr = const Constant(false);
    for (final type in types) {
      expr |= vaultSnapshotsHistory.type.equalsValue(type);
    }
    return expr;
  }
}
