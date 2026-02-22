import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/contact_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/contacts_filter.dart';
import 'package:hoplixi/main_store/tables/categories.dart';
import 'package:hoplixi/main_store/tables/contact_items.dart';
import 'package:hoplixi/main_store/tables/item_tags.dart';
import 'package:hoplixi/main_store/tables/note_items.dart';
import 'package:hoplixi/main_store/tables/tags.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';

part 'contact_filter_dao.g.dart';

@DriftAccessor(
  tables: [VaultItems, ContactItems, Categories, Tags, ItemTags, NoteItems],
)
class ContactFilterDao extends DatabaseAccessor<MainStore>
    with _$ContactFilterDaoMixin
    implements FilterDao<ContactsFilter, ContactCardDto> {
  ContactFilterDao(super.db);

  @override
  Future<List<ContactCardDto>> getFiltered(ContactsFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(contactItems, contactItems.itemId.equalsExp(vaultItems.id)),
      leftOuterJoin(categories, categories.id.equalsExp(vaultItems.categoryId)),
      leftOuterJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.noteId)),
    ]);

    query.where(_buildWhereExpression(filter));
    query.orderBy(_buildOrderBy(filter));

    if (filter.base.limit != null && filter.base.limit! > 0) {
      query.limit(filter.base.limit!, offset: filter.base.offset);
    }

    final rows = await query.get();
    final itemIds = rows.map((r) => r.readTable(vaultItems).id).toList();
    final tagsMap = await _loadTagsForItems(itemIds);

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final contact = row.readTable(contactItems);
      final category = row.readTableOrNull(categories);

      return ContactCardDto(
        id: item.id,
        name: item.name,
        phone: contact.phone,
        email: contact.email,
        company: contact.company,
        jobTitle: contact.jobTitle,
        isEmergencyContact: contact.isEmergencyContact,
        description: item.description,
        category: category != null
            ? CategoryInCardDto(
                id: category.id,
                name: category.name,
                type: category.type.name,
                color: category.color,
                iconId: category.iconId,
              )
            : null,
        tags: tagsMap[item.id] ?? [],
        isFavorite: item.isFavorite,
        isPinned: item.isPinned,
        isArchived: item.isArchived,
        isDeleted: item.isDeleted,
        usedCount: item.usedCount,
        modifiedAt: item.modifiedAt,
        createdAt: item.createdAt,
      );
    }).toList();
  }

  @override
  Future<int> countFiltered(ContactsFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(contactItems, contactItems.itemId.equalsExp(vaultItems.id)),
      leftOuterJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.noteId)),
    ]);

    query.where(_buildWhereExpression(filter));
    final rows = await query.get();
    return rows.length;
  }

  Expression<bool> _buildWhereExpression(ContactsFilter filter) {
    Expression<bool> expr = const Constant(true);
    expr = expr & _applyBaseFilters(filter.base);
    expr = expr & _applySpecificFilters(filter);
    return expr;
  }

  Expression<bool> _applyBaseFilters(BaseFilter base) {
    Expression<bool> expr = const Constant(true);

    if (base.isDeleted == null) {
      expr = expr & vaultItems.isDeleted.equals(false);
    }

    if (base.query.isNotEmpty) {
      final q = base.query.toLowerCase();
      expr =
          expr &
          (vaultItems.name.lower().like('%$q%') |
              contactItems.phone.lower().like('%$q%') |
              contactItems.email.lower().like('%$q%') |
              contactItems.company.lower().like('%$q%') |
              contactItems.jobTitle.lower().like('%$q%') |
              contactItems.address.lower().like('%$q%') |
              vaultItems.description.lower().like('%$q%') |
              noteItems.content.lower().like('%$q%'));
    }

    if (base.categoryIds.isNotEmpty) {
      expr = expr & vaultItems.categoryId.isIn(base.categoryIds);
    }

    if (base.tagIds.isNotEmpty) {
      final tagExists = existsQuery(
        select(itemTags)..where(
          (t) => t.itemId.equalsExp(vaultItems.id) & t.tagId.isIn(base.tagIds),
        ),
      );
      expr = expr & tagExists;
    }

    if (base.isFavorite != null) {
      expr = expr & vaultItems.isFavorite.equals(base.isFavorite!);
    }

    if (base.isArchived != null) {
      expr = expr & vaultItems.isArchived.equals(base.isArchived!);
    } else {
      expr = expr & vaultItems.isArchived.equals(false);
    }

    if (base.isDeleted != null) {
      expr = expr & vaultItems.isDeleted.equals(base.isDeleted!);
    }

    return expr;
  }

  Expression<bool> _applySpecificFilters(ContactsFilter filter) {
    Expression<bool> expr = const Constant(true);

    if (filter.name != null) {
      expr =
          expr &
          vaultItems.name.lower().like('%${filter.name!.toLowerCase()}%');
    }

    if (filter.phone != null) {
      expr =
          expr &
          contactItems.phone.lower().like('%${filter.phone!.toLowerCase()}%');
    }

    if (filter.email != null) {
      expr =
          expr &
          contactItems.email.lower().like('%${filter.email!.toLowerCase()}%');
    }

    if (filter.company != null) {
      expr =
          expr &
          contactItems.company.lower().like(
            '%${filter.company!.toLowerCase()}%',
          );
    }

    if (filter.isEmergencyContact != null) {
      expr =
          expr &
          contactItems.isEmergencyContact.equals(filter.isEmergencyContact!);
    }

    if (filter.hasPhone != null) {
      expr =
          expr &
          (filter.hasPhone!
              ? contactItems.phone.isNotNull()
              : contactItems.phone.isNull());
    }

    if (filter.hasEmail != null) {
      expr =
          expr &
          (filter.hasEmail!
              ? contactItems.email.isNotNull()
              : contactItems.email.isNull());
    }

    return expr;
  }

  List<OrderingTerm> _buildOrderBy(ContactsFilter filter) {
    final terms = <OrderingTerm>[
      OrderingTerm(expression: vaultItems.isPinned, mode: OrderingMode.desc),
    ];

    final mode = filter.base.sortDirection == SortDirection.asc
        ? OrderingMode.asc
        : OrderingMode.desc;

    switch (filter.sortField) {
      case ContactsSortField.name:
        terms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
      case ContactsSortField.company:
        terms.add(OrderingTerm(expression: contactItems.company, mode: mode));
      case ContactsSortField.createdAt:
        terms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
      case ContactsSortField.modifiedAt:
        terms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
      case ContactsSortField.lastAccessed:
        terms.add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
      case null:
        terms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
    }

    return terms;
  }

  Future<Map<String, List<TagInCardDto>>> _loadTagsForItems(
    List<String> itemIds,
  ) async {
    if (itemIds.isEmpty) return {};

    final query = select(itemTags).join([
      innerJoin(tags, tags.id.equalsExp(itemTags.tagId)),
    ])..where(itemTags.itemId.isIn(itemIds));

    final rows = await query.get();
    final tagsMap = <String, List<TagInCardDto>>{};

    for (final row in rows) {
      final it = row.readTable(itemTags);
      final tag = row.readTable(tags);
      final list = tagsMap.putIfAbsent(it.itemId, () => []);
      if (list.length < 10) {
        list.add(TagInCardDto(id: tag.id, name: tag.name, color: tag.color));
      }
    }

    return tagsMap;
  }
}
