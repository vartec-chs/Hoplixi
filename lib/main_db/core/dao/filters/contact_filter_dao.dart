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
    final query = _buildQuery(filter);
    applyLimitOffset(query, filter.base);

    final rows = await query.get();
    if (rows.isEmpty) return [];

    final itemIds = rows.map((r) => r.readTable(vaultItems).id).toList();
    final categoryIds =
        rows.map((r) => r.readTable(vaultItems).categoryId).whereType<String>().toList();

    final categoriesMap = await loadCategoriesForItems(categoryIds);
    final tagsMap = await loadTagsForItems(itemIds);

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final contact = row.readTable(contactItems);

      final categoryId = item.categoryId;
      final meta = VaultItemCardMetaDto(
        category: categoryId != null ? categoriesMap[categoryId] : null,
        tags: tagsMap[item.id] ?? const [],
      );

      final cardDto = ContactCardDto(
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
        contact: ContactCardDataDto(
          firstName: contact.firstName,
          middleName: contact.middleName,
          lastName: contact.lastName,
          company: contact.company,
          phone: contact.phone,
          email: contact.email,
          isEmergencyContact: contact.isEmergencyContact,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(ContactFilter filter) async {
    final query = _buildQuery(filter);
    final countExp = countAll();
    query.addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildQuery(ContactFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(VaultItemType.contact);

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.phone != null) {
      whereExpr &= contactItems.phone.contains(filter.phone!);
    }
    if (filter.email != null) {
      whereExpr &= contactItems.email.contains(filter.email!);
    }
    if (filter.company != null) {
      whereExpr &= contactItems.company.contains(filter.company!);
    }
    if (filter.jobTitle != null) {
      whereExpr &= contactItems.jobTitle.contains(filter.jobTitle!);
    }
    if (filter.website != null) {
      whereExpr &= contactItems.website.contains(filter.website!);
    }
    if (filter.birthdayAfter != null) {
      whereExpr &= contactItems.birthday.isBiggerOrEqualValue(filter.birthdayAfter!);
    }
    if (filter.birthdayBefore != null) {
      whereExpr &= contactItems.birthday.isSmallerOrEqualValue(filter.birthdayBefore!);
    }
    if (filter.isEmergencyContact != null) {
      whereExpr &= contactItems.isEmergencyContact.equals(filter.isEmergencyContact!);
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr = vaultItems.name.like(q) |
          vaultItems.description.like(q) |
          contactItems.firstName.like(q) |
          contactItems.lastName.like(q) |
          contactItems.company.like(q) |
          contactItems.email.like(q) |
          contactItems.phone.like(q);
      whereExpr &= textExpr;
    }

    final query = select(vaultItems).join([
      innerJoin(contactItems, contactItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..where(whereExpr);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case ContactSortField.name:
          orderingTerms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case ContactSortField.firstName:
          orderingTerms.add(OrderingTerm(expression: contactItems.firstName, mode: mode));
          break;
        case ContactSortField.lastName:
          orderingTerms.add(OrderingTerm(expression: contactItems.lastName, mode: mode));
          break;
        case ContactSortField.company:
          orderingTerms.add(OrderingTerm(expression: contactItems.company, mode: mode));
          break;
        case ContactSortField.createdAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case ContactSortField.modifiedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case ContactSortField.lastUsedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case ContactSortField.usedCount:
          orderingTerms.add(OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case ContactSortField.recentScore:
          orderingTerms.add(OrderingTerm(expression: vaultItems.recentScore, mode: mode));
          break;
      }
    }

    query.orderBy(orderingTerms);

    return query;
  }
}
