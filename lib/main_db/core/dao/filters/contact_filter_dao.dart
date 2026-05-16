import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../models/dto/dto.dart';
import '../../models/filters/filters.dart';
import '../../tables/contact/contact_items.dart';
import '../../tables/system/categories.dart';
import '../../tables/system/item_tags.dart';
import '../../tables/system/tags.dart';
import '../../tables/vault_items/vault_items.dart';
import 'base_filter_query_mixin.dart';
import 'filter_dao.dart';

part 'contact_filter_dao.g.dart';

@DriftAccessor(tables: [
  VaultItems,
  ContactItems,
  Categories,
  Tags,
  ItemTags,
])
class ContactFilterDao extends DatabaseAccessor<MainStore>
    with _$ContactFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<ContactFilter, FilteredCardDto<ContactCardDto>> {
  ContactFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<ContactCardDto>>> getFiltered(
    ContactFilter filter,
  ) async {
    final whereExpr = _buildWhere(filter);

    final query = selectOnly(vaultItems).join([
      innerJoin(contactItems, contactItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..addColumns([
        vaultItems.id,
        vaultItems.type,
        vaultItems.name,
        vaultItems.description,
        vaultItems.categoryId,
        vaultItems.iconRefId,
        vaultItems.isFavorite,
        vaultItems.isArchived,
        vaultItems.isPinned,
        vaultItems.isDeleted,
        vaultItems.createdAt,
        vaultItems.modifiedAt,
        vaultItems.lastUsedAt,
        vaultItems.archivedAt,
        vaultItems.deletedAt,
        vaultItems.recentScore,
        contactItems.firstName,
        contactItems.middleName,
        contactItems.lastName,
        contactItems.company,
        contactItems.phone,
        contactItems.email,
        contactItems.isEmergencyContact,
      ])
      ..where(whereExpr);

    applyLimitOffset(query, filter.base);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case ContactSortField.name:
          orderingTerms
              .add(OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case ContactSortField.firstName:
          orderingTerms.add(
              OrderingTerm(expression: contactItems.firstName, mode: mode));
          break;
        case ContactSortField.lastName:
          orderingTerms
              .add(OrderingTerm(expression: contactItems.lastName, mode: mode));
          break;
        case ContactSortField.company:
          orderingTerms
              .add(OrderingTerm(expression: contactItems.company, mode: mode));
          break;
        case ContactSortField.createdAt:
          orderingTerms
              .add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case ContactSortField.modifiedAt:
          orderingTerms
              .add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case ContactSortField.lastUsedAt:
          orderingTerms
              .add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case ContactSortField.usedCount:
          orderingTerms
              .add(OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case ContactSortField.recentScore:
          orderingTerms
              .add(OrderingTerm(expression: vaultItems.recentScore, mode: mode));
          break;
      }
    }
    query.orderBy(orderingTerms);

    final rows = await query.get();
    if (rows.isEmpty) return [];

    final itemIds = rows.map((r) => r.read(vaultItems.id)!).toList();
    final categoryIds = rows
        .map((r) => r.read(vaultItems.categoryId))
        .whereType<String>()
        .toList();

    final categoriesMap = await loadCategoriesForItems(categoryIds);
    final tagsMap = await loadTagsForItems(itemIds);

    return rows.map((row) {
      final itemId = row.read(vaultItems.id)!;
      final categoryId = row.read(vaultItems.categoryId);
      final meta = VaultItemCardMetaDto(
        category: categoryId != null ? categoriesMap[categoryId] : null,
        tags: tagsMap[itemId] ?? const [],
      );

      final cardDto = ContactCardDto(
        item: VaultItemCardDto(
          itemId: itemId,
          type: row.readWithConverter<VaultItemType, String>(vaultItems.type)!,
          name: row.read(vaultItems.name)!,
          description: row.read(vaultItems.description),
          categoryId: categoryId,
          iconRefId: row.read(vaultItems.iconRefId),
          isFavorite: row.read(vaultItems.isFavorite)!,
          isArchived: row.read(vaultItems.isArchived)!,
          isPinned: row.read(vaultItems.isPinned)!,
          isDeleted: row.read(vaultItems.isDeleted)!,
          createdAt: row.read(vaultItems.createdAt)!,
          modifiedAt: row.read(vaultItems.modifiedAt)!,
          lastUsedAt: row.read(vaultItems.lastUsedAt),
          archivedAt: row.read(vaultItems.archivedAt),
          deletedAt: row.read(vaultItems.deletedAt),
          recentScore: row.read(vaultItems.recentScore),
        ),
        contact: ContactCardDataDto(
          firstName: row.read(contactItems.firstName)!,
          middleName: row.read(contactItems.middleName),
          lastName: row.read(contactItems.lastName),
          company: row.read(contactItems.company),
          phone: row.read(contactItems.phone),
          email: row.read(contactItems.email),
          isEmergencyContact:
              row.read(contactItems.isEmergencyContact) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(ContactFilter filter) async {
    final whereExpr = _buildWhere(filter);
    final countExp = countAll();
    final query = selectOnly(vaultItems).join([
      innerJoin(contactItems, contactItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..addColumns([countExp])
      ..where(whereExpr);

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Expression<bool> _buildWhere(ContactFilter filter) {
    Expression<bool> whereExpr =
        vaultItems.type.equalsValue(VaultItemType.contact);

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.firstName != null) {
      whereExpr &= contactItems.firstName.contains(filter.firstName!);
    }
    if (filter.middleName != null) {
      whereExpr &= contactItems.middleName.contains(filter.middleName!);
    }
    if (filter.lastName != null) {
      whereExpr &= contactItems.lastName.contains(filter.lastName!);
    }
    if (filter.company != null) {
      whereExpr &= contactItems.company.contains(filter.company!);
    }
    if (filter.phone != null) {
      whereExpr &= contactItems.phone.contains(filter.phone!);
    }
    if (filter.email != null) {
      whereExpr &= contactItems.email.contains(filter.email!);
    }
    if (filter.isEmergencyContact != null) {
      whereExpr &=
          contactItems.isEmergencyContact.equals(filter.isEmergencyContact!);
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr = vaultItems.name.like(q) |
          vaultItems.description.like(q) |
          contactItems.firstName.like(q) |
          contactItems.middleName.like(q) |
          contactItems.lastName.like(q) |
          contactItems.company.like(q) |
          contactItems.phone.like(q) |
          contactItems.email.like(q);
      whereExpr &= textExpr;
    }

    return whereExpr;
  }
}
