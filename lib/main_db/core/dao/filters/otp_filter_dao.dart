import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../models/dto/dto.dart';
import '../../models/filters/filters.dart';
import '../../tables/otp/otp_items.dart';
import '../../tables/system/categories.dart';
import '../../tables/system/item_tags.dart';
import '../../tables/system/tags.dart';
import '../../tables/vault_items/vault_items.dart';
import 'base_filter_query_mixin.dart';
import 'filter_dao.dart';

part 'otp_filter_dao.g.dart';

@DriftAccessor(tables: [
  VaultItems,
  OtpItems,
  Categories,
  Tags,
  ItemTags,
])
class OtpFilterDao extends DatabaseAccessor<MainStore>
    with _$OtpFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<OtpFilter, FilteredCardDto<OtpCardDto>> {
  OtpFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<OtpCardDto>>> getFiltered(
    OtpFilter filter,
  ) async {
    final query = _buildQuery(filter);
    applyLimitOffset(query, filter.base);

    final rows = await query.get();
    if (rows.isEmpty) return [];

    final itemIds = rows.map((r) => r.readTable(vaultItems).id).toList();
    final categoryIds =
        rows.map((r) => r.readTable(vaultItems).categoryId).whereType<String>().toList();

    final categoriesMap = await loadCategoriesForItems(categoryIds);
    final tagsMap = await loadTagsForItems(itemIds);

    final hasSecretExpr = db.otpItems.secret.isNotNull();

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final otp = row.readTable(otpItems);

      final categoryId = item.categoryId;
      final meta = VaultItemCardMetaDto(
        category: categoryId != null ? categoriesMap[categoryId] : null,
        tags: tagsMap[item.id] ?? const [],
      );

      final cardDto = OtpCardDto(
        item: VaultItemCardDto(
          itemId: item.id,
          type: item.type,
          name: item.name,
          description: item.description,
          categoryId: item.categoryId,
          iconRefId: item.iconRefId,
          isFavorite: item.isFavorite,
          isArchived: item.isArchived,
          isPinned: item.isPinned,
          isDeleted: item.isDeleted,
          createdAt: item.createdAt,
          modifiedAt: item.modifiedAt,
          lastUsedAt: item.lastUsedAt,
          archivedAt: item.archivedAt,
          deletedAt: item.deletedAt,
          recentScore: item.recentScore,
        ),
        otp: OtpCardDataDto(
          type: row.readWithConverter<OtpType, String>(otpItems.type)!,
          issuer: otp.issuer,
          accountName: otp.accountName,
          algorithm: row.readWithConverter<OtpHashAlgorithm, String>(otpItems.algorithm)!,
          digits: otp.digits,
          period: otp.period,
          counter: otp.counter,
          hasSecret: row.read(hasSecretExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(OtpFilter filter) async {
    final query = _buildQuery(filter);
    final countExp = countAll();
    query.addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildQuery(OtpFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(VaultItemType.otp);

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.issuer != null) {
      whereExpr &= otpItems.issuer.contains(filter.issuer!);
    }
    if (filter.accountName != null) {
      whereExpr &= otpItems.accountName.contains(filter.accountName!);
    }
    if (filter.type != null) {
      whereExpr &= otpItems.type.equalsValue(filter.type!);
    }
    if (filter.algorithm != null) {
      whereExpr &= otpItems.algorithm.equalsValue(filter.algorithm!);
    }
    if (filter.digits != null) {
      whereExpr &= otpItems.digits.equals(filter.digits!);
    }

    if (filter.hasIssuer != null) {
      if (filter.hasIssuer!) {
        whereExpr &= otpItems.issuer.isNotNull();
      } else {
        whereExpr &= otpItems.issuer.isNull();
      }
    }
    if (filter.hasAccountName != null) {
      if (filter.hasAccountName!) {
        whereExpr &= otpItems.accountName.isNotNull();
      } else {
        whereExpr &= otpItems.accountName.isNull();
      }
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr = vaultItems.name.like(q) |
          vaultItems.description.like(q) |
          otpItems.issuer.like(q) |
          otpItems.accountName.like(q);
      whereExpr &= textExpr;
    }

    final hasSecretExpr = db.otpItems.secret.isNotNull();

    final query = select(vaultItems).join([
      innerJoin(otpItems, otpItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..where(whereExpr)
      ..addColumns([hasSecretExpr]);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case OtpSortField.name:
          orderingTerms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case OtpSortField.issuer:
          orderingTerms.add(OrderingTerm(expression: otpItems.issuer, mode: mode));
          break;
        case OtpSortField.accountName:
          orderingTerms.add(OrderingTerm(expression: otpItems.accountName, mode: mode));
          break;
        case OtpSortField.createdAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case OtpSortField.modifiedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case OtpSortField.lastUsedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case OtpSortField.usedCount:
          orderingTerms.add(OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case OtpSortField.recentScore:
          orderingTerms.add(OrderingTerm(expression: vaultItems.recentScore, mode: mode));
          break;
      }
    }

    query.orderBy(orderingTerms);

    return query;
  }
}
