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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
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
                // Text(
                //   'Тип:',
                //   style: theme.textTheme.bodyMedium?.copyWith(
                //     fontWeight: FontWeight.w500,
                //   ),
                // ),
                // const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        TypeChip(
                          label: 'Все',
                          isSelected: filter.type == null,
                          onTap: () => filterNotifier.updateType(null),
                        ),
                        const SizedBox(width: 8),
                        TypeChip(
                          label: 'Пароли',
                          isSelected:
                              filter.type == CategoryType.password.value,
                          onTap: () => filterNotifier.updateType(
                            CategoryType.password.value,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TypeChip(
                          label: 'Банковские карты',
                          isSelected:
                              filter.type == CategoryType.bankCard.value,
                          onTap: () => filterNotifier.updateType(
                            CategoryType.bankCard.value,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TypeChip(
                          label: 'Заметки',
                          isSelected: filter.type == CategoryType.note.value,
                          onTap: () => filterNotifier.updateType(
                            CategoryType.note.value,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TypeChip(
                          label: 'Файлы',
                          isSelected: filter.type == CategoryType.file.value,
                          onTap: () => filterNotifier.updateType(
                            CategoryType.file.value,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TypeChip(
                          label: 'Mixed',
                          isSelected: filter.type == CategoryType.mixed.value,
                          onTap: () => filterNotifier.updateType(
                            CategoryType.mixed.value,
                          ),
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
