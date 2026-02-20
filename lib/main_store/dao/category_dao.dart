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
    return Future.wait(list.map(_toCardDto));
  }

  /// Получить только корневые категории (без родителя).
  Future<List<CategoryCardDto>> getRootCategoryCards() async {
    final list =
        await (select(categories)
              ..where((c) => c.parentId.isNull())
              ..orderBy([(c) => OrderingTerm.asc(c.name)]))
            .get();
    return Future.wait(list.map(_toCardDto));
  }

  /// Получить прямые подкатегории указанной категории.
  Future<List<CategoryCardDto>> getSubcategories(String parentId) async {
    final list =
        await (select(categories)
              ..where((c) => c.parentId.equals(parentId))
              ..orderBy([(c) => OrderingTerm.asc(c.name)]))
            .get();
    return Future.wait(list.map(_toCardDto));
  }

  /// Построить дерево категорий: возвращает список корневых узлов
  /// с рекурсивно вложенными дочерними.
  Future<List<CategoryTreeNode>> getCategoryTree() async {
    final all = await (select(
      categories,
    )..orderBy([(c) => OrderingTerm.asc(c.name)])).get();

    // Строим DTO для всех категорий
    final cards = <CategoryCardDto>[];
    for (final c in all) {
      final itemsCount = await countItemsInCategory(c.id);
      cards.add(
        CategoryCardDto(
          id: c.id,
          name: c.name,
          type: c.type.value,
          color: c.color,
          iconId: c.iconId,
          parentId: c.parentId,
          itemsCount: itemsCount,
        ),
      );
    }

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
  Stream<List<CategoryCardDto>> watchCategoryCards() => watchAllCategories()
      .asyncMap((list) => Future.wait(list.map(_toCardDto)));

  /// Смотреть категории по типу.
  Stream<List<CategoryCardDto>> watchCategoriesByType(String type) =>
      (select(categories)
            ..where((c) => c.type.equals(type))
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .watch()
          .asyncMap((list) => Future.wait(list.map(_toCardDto)));

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
    return Future.wait(list.map(_toCardDto));
  }

  /// Смотреть отфильтрованные категории карточки с автообновлением.
  Stream<List<CategoryCardDto>> watchCategoryCardsFiltered(
    CategoriesFilter filter,
  ) => watchCategoriesFiltered(
    filter,
  ).asyncMap((list) => Future.wait(list.map(_toCardDto)));

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
    return Future.wait(list.map(_toCardDto));
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
