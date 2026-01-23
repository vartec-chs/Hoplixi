import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

/// Базовая информация о категории для отображения в полях
class CategoryBasicInfo {
  final String id;
  final String name;
  final String type;
  final String? color;
  final String? iconId;

  const CategoryBasicInfo({
    required this.id,
    required this.name,
    required this.type,
    this.color,
    this.iconId,
  });

  factory CategoryBasicInfo.fromCategoryCard(CategoryCardDto dto) {
    return CategoryBasicInfo(
      id: dto.id,
      name: dto.name,
      type: dto.type,
      color: dto.color,
      iconId: dto.iconId,
    );
  }
}

/// Провайдер для получения базовой информации о категории по ID
///
/// Использует .family для кэширования результатов по ID категории.
/// Автоматически освобождает ресурсы при dispose благодаря autoDispose.
final categoryInfoProvider = FutureProvider.autoDispose
    .family<CategoryBasicInfo?, String>((ref, categoryId) async {
      if (categoryId.isEmpty) return null;

      try {
        final categoryDao = await ref.watch(categoryDaoProvider.future);
        final category = await categoryDao.getCategoryById(categoryId);

        if (category == null) return null;

        return CategoryBasicInfo(
          id: category.id,
          name: category.name,
          type: category.type.value,
          color: category.color,
          iconId: category.iconId,
        );
      } catch (e) {
        return null;
      }
    });

/// Провайдер для получения базовой информации о нескольких категориях по списку ID
///
/// Полезен для режима фильтра с множественным выбором.
final categoriesInfoProvider = FutureProvider.autoDispose
    .family<List<CategoryBasicInfo>, List<String>>((ref, categoryIds) async {
      if (categoryIds.isEmpty) return [];

      try {
        final categoryDao = await ref.watch(categoryDaoProvider.future);
        final results = <CategoryBasicInfo>[];

        for (final id in categoryIds) {
          final category = await categoryDao.getCategoryById(id);
          if (category != null) {
            results.add(
              CategoryBasicInfo(
                id: category.id,
                name: category.name,
                type: category.type.value,
                color: category.color,
                iconId: category.iconId,
              ),
            );
          }
        }

        return results;
      } catch (e) {
        return [];
      }
    });
