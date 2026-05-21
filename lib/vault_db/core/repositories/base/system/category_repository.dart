import 'package:hoplixi/vault_db/core/models/field_update.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import 'package:hoplixi/vault_db/core/vault_db.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/system/category_dto.dart';
import '../../../models/mappers/system/category_mapper.dart';

class CategoryRepository {
  final VaultDB db;

  CategoryRepository(this.db);

  AsyncDbResult<String> createCategory(CreateCategoryDto dto) {
    return ResultUtils.tryCatchAsync(
      () async {
        final name = dto.name.trim();
        if (name.isEmpty) {
          throw const DBCoreError.validation(
            code: 'category.name_empty',
            message: 'Category name cannot be empty',
          );
        }

        if (dto.parentId != null) {
          final parentExists = await db.categoriesDao.existsCategory(
            dto.parentId!,
          );
          if (!parentExists) {
            throw DBCoreError.notFound(
              entity: 'categories',
              id: dto.parentId!,
              message: 'Parent category not found',
            );
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
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании категории',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> updateCategory(PatchCategoryDto dto) {
    return ResultUtils.tryCatchAsync(
      () async {
        if (dto.name is FieldUpdateSet<String>) {
          final name = (dto.name as FieldUpdateSet<String>).value;
          if (name != null && name.trim().isEmpty) {
            throw const DBCoreError.validation(
              code: 'category.name_empty',
              message: 'Category name cannot be empty',
            );
          }
        }

        final parentIdUpdate = dto.parentId;
        if (parentIdUpdate is FieldUpdateSet<String>) {
          final parentId = parentIdUpdate.value;
          if (parentId != null) {
            if (parentId == dto.id) {
              throw const DBCoreError.validation(
                code: 'category.self_parent',
                message: 'Category cannot be its own parent',
              );
            }

            final parentExists = await db.categoriesDao.existsCategory(parentId);
            if (!parentExists) {
              throw DBCoreError.notFound(
                entity: 'categories',
                id: parentId,
                message: 'Parent category not found',
              );
            }

            String? currentParentId = parentId;
            while (currentParentId != null) {
              if (currentParentId == dto.id) {
                throw const DBCoreError.validation(
                  code: 'category.cycle_detected',
                  message: 'Category tree cycle detected',
                );
              }
              final parent = await db.categoriesDao.getCategoryById(
                currentParentId,
              );
              currentParentId = parent?.parentId;
            }
          }
        }

        final count = await db.categoriesDao.updateCategoryById(
          dto.id,
          CategoriesCompanion(
            name: dto.name.toRequiredValue(),
            description: dto.description.toNullableValue(),
            iconRefId: dto.iconRefId.toNullableValue(),
            color: dto.color.toRequiredValue(),
            type: dto.type.toRequiredValue(),
            parentId: dto.parentId.toNullableValue(),
            modifiedAt: drift.Value(DateTime.now()),
          ),
        );

        if (count == 0) {
          throw DBCoreError.notFound(entity: 'categories', id: dto.id);
        }
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при обновлении категории',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> deleteCategory(String categoryId) {
    return ResultUtils.tryCatchAsync(
      () async {
        await db.categoriesDao.deleteCategoryById(categoryId);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при удалении категории',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<CategoryViewDto>> getCategory(String categoryId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final row = await db.categoriesDao.getCategoryById(categoryId);
        return Optional.fromNullable(row?.toCategoryViewDto());
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении категории',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<CategoryCardDto>> getAllCategories() {
    return ResultUtils.tryCatchAsync(
      () async {
        final rows = await db.categoriesDao.getAllCategories();
        return rows.map((r) => r.toCategoryCardDto()).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении списка категорий',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<CategoryTreeNodeDto>> getCategoryTree() {
    return ResultUtils.tryCatchAsync(
      () async {
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
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при построении дерева категорий',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<bool> existsCategory(String categoryId) {
    return ResultUtils.tryCatchAsync(
      () => db.categoriesDao.existsCategory(categoryId),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при проверке существования категории',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}

