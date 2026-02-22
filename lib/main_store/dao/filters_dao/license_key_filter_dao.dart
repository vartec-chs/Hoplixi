import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/license_key_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/license_keys_filter.dart';
import 'package:hoplixi/main_store/tables/categories.dart';
import 'package:hoplixi/main_store/tables/item_tags.dart';
import 'package:hoplixi/main_store/tables/license_key_items.dart';
import 'package:hoplixi/main_store/tables/note_items.dart';
import 'package:hoplixi/main_store/tables/tags.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';

part 'license_key_filter_dao.g.dart';

@DriftAccessor(
  tables: [VaultItems, LicenseKeyItems, Categories, Tags, ItemTags, NoteItems],
)
class LicenseKeyFilterDao extends DatabaseAccessor<MainStore>
    with _$LicenseKeyFilterDaoMixin
    implements FilterDao<LicenseKeysFilter, LicenseKeyCardDto> {
  LicenseKeyFilterDao(super.db);

  @override
  Future<List<LicenseKeyCardDto>> getFiltered(LicenseKeysFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(
        licenseKeyItems,
        licenseKeyItems.itemId.equalsExp(vaultItems.id),
      ),
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
      final license = row.readTable(licenseKeyItems);
      final category = row.readTableOrNull(categories);

      return LicenseKeyCardDto(
        id: item.id,
        name: item.name,
        product: license.product,
        licenseType: license.licenseType,
        orderId: license.orderId,
        expiresAt: license.expiresAt,
        seats: license.seats,
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
  Future<int> countFiltered(LicenseKeysFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(
        licenseKeyItems,
        licenseKeyItems.itemId.equalsExp(vaultItems.id),
      ),
      leftOuterJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.noteId)),
    ]);

    query.where(_buildWhereExpression(filter));
    final rows = await query.get();
    return rows.length;
  }

  Expression<bool> _buildWhereExpression(LicenseKeysFilter filter) {
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
              licenseKeyItems.product.lower().like('%$q%') |
              licenseKeyItems.licenseType.lower().like('%$q%') |
              licenseKeyItems.orderId.lower().like('%$q%') |
              licenseKeyItems.purchaseFrom.lower().like('%$q%') |
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

  Expression<bool> _applySpecificFilters(LicenseKeysFilter filter) {
    Expression<bool> expr = const Constant(true);

    if (filter.name != null) {
      expr =
          expr &
          vaultItems.name.lower().like('%${filter.name!.toLowerCase()}%');
    }

    if (filter.product != null) {
      expr =
          expr &
          licenseKeyItems.product.lower().like(
            '%${filter.product!.toLowerCase()}%',
          );
    }

    if (filter.licenseType != null) {
      expr =
          expr &
          licenseKeyItems.licenseType.lower().like(
            '%${filter.licenseType!.toLowerCase()}%',
          );
    }

    if (filter.orderId != null) {
      expr =
          expr &
          licenseKeyItems.orderId.lower().like(
            '%${filter.orderId!.toLowerCase()}%',
          );
    }

    if (filter.purchaseFrom != null) {
      expr =
          expr &
          licenseKeyItems.purchaseFrom.lower().like(
            '%${filter.purchaseFrom!.toLowerCase()}%',
          );
    }

    if (filter.supportContact != null) {
      expr =
          expr &
          licenseKeyItems.supportContact.lower().like(
            '%${filter.supportContact!.toLowerCase()}%',
          );
    }

    if (filter.expiredOnly == true) {
      expr =
          expr &
          licenseKeyItems.expiresAt.isNotNull() &
          licenseKeyItems.expiresAt.isSmallerOrEqualValue(DateTime.now());
    }

    return expr;
  }

  List<OrderingTerm> _buildOrderBy(LicenseKeysFilter filter) {
    final terms = <OrderingTerm>[
      OrderingTerm(expression: vaultItems.isPinned, mode: OrderingMode.desc),
    ];

    final mode = filter.base.sortDirection == SortDirection.asc
        ? OrderingMode.asc
        : OrderingMode.desc;

    switch (filter.sortField) {
      case LicenseKeysSortField.name:
        terms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
      case LicenseKeysSortField.product:
        terms.add(
          OrderingTerm(expression: licenseKeyItems.product, mode: mode),
        );
      case LicenseKeysSortField.licenseType:
        terms.add(
          OrderingTerm(expression: licenseKeyItems.licenseType, mode: mode),
        );
      case LicenseKeysSortField.orderId:
        terms.add(
          OrderingTerm(expression: licenseKeyItems.orderId, mode: mode),
        );
      case LicenseKeysSortField.expiresAt:
        terms.add(
          OrderingTerm(expression: licenseKeyItems.expiresAt, mode: mode),
        );
      case LicenseKeysSortField.createdAt:
        terms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
      case LicenseKeysSortField.modifiedAt:
        terms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
      case LicenseKeysSortField.lastAccessed:
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
