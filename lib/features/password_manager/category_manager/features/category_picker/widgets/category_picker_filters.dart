import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/providers/category_filter_provider.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:hoplixi/shared/ui/type_chip.dart';

/// Панель фильтров для пикера категорий
class CategoryPickerFilters extends ConsumerWidget {
  const CategoryPickerFilters({
    super.key,
    this.hideTypeFilter = false,
    this.selectedCount = 0,
  });

  /// Скрыть фильтр по типу (используется когда тип уже задан извне)
  final bool hideTypeFilter;

  /// Количество выбранных категорий
  final int selectedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(categoryPickerFilterProvider);
    final filterNotifier = ref.read(categoryPickerFilterProvider.notifier);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Строка с поиском и счетчиком
          Row(
            children: [
              // Поле поиска
              Expanded(
                child: TextField(
                  decoration: primaryInputDecoration(
                    context,
                    hintText: 'Поиск категории...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: filter.query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => filterNotifier.updateQuery(''),
                          )
                        : null,
                  ),
                  onChanged: filterNotifier.updateQuery,
                ),
              ),
              // Счетчик выбранных категорий
              if (selectedCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$selectedCount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Фильтр по типу (скрываем если hideTypeFilter = true)
          if (!hideTypeFilter) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        TypeChip(
                          label: 'Все',
                          isSelected: filter.types.isEmpty,
                          onTap: () => filterNotifier.updateType([]),
                        ),
                        const SizedBox(width: 8),
                        TypeChip(
                          label: 'Пароли',
                          isSelected: filter.types.contains(
                            CategoryType.password,
                          ),
                          onTap: () => filterNotifier.updateType([
                            CategoryType.password,
                          ]),
                        ),
                        const SizedBox(width: 8),
                        TypeChip(
                          label: 'Банковские карты',
                          isSelected: filter.types.contains(
                            CategoryType.bankCard,
                          ),
                          onTap: () => filterNotifier.updateType([
                            CategoryType.bankCard,
                          ]),
                        ),
                        const SizedBox(width: 8),
                        TypeChip(
                          label: 'Заметки',
                          isSelected: filter.types.contains(CategoryType.note),
                          onTap: () =>
                              filterNotifier.updateType([CategoryType.note]),
                        ),
                        const SizedBox(width: 8),
                        TypeChip(
                          label: 'Файлы',
                          isSelected: filter.types.contains(CategoryType.file),
                          onTap: () =>
                              filterNotifier.updateType([CategoryType.file]),
                        ),
                        const SizedBox(width: 8),
                        TypeChip(
                          label: 'Mixed',
                          isSelected: filter.types.contains(CategoryType.mixed),
                          onTap: () =>
                              filterNotifier.updateType([CategoryType.mixed]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
