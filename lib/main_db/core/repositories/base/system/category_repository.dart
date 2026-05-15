import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../../../main_store.dart';
import '../../../models/dto/system/category_dto.dart';
import '../../../models/mappers/system/category_mapper.dart';

class CategoryRepository {
  final MainStore db;

  CategoryRepository(this.db);

  Future<String> createCategory(CreateCategoryDto dto) async {
    final name = dto.name.trim();
    if (name.isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    if (dto.parentId != null) {
      final parentExists = await db.categoriesDao.existsCategory(dto.parentId!);
      if (!parentExists) {
        throw ArgumentError('Parent category not found');
      }
    }

    final id = const Uuid().v4();
    final now = DateTime.now();

    await db.categoriesDao.insertCategory(
      CategoriesCompanion.insert(
        id: drift.Value(id),
        name: name,
        description: drift.Value(dto.description),
        iconRefId: drift.Value(dto.iconRefId),
        color: drift.Value(dto.color),
        type: dto.type,
        parentId: drift.Value(dto.parentId),
        createdAt: drift.Value(now),
        modifiedAt: drift.Value(now),
      ),
    );

    return id;
  }

  Future<void> updateCategory(UpdateCategoryDto dto) async {
    if (dto.name != null && dto.name!.trim().isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    if (dto.parentId != null) {
      if (dto.parentId == dto.id) {
        throw ArgumentError('Category cannot be its own parent');
      }

      final parentExists = await db.categoriesDao.existsCategory(dto.parentId!);
      if (!parentExists) {
        throw ArgumentError('Parent category not found');
      }

      var currentParentId = dto.parentId;
      while (currentParentId != null) {
        if (currentParentId == dto.id) {
          throw ArgumentError('Category tree cycle detected');
        }
        final parent = await db.categoriesDao.getCategoryById(currentParentId);
        currentParentId = parent?.parentId;
      }
    }

    await db.categoriesDao.updateCategoryById(
      dto.id,
      CategoriesCompanion(
        name: dto.name != null ? drift.Value(dto.name!.trim()) : const drift.Value.absent(),
        description: dto.description != null ? drift.Value(dto.description) : const drift.Value.absent(),
        iconRefId: dto.iconRefId != null ? drift.Value(dto.iconRefId) : const drift.Value.absent(),
        color: dto.color != null ? drift.Value(dto.color!) : const drift.Value.absent(),
        type: dto.type != null ? drift.Value(dto.type!) : const drift.Value.absent(),
        parentId: dto.parentId != null ? drift.Value(dto.parentId) : const drift.Value.absent(),
        modifiedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteCategory(String categoryId) {
    return db.categoriesDao.deleteCategoryById(categoryId);
  }

  Future<CategoryViewDto?> getCategory(String categoryId) async {
    final row = await db.categoriesDao.getCategoryById(categoryId);
    return row?.toCategoryViewDto();
  }

  Future<List<CategoryCardDto>> getAllCategories() async {
    final rows = await db.categoriesDao.getAllCategories();
    return rows.map((r) => r.toCategoryCardDto()).toList();
  }

  Future<List<CategoryTreeNodeDto>> getCategoryTree() async {
    final allCategories = await db.categoriesDao.getAllCategories();
    final Map<String, List<CategoriesData>> childrenMap = {};
    final List<CategoriesData> rootNodes = [];

    for (final cat in allCategories) {
      if (cat.parentId == null) {
        rootNodes.add(cat);
      } else {
        childrenMap.putIfAbsent(cat.parentId!, () => []).add(cat);
      }
    }

    CategoryTreeNodeDto buildTree(CategoriesData node) {
      final childrenData = childrenMap[node.id] ?? [];
      final children = childrenData.map((c) => buildTree(c)).toList();
      return CategoryTreeNodeDto(
        category: node.toCategoryCardDto(),
        children: children,
      );
    }

    return rootNodes.map((n) => buildTree(n)).toList();
  }

  Future<bool> existsCategory(String categoryId) {
    return db.categoriesDao.existsCategory(categoryId);
  }
}
