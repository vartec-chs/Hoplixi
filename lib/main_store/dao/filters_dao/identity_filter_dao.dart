import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/identity_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/identities_filter.dart';
import 'package:hoplixi/main_store/tables/categories.dart';
import 'package:hoplixi/main_store/tables/identity_items.dart';
import 'package:hoplixi/main_store/tables/item_tags.dart';
import 'package:hoplixi/main_store/tables/note_items.dart';
import 'package:hoplixi/main_store/tables/tags.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';

part 'identity_filter_dao.g.dart';

@DriftAccessor(
  tables: [VaultItems, IdentityItems, Categories, Tags, ItemTags, NoteItems],
)
class IdentityFilterDao extends DatabaseAccessor<MainStore>
    with _$IdentityFilterDaoMixin
    implements FilterDao<IdentitiesFilter, IdentityCardDto> {
  IdentityFilterDao(super.db);

  @override
  Future<List<IdentityCardDto>> getFiltered(IdentitiesFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(identityItems, identityItems.itemId.equalsExp(vaultItems.id)),
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
      final identity = row.readTable(identityItems);
      final category = row.readTableOrNull(categories);

      return IdentityCardDto(
        id: item.id,
        name: item.name,
        idType: identity.idType,
        idNumber: identity.idNumber,
        fullName: identity.fullName,
        nationality: identity.nationality,
        expiryDate: identity.expiryDate,
        verified: identity.verified,
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
  Future<int> countFiltered(IdentitiesFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(identityItems, identityItems.itemId.equalsExp(vaultItems.id)),
      leftOuterJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.noteId)),
    ]);

    query.where(_buildWhereExpression(filter));
    final rows = await query.get();
    return rows.length;
  }

  Expression<bool> _buildWhereExpression(IdentitiesFilter filter) {
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
              identityItems.idType.lower().like('%$q%') |
              identityItems.idNumber.lower().like('%$q%') |
              identityItems.fullName.lower().like('%$q%') |
              identityItems.nationality.lower().like('%$q%') |
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

  Expression<bool> _applySpecificFilters(IdentitiesFilter filter) {
    Expression<bool> expr = const Constant(true);

    if (filter.name != null) {
      expr =
          expr &
          vaultItems.name.lower().like('%${filter.name!.toLowerCase()}%');
    }

    if (filter.idType != null) {
      expr =
          expr &
          identityItems.idType.lower().like(
            '%${filter.idType!.toLowerCase()}%',
          );
    }

    if (filter.idNumber != null) {
      expr =
          expr &
          identityItems.idNumber.lower().like(
            '%${filter.idNumber!.toLowerCase()}%',
          );
    }

    if (filter.fullName != null) {
      expr =
          expr &
          identityItems.fullName.lower().like(
            '%${filter.fullName!.toLowerCase()}%',
          );
    }

    if (filter.nationality != null) {
      expr =
          expr &
          identityItems.nationality.lower().like(
            '%${filter.nationality!.toLowerCase()}%',
          );
    }

    if (filter.verified != null) {
      expr = expr & identityItems.verified.equals(filter.verified!);
    }

    if (filter.expiredOnly == true) {
      expr =
          expr &
          identityItems.expiryDate.isNotNull() &
          identityItems.expiryDate.isSmallerOrEqualValue(DateTime.now());
    }

    return expr;
  }

  List<OrderingTerm> _buildOrderBy(IdentitiesFilter filter) {
    final terms = <OrderingTerm>[
      OrderingTerm(expression: vaultItems.isPinned, mode: OrderingMode.desc),
    ];

    final mode = filter.base.sortDirection == SortDirection.asc
        ? OrderingMode.asc
        : OrderingMode.desc;

    switch (filter.sortField) {
      case IdentitiesSortField.name:
        terms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
      case IdentitiesSortField.idType:
        terms.add(OrderingTerm(expression: identityItems.idType, mode: mode));
      case IdentitiesSortField.idNumber:
        terms.add(OrderingTerm(expression: identityItems.idNumber, mode: mode));
      case IdentitiesSortField.expiryDate:
        terms.add(
          OrderingTerm(expression: identityItems.expiryDate, mode: mode),
        );
      case IdentitiesSortField.createdAt:
        terms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
      case IdentitiesSortField.modifiedAt:
        terms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
      case IdentitiesSortField.lastAccessed:
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
