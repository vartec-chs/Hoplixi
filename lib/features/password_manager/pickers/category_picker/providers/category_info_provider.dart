import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';

/// Базовая информация о категории для отображения в полях
class CategoryBasicInfo {
  final String id;
  final String name;
  final int color;
  final String? iconRefId;

  const CategoryBasicInfo({
    required this.id,
    required this.name,
    required this.color,
    this.iconRefId,
  });

  factory CategoryBasicInfo.fromCategoryCard(CategoryCardDto dto) {
    return CategoryBasicInfo(
      id: dto.id,
      name: dto.name,
      color: dto.color,
      iconRefId: dto.iconRefId,
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
        final repos = await ref.watch(vaultRepositories.future);
        final result = await repos.category.getCategory(categoryId);
        final category = result.getOrNull()?.getOrNull();
        return category == null
            ? null
            : CategoryBasicInfo(
                id: category.id,
                name: category.name,
                color: category.color,
                iconRefId: category.iconRefId,
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
        final repos = await ref.watch(vaultRepositories.future);
        final results = <CategoryBasicInfo>[];

        for (final id in categoryIds) {
          final result = await repos.category.getCategory(id);
          final category = result.getOrNull()?.getOrNull();
          if (category != null) {
            results.add(
              CategoryBasicInfo(
                id: category.id,
                name: category.name,
                color: category.color,
                iconRefId: category.iconRefId,
              ),
            );
          }
        }

        return results;
      } catch (e) {
        return [];
      }
    });
