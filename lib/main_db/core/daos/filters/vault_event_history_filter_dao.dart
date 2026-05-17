import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../models/filters/filters.dart';
import '../../tables/vault_items/vault_events_history.dart';
import '../../tables/vault_items/vault_items.dart';
import 'filter_dao.dart';

part 'vault_event_history_filter_dao.g.dart';

@DriftAccessor(tables: [VaultEventsHistory])
class VaultEventHistoryFilterDao extends DatabaseAccessor<MainStore>
    with _$VaultEventHistoryFilterDaoMixin
    implements FilterDao<VaultEventHistoryFilter, VaultEventHistoryData> {
  VaultEventHistoryFilterDao(super.db);

  @override
  Future<List<VaultEventHistoryData>> getFiltered(
    VaultEventHistoryFilter filter,
  ) {
    final whereExpr = _buildWhere(filter);
    final mode = filter.sortDirection == SortDirection.asc
        ? OrderingMode.asc
        : OrderingMode.desc;

    final query = select(vaultEventsHistory)
      ..where((_) => whereExpr)
      ..orderBy([
        (t) => switch (filter.sortBy) {
          EventHistorySortBy.eventCreatedAt => OrderingTerm(
            expression: t.eventCreatedAt,
            mode: mode,
          ),
          EventHistorySortBy.name => OrderingTerm(
            expression: t.name,
            mode: mode,
          ),
          EventHistorySortBy.action => OrderingTerm(
            expression: t.action,
            mode: mode,
          ),
          EventHistorySortBy.type => OrderingTerm(
            expression: t.type,
            mode: mode,
          ),
          EventHistorySortBy.actorType => OrderingTerm(
            expression: t.actorType,
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
  Future<int> countFiltered(VaultEventHistoryFilter filter) async {
    final countExp = countAll();
    final query = selectOnly(vaultEventsHistory)
      ..addColumns([countExp])
      ..where(_buildWhere(filter));

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Expression<bool> _buildWhere(VaultEventHistoryFilter filter) {
    Expression<bool> whereExpr = const Constant(true);

    if (filter.query.isNotEmpty) {
      final query = '%${filter.query}%';
      whereExpr &=
          vaultEventsHistory.name.like(query) |
          vaultEventsHistory.description.like(query);
    }

    if (filter.itemId != null) {
      whereExpr &= vaultEventsHistory.itemId.equals(filter.itemId!);
    }
    if (filter.itemIds.isNotEmpty) {
      whereExpr &= vaultEventsHistory.itemId.isIn(filter.itemIds);
    }
    if (filter.actions.isNotEmpty) {
      whereExpr &= _matchesAnyAction(filter.actions);
    }
    if (filter.types.isNotEmpty) {
      whereExpr &= _matchesAnyType(filter.types);
    }
    if (filter.actorTypes.isNotEmpty) {
      whereExpr &= _matchesAnyActorType(filter.actorTypes);
    }
    if (filter.snapshotHistoryIds.isNotEmpty) {
      whereExpr &= vaultEventsHistory.snapshotHistoryId.isIn(
        filter.snapshotHistoryIds,
      );
    }

    if (filter.hasSnapshot != null) {
      whereExpr &= filter.hasSnapshot!
          ? vaultEventsHistory.snapshotHistoryId.isNotNull()
          : vaultEventsHistory.snapshotHistoryId.isNull();
    }
    if (filter.hasName != null) {
      whereExpr &= filter.hasName!
          ? vaultEventsHistory.name.isNotNull()
          : vaultEventsHistory.name.isNull();
    }

    if (filter.eventCreatedAfter != null) {
      whereExpr &= vaultEventsHistory.eventCreatedAt.isBiggerOrEqualValue(
        filter.eventCreatedAfter!,
      );
    }
    if (filter.eventCreatedBefore != null) {
      whereExpr &= vaultEventsHistory.eventCreatedAt.isSmallerOrEqualValue(
        filter.eventCreatedBefore!,
      );
    }

    return whereExpr;
  }

  Expression<bool> _matchesAnyAction(List<VaultEventHistoryAction> actions) {
    Expression<bool> expr = const Constant(false);
    for (final action in actions) {
      expr |= vaultEventsHistory.action.equalsValue(action);
    }
    return expr;
  }

  Expression<bool> _matchesAnyActorType(
    List<VaultHistoryActorType> actorTypes,
  ) {
    Expression<bool> expr = const Constant(false);
    for (final actorType in actorTypes) {
      expr |= vaultEventsHistory.actorType.equalsValue(actorType);
    }
    return expr;
  }

  Expression<bool> _matchesAnyType(List<VaultItemType> types) {
    Expression<bool> expr = const Constant(false);
    for (final type in types) {
      expr |= vaultEventsHistory.type.equalsValue(type);
    }
    return expr;
  }
}
