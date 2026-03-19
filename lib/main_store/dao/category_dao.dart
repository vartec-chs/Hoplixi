import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/category_tree_node.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/models/filter/categories_filter.dart';
import 'package:hoplixi/main_store/tables/categories.dart';
import 'package:uuid/uuid.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<MainStore> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Подсчитать количество элементов в категории.
  Future<int> countItemsInCategory(String categoryId) async {
    final countExpr = db.vaultItems.id.count();
    final query = selectOnly(db.vaultItems)
      ..addColumns([countExpr])
      ..where(db.vaultItems.categoryId.equals(categoryId))
      ..where(db.vaultItems.isDeleted.equals(false));
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  /// Создать [CategoryCardDto] из [CategoriesData].
  Future<CategoryCardDto> _toCardDto(CategoriesData c) async {
    final itemsCount = await countItemsInCategory(c.id);
    return CategoryCardDto(
      id: c.id,
      name: c.name,
      type: c.type.value,
      color: c.color,
      iconId: c.iconId,
      parentId: c.parentId,
      itemsCount: itemsCount,
    );
  }

  Future<Map<String, int>> _countItemsForCategories(
    List<String> categoryIds,
  ) async {
    if (categoryIds.isEmpty) {
      return const {};
    }

    final countExpr = db.vaultItems.id.count();
    final query = selectOnly(db.vaultItems)
      ..addColumns([db.vaultItems.categoryId, countExpr])
      ..where(db.vaultItems.categoryId.isIn(categoryIds))
      ..where(db.vaultItems.isDeleted.equals(false))
      ..groupBy([db.vaultItems.categoryId]);

    final rows = await query.get();
    final result = <String, int>{for (final id in categoryIds) id: 0};

    for (final row in rows) {
      final categoryId = row.read(db.vaultItems.categoryId);
      if (categoryId != null) {
        result[categoryId] = row.read(countExpr) ?? 0;
      }
    }

    return result;
  }

  Future<Map<String, bool>> _getHasChildrenMap(List<String> categoryIds) async {
    if (categoryIds.isEmpty) {
      return const {};
    }

    final countExpr = categories.id.count();
    final query = selectOnly(categories)
      ..addColumns([categories.parentId, countExpr])
      ..where(categories.parentId.isIn(categoryIds))
      ..groupBy([categories.parentId]);

    final rows = await query.get();
    final result = <String, bool>{for (final id in categoryIds) id: false};

    for (final row in rows) {
      final parentId = row.read(categories.parentId);
      if (parentId != null) {
        result[parentId] = (row.read(countExpr) ?? 0) > 0;
      }
    }

    return result;
  }

  Future<List<CategoryCardDto>> _toCardDtos(
    List<CategoriesData> entries,
  ) async {
    if (entries.isEmpty) {
      return const [];
    }

    final ids = entries.map((entry) => entry.id).toList(growable: false);
    final itemCounts = await _countItemsForCategories(ids);

    return [
      for (final entry in entries)
        CategoryCardDto(
          id: entry.id,
          name: entry.name,
          type: entry.type.value,
          color: entry.color,
          iconId: entry.iconId,
          parentId: entry.parentId,
          itemsCount: itemCounts[entry.id] ?? 0,
        ),
    ];
  }

  Future<List<CategoryTreeNode>> _toLazyTreeNodes(
    List<CategoriesData> entries,
  ) async {
    if (entries.isEmpty) {
      return const [];
    }

    final cards = await _toCardDtos(entries);
    final hasChildrenMap = await _getHasChildrenMap(
      cards.map((card) => card.id).toList(growable: false),
    );

    return [
      for (final card in cards)
        CategoryTreeNode(
          category: card,
          hasChildren: hasChildrenMap[card.id] ?? false,
          isExpanded: false,
          isChildrenLoaded: false,
          isLoadingChildren: false,
        ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Простые выборки
  // ---------------------------------------------------------------------------

  /// Получить все категории (сырые данные).
  Future<List<CategoriesData>> getAllCategories() => select(categories).get();

  /// Получить категорию по ID.
  Future<CategoriesData?> getCategoryById(String id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Получить все категории в виде карточек.
  Future<List<CategoryCardDto>> getAllCategoryCards() async {
    final list = await (select(
      categories,
    )..orderBy([(c) => OrderingTerm.asc(c.name)])).get();
    return _toCardDtos(list);
  }

  /// Получить только корневые категории (без родителя).
  Future<List<CategoryCardDto>> getRootCategoryCards() async {
    final list =
        await (select(categories)
              ..where((c) => c.parentId.isNull())
              ..orderBy([(c) => OrderingTerm.asc(c.name)]))
            .get();
    return _toCardDtos(list);
  }

  /// Получить прямые подкатегории указанной категории.
  Future<List<CategoryCardDto>> getSubcategories(String parentId) async {
    final list =
        await (select(categories)
              ..where((c) => c.parentId.equals(parentId))
              ..orderBy([(c) => OrderingTerm.asc(c.name)]))
            .get();
    return _toCardDtos(list);
  }

  Future<List<CategoryTreeNode>> getRootCategoryNodesPaginated({
    required int limit,
    required int offset,
  }) async {
    final list =
        await (select(categories)
              ..where((c) => c.parentId.isNull())
              ..orderBy([(c) => OrderingTerm.asc(c.name)])
              ..limit(limit, offset: offset))
            .get();
    return _toLazyTreeNodes(list);
  }

  Future<List<CategoryTreeNode>> getSubcategoryNodes(String parentId) async {
    final list =
        await (select(categories)
              ..where((c) => c.parentId.equals(parentId))
              ..orderBy([(c) => OrderingTerm.asc(c.name)]))
            .get();
    return _toLazyTreeNodes(list);
  }

  /// Построить дерево категорий: возвращает список корневых узлов
  /// с рекурсивно вложенными дочерними.
  Future<List<CategoryTreeNode>> getCategoryTree() async {
    final all = await (select(
      categories,
    )..orderBy([(c) => OrderingTerm.asc(c.name)])).get();

    // Строим DTO для всех категорий
    final cards = await _toCardDtos(all);

    // Группируем по parentId
    final childrenMap = <String, List<CategoryCardDto>>{};
    final roots = <CategoryCardDto>[];
    for (final card in cards) {
      if (card.parentId == null) {
        roots.add(card);
      } else {
        childrenMap.putIfAbsent(card.parentId!, () => []).add(card);
      }
    }

    CategoryTreeNode buildNode(CategoryCardDto cat) {
      final children = childrenMap[cat.id] ?? [];
      return CategoryTreeNode(
        category: cat,
        children: children.map(buildNode).toList(),
        hasChildren: children.isNotEmpty,
        isChildrenLoaded: true,
      );
    }

    return roots.map(buildNode).toList();
  }

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  /// Смотреть все категории с автообновлением.
  Stream<List<CategoriesData>> watchAllCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();

  /// Смотреть дерево категорий с автообновлением.
  Stream<List<CategoryTreeNode>> watchCategoryTree() =>
      watchAllCategories().asyncMap((_) => getCategoryTree());

  /// Смотреть категории карточки с автообновлением.
  Stream<List<CategoryCardDto>> watchCategoryCards() =>
      watchAllCategories().asyncMap(_toCardDtos);

  /// Смотреть категории по типу.
  Stream<List<CategoryCardDto>> watchCategoriesByType(String type) =>
      (select(categories)
            ..where((c) => c.type.equals(type))
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .watch()
          .asyncMap(_toCardDtos);

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Создать новую категорию.
  Future<String> createCategory(CreateCategoryDto dto) async {
    final id = const Uuid().v4();
    await into(categories).insert(
      CategoriesCompanion.insert(
        id: Value(id),
        name: dto.name,
        type: CategoryTypeX.fromString(dto.type),
        description: Value(dto.description),
        color: Value(dto.color ?? 'FFFFFF'),
        iconId: Value(dto.iconId),
        parentId: Value(dto.parentId),
      ),
    );
    return id;
  }

  /// Обновить категорию.
  Future<bool> updateCategory(String id, UpdateCategoryDto dto) {
    final companion = CategoriesCompanion(
      name: dto.name != null ? Value(dto.name!) : const Value.absent(),
      description: dto.description != null
          ? Value(dto.description)
          : const Value.absent(),
      color: dto.color != null ? Value(dto.color!) : const Value.absent(),
      iconId: dto.iconId != null ? Value(dto.iconId) : const Value.absent(),
      parentId: dto.parentId,
      modifiedAt: Value(DateTime.now()),
    );

    return (update(
      categories,
    )..where((c) => c.id.equals(id))).write(companion).then((n) => n > 0);
  }

  /// Удалить категорию.
  Future<bool> deleteCategory(String id) async {
    final rowsAffected = await (delete(
      categories,
    )..where((c) => c.id.equals(id))).go();
    return rowsAffected > 0;
  }

  // ---------------------------------------------------------------------------
  // Фильтрованные выборки
  // ---------------------------------------------------------------------------

  /// Получить отфильтрованные категории.
  Future<List<CategoriesData>> getCategoriesFiltered(CategoriesFilter filter) =>
      _buildFilterQuery(filter).get();

  /// Смотреть отфильтрованные категории с автообновлением.
  Stream<List<CategoriesData>> watchCategoriesFiltered(
    CategoriesFilter filter,
  ) => _buildFilterQuery(filter).watch();

  /// Получить отфильтрованные категории в виде карточек.
  Future<List<CategoryCardDto>> getCategoryCardsFiltered(
    CategoriesFilter filter,
  ) async {
    final list = await getCategoriesFiltered(filter);
    return _toCardDtos(list);
  }

  /// Смотреть отфильтрованные категории карточки с автообновлением.
  Stream<List<CategoryCardDto>> watchCategoryCardsFiltered(
    CategoriesFilter filter,
  ) => watchCategoriesFiltered(filter).asyncMap(_toCardDtos);

  /// Получить с пагинацией.
  Future<List<CategoryCardDto>> getCategoryCardsPaginated({
    required int limit,
    required int offset,
  }) async {
    final list =
        await (select(categories)
              ..orderBy([(c) => OrderingTerm.asc(c.name)])
              ..limit(limit, offset: offset))
            .get();
    return _toCardDtos(list);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  SimpleSelectStatement<$CategoriesTable, CategoriesData> _buildFilterQuery(
    CategoriesFilter filter,
  ) {
    var query = select(categories);

    if (filter.query.isNotEmpty) {
      query = query..where((c) => c.name.like('%${filter.query}%'));
    }
    if (filter.types.isNotEmpty) {
      query = query
        ..where((c) => c.type.isIn(filter.types.map((t) => t!.value).toList()));
    }
    if (filter.color != null) {
      query = query..where((c) => c.color.equals(filter.color!));
    }
    if (filter.hasIcon != null) {
      if (filter.hasIcon!) {
        query = query..where((c) => c.iconId.isNotNull());
      } else {
        query = query..where((c) => c.iconId.isNull());
      }
    }
    if (filter.hasDescription != null) {
      if (filter.hasDescription!) {
        query = query..where((c) => c.description.isNotNull());
      } else {
        query = query..where((c) => c.description.isNull());
      }
    }
    if (filter.createdAfter != null) {
      query = query
        ..where((c) => c.createdAt.isBiggerThanValue(filter.createdAfter!));
    }
    if (filter.createdBefore != null) {
      query = query
        ..where((c) => c.createdAt.isSmallerThanValue(filter.createdBefore!));
    }
    if (filter.modifiedAfter != null) {
      query = query
        ..where((c) => c.modifiedAt.isBiggerThanValue(filter.modifiedAfter!));
    }
    if (filter.modifiedBefore != null) {
      query = query
        ..where((c) => c.modifiedAt.isSmallerThanValue(filter.modifiedBefore!));
    }

    query = query..orderBy([(c) => _sortTerm(filter.sortField, c)]);

    if (filter.limit != null && filter.limit! > 0) {
      query = query..limit(filter.limit!, offset: filter.offset ?? 0);
    }

    return query;
  }

  OrderingTerm _sortTerm(CategoriesSortField sortField, Categories c) {
    switch (sortField) {
      case CategoriesSortField.name:
        return OrderingTerm.asc(c.name);
      case CategoriesSortField.type:
        return OrderingTerm.asc(c.type);
      case CategoriesSortField.createdAt:
        return OrderingTerm.asc(c.createdAt);
      case CategoriesSortField.modifiedAt:
        return OrderingTerm.asc(c.modifiedAt);
    }
  }
}
