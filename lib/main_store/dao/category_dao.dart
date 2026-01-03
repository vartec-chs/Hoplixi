import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/models/filter/categories_filter.dart';
import 'package:hoplixi/main_store/tables/categories.dart';
import 'package:uuid/uuid.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<MainStore> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// Подсчитать количество элементов в категории
  Future<int> countItemsInCategory(String categoryId) async {
    // Подсчитываем элементы во всех таблицах, которые используют categoryId
    final passwordsCount =
        await (selectOnly(db.passwords)
              ..addColumns([db.passwords.id.count()])
              ..where(db.passwords.categoryId.equals(categoryId))
              ..where(db.passwords.isDeleted.equals(false)))
            .getSingle()
            .then((row) => row.read(db.passwords.id.count()) ?? 0);

    final notesCount =
        await (selectOnly(db.notes)
              ..addColumns([db.notes.id.count()])
              ..where(db.notes.categoryId.equals(categoryId))
              ..where(db.notes.isDeleted.equals(false)))
            .getSingle()
            .then((row) => row.read(db.notes.id.count()) ?? 0);

    final filesCount =
        await (selectOnly(db.files)
              ..addColumns([db.files.id.count()])
              ..where(db.files.categoryId.equals(categoryId))
              ..where(db.files.isDeleted.equals(false)))
            .getSingle()
            .then((row) => row.read(db.files.id.count()) ?? 0);

    final bankCardsCount =
        await (selectOnly(db.bankCards)
              ..addColumns([db.bankCards.id.count()])
              ..where(db.bankCards.categoryId.equals(categoryId))
              ..where(db.bankCards.isDeleted.equals(false)))
            .getSingle()
            .then((row) => row.read(db.bankCards.id.count()) ?? 0);

    final otpsCount =
        await (selectOnly(db.otps)
              ..addColumns([db.otps.id.count()])
              ..where(db.otps.categoryId.equals(categoryId))
              ..where(db.otps.isDeleted.equals(false)))
            .getSingle()
            .then((row) => row.read(db.otps.id.count()) ?? 0);

    return passwordsCount +
        notesCount +
        filesCount +
        bankCardsCount +
        otpsCount;
  }

  /// Получить все категории
  Future<List<CategoriesData>> getAllCategories() {
    return select(categories).get();
  }

  /// Получить категорию по ID
  Future<CategoriesData?> getCategoryById(String id) {
    return (select(
      categories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  /// Получить категории в виде карточек
  Future<List<CategoryCardDto>> getAllCategoryCards() async {
    final categoriesList = await (select(
      categories,
    )..orderBy([(c) => OrderingTerm.asc(c.name)])).get();

    final result = <CategoryCardDto>[];
    for (final category in categoriesList) {
      final itemsCount = await countItemsInCategory(category.id);
      result.add(
        CategoryCardDto(
          id: category.id,
          name: category.name,
          type: category.type.value,
          color: category.color,
          iconId: category.iconId,
          itemsCount: itemsCount,
        ),
      );
    }
    return result;
  }

  /// Смотреть все категории с автообновлением
  Stream<List<CategoriesData>> watchAllCategories() {
    return (select(
      categories,
    )..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();
  }

  /// Смотреть категории карточки с автообновлением
  Stream<List<CategoryCardDto>> watchCategoryCards() {
    return (select(categories)..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch()
        .asyncMap((categoriesList) async {
          final result = <CategoryCardDto>[];
          for (final category in categoriesList) {
            final itemsCount = await countItemsInCategory(category.id);
            result.add(
              CategoryCardDto(
                id: category.id,
                name: category.name,
                type: category.type.value,
                color: category.color,
                iconId: category.iconId,
                itemsCount: itemsCount,
              ),
            );
          }
          return result;
        });
  }

  /// Создать новую категорию
  Future<String> createCategory(CreateCategoryDto dto) async {
    final id = const Uuid()
        .v4(); // Генерируем уникальный ID для новой категории
    final companion = CategoriesCompanion.insert(
      id: Value(id),
      name: dto.name,
      type: CategoryTypeX.fromString(dto.type),
      description: Value(dto.description),
      color: Value(dto.color ?? 'FFFFFF'),
      iconId: Value(dto.iconId),
    );
    await into(categories).insert(companion);
    return id;
  }

  /// Обновить категорию
  Future<bool> updateCategory(String id, UpdateCategoryDto dto) {
    final companion = CategoriesCompanion(
      name: dto.name != null ? Value(dto.name!) : const Value.absent(),
      description: dto.description != null
          ? Value(dto.description)
          : const Value.absent(),
      color: dto.color != null ? Value(dto.color!) : const Value.absent(),
      iconId: dto.iconId != null ? Value(dto.iconId) : const Value.absent(),
      modifiedAt: Value(DateTime.now()),
    );

    final query = update(categories)..where((c) => c.id.equals(id));
    return query.write(companion).then((rowsAffected) => rowsAffected > 0);
  }

  /// Получить категории по типу
  Stream<List<CategoryCardDto>> watchCategoriesByType(String type) {
    return (select(categories)
          ..where((c) => c.type.equals(type))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch()
        .asyncMap((categoriesList) async {
          final result = <CategoryCardDto>[];
          for (final category in categoriesList) {
            final itemsCount = await countItemsInCategory(category.id);
            result.add(
              CategoryCardDto(
                id: category.id,
                name: category.name,
                type: category.type.value,
                color: category.color,
                iconId: category.iconId,
                itemsCount: itemsCount,
              ),
            );
          }
          return result;
        });
  }

  /// Получить категории с пагинацией
  Future<List<CategoryCardDto>> getCategoryCardsPaginated({
    required int limit,
    required int offset,
  }) async {
    final categoriesList =
        await (select(categories)
              ..orderBy([(c) => OrderingTerm.asc(c.name)])
              ..limit(limit, offset: offset))
            .get();

    final result = <CategoryCardDto>[];
    for (final category in categoriesList) {
      final itemsCount = await countItemsInCategory(category.id);
      result.add(
        CategoryCardDto(
          id: category.id,
          name: category.name,
          type: category.type.value,
          color: category.color,
          iconId: category.iconId,
          itemsCount: itemsCount,
        ),
      );
    }
    return result;
  }

  /// Удалить категорию
  Future<bool> deleteCategory(String id) async {
    final rowsAffected = await (delete(
      categories,
    )..where((c) => c.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Получить отфильтрованные категории
  Future<List<CategoriesData>> getCategoriesFiltered(CategoriesFilter filter) {
    var query = select(categories);

    // Фильтр по поисковому запросу (название)
    if (filter.query.isNotEmpty) {
      query = query..where((c) => c.name.like('%${filter.query}%'));
    }

    // Фильтр по типу
    if (filter.type != null) {
      query = query..where((c) => c.type.equals(filter.type!));
    }

    // Фильтр по цвету
    if (filter.color != null) {
      query = query..where((c) => c.color.equals(filter.color!));
    }

    // Фильтр по наличию иконки
    if (filter.hasIcon != null) {
      if (filter.hasIcon!) {
        query = query..where((c) => c.iconId.isNotNull());
      } else {
        query = query..where((c) => c.iconId.isNull());
      }
    }

    // Фильтр по наличию описания
    if (filter.hasDescription != null) {
      if (filter.hasDescription!) {
        query = query..where((c) => c.description.isNotNull());
      } else {
        query = query..where((c) => c.description.isNull());
      }
    }

    // Фильтр по дате создания
    if (filter.createdAfter != null) {
      query = query
        ..where((c) => c.createdAt.isBiggerThanValue(filter.createdAfter!));
    }
    if (filter.createdBefore != null) {
      query = query
        ..where((c) => c.createdAt.isSmallerThanValue(filter.createdBefore!));
    }

    // Фильтр по дате изменения
    if (filter.modifiedAfter != null) {
      query = query
        ..where((c) => c.modifiedAt.isBiggerThanValue(filter.modifiedAfter!));
    }
    if (filter.modifiedBefore != null) {
      query = query
        ..where((c) => c.modifiedAt.isSmallerThanValue(filter.modifiedBefore!));
    }

    // Сортировка
    query = query..orderBy([(c) => _getSortOrderByTerm(filter.sortField)]);

    // Пагинация
    if (filter.limit != null && filter.limit! > 0) {
      query = query..limit(filter.limit!, offset: filter.offset ?? 0);
    }

    return query.get();
  }

  /// Смотреть отфильтрованные категории с автообновлением
  Stream<List<CategoriesData>> watchCategoriesFiltered(
    CategoriesFilter filter,
  ) {
    var query = select(categories);

    // Фильтр по поисковому запросу (название)
    if (filter.query.isNotEmpty) {
      query = query..where((c) => c.name.like('%${filter.query}%'));
    }

    // Фильтр по типу
    if (filter.type != null) {
      query = query..where((c) => c.type.equals(filter.type!));
    }

    // Фильтр по цвету
    if (filter.color != null) {
      query = query..where((c) => c.color.equals(filter.color!));
    }

    // Фильтр по наличию иконки
    if (filter.hasIcon != null) {
      if (filter.hasIcon!) {
        query = query..where((c) => c.iconId.isNotNull());
      } else {
        query = query..where((c) => c.iconId.isNull());
      }
    }

    // Фильтр по наличию описания
    if (filter.hasDescription != null) {
      if (filter.hasDescription!) {
        query = query..where((c) => c.description.isNotNull());
      } else {
        query = query..where((c) => c.description.isNull());
      }
    }

    // Фильтр по дате создания
    if (filter.createdAfter != null) {
      query = query
        ..where((c) => c.createdAt.isBiggerThanValue(filter.createdAfter!));
    }
    if (filter.createdBefore != null) {
      query = query
        ..where((c) => c.createdAt.isSmallerThanValue(filter.createdBefore!));
    }

    // Фильтр по дате изменения
    if (filter.modifiedAfter != null) {
      query = query
        ..where((c) => c.modifiedAt.isBiggerThanValue(filter.modifiedAfter!));
    }
    if (filter.modifiedBefore != null) {
      query = query
        ..where((c) => c.modifiedAt.isSmallerThanValue(filter.modifiedBefore!));
    }

    // Сортировка
    query = query..orderBy([(c) => _getSortOrderByTerm(filter.sortField)]);

    // Пагинация
    if (filter.limit != null && filter.limit! > 0) {
      query = query..limit(filter.limit!, offset: filter.offset ?? 0);
    }

    return query.watch();
  }

  /// Получить отфильтрованные категории в виде карточек
  Future<List<CategoryCardDto>> getCategoryCardsFiltered(
    CategoriesFilter filter,
  ) async {
    final categoriesList = await getCategoriesFiltered(filter);
    final result = <CategoryCardDto>[];
    for (final category in categoriesList) {
      final itemsCount = await countItemsInCategory(category.id);
      result.add(
        CategoryCardDto(
          id: category.id,
          name: category.name,
          type: category.type.value,
          color: category.color,
          iconId: category.iconId,
          itemsCount: itemsCount,
        ),
      );
    }
    return result;
  }

  /// Смотреть отфильтрованные категории карточки с автообновлением
  Stream<List<CategoryCardDto>> watchCategoryCardsFiltered(
    CategoriesFilter filter,
  ) {
    return watchCategoriesFiltered(filter).asyncMap((categoriesList) async {
      final result = <CategoryCardDto>[];
      for (final category in categoriesList) {
        final itemsCount = await countItemsInCategory(category.id);
        result.add(
          CategoryCardDto(
            id: category.id,
            name: category.name,
            type: category.type.value,
            color: category.color,
            iconId: category.iconId,
            itemsCount: itemsCount,
          ),
        );
      }
      return result;
    });
  }

  /// Получить тип сортировки для Drift
  OrderingTerm _getSortOrderByTerm(CategoriesSortField sortField) {
    switch (sortField) {
      case CategoriesSortField.name:
        return OrderingTerm.asc(categories.name);
      case CategoriesSortField.type:
        return OrderingTerm.asc(categories.type);
      case CategoriesSortField.createdAt:
        return OrderingTerm.asc(categories.createdAt);
      case CategoriesSortField.modifiedAt:
        return OrderingTerm.asc(categories.modifiedAt);
    }
  }
}
