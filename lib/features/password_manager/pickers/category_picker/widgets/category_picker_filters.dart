import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/providers/category_filter_provider.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Панель фильтров для пикера категорий
class CategoryPickerFilters extends ConsumerWidget {
  const CategoryPickerFilters({super.key, this.selectedCount = 0});

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
        ],
      ),
    );
  }
}
