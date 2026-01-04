import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/tags_manager/features/tags_picker/providers/tag_filter_provider.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:hoplixi/shared/ui/type_chip.dart';

/// Панель фильтров для пикера тегов
class TagPickerFilters extends ConsumerWidget {
  const TagPickerFilters({
    super.key,
    this.filterByType,
    this.selectedCount = 0,
    this.maxCount,
  });

  /// Фиксированный тип для фильтрации (если задан, выбор типа скрыт)
  final String? filterByType;

  /// Количество выбранных тегов
  final int selectedCount;

  /// Максимальное количество тегов (если задано)
  final int? maxCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(tagPickerFilterProvider);
    final filterNotifier = ref.read(tagPickerFilterProvider.notifier);
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
                    hintText: 'Поиск тега...',
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
              // Счетчик выбранных тегов
              if (selectedCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    maxCount != null
                        ? '$selectedCount / $maxCount'
                        : '$selectedCount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Фильтр по типу (скрываем если filterByType задан)
          if (filterByType == null) ...[
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
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
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
                          isSelected: filter.type == TagType.password.value,
                          onTap: () =>
                              filterNotifier.updateType(TagType.password.value),
                        ),
                        const SizedBox(width: 8),
                        TypeChip(
                          label: 'Банковские карты',
                          isSelected: filter.type == TagType.bankCard.value,
                          onTap: () =>
                              filterNotifier.updateType(TagType.bankCard.value),
                        ),
                        const SizedBox(width: 8),
                        TypeChip(
                          label: 'Заметки',
                          isSelected: filter.type == TagType.note.value,
                          onTap: () =>
                              filterNotifier.updateType(TagType.note.value),
                        ),
                        const SizedBox(width: 8),
                        TypeChip(
                          label: 'Файлы',
                          isSelected: filter.type == TagType.file.value,
                          onTap: () =>
                              filterNotifier.updateType(TagType.file.value),
                        ),
                        const SizedBox(width: 8),
                        TypeChip(
                          label: 'Mixed',
                          isSelected: filter.type == TagType.mixed.value,
                          onTap: () =>
                              filterNotifier.updateType(TagType.mixed.value),
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
