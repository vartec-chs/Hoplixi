import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';

/// Элемент списка категорий в пикере.
///
/// Поддерживает корневые и вложенные категории (отступ и отображение родителя).
class CategoryPickerItem extends StatelessWidget {
  const CategoryPickerItem({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
    this.parentName,
    this.depth = 0,
  });

  final CategoryCardDto category;
  final bool isSelected;
  final VoidCallback onTap;

  /// Имя родительской категории (для подкатегорий)
  final String? parentName;

  /// Глубина вложенности (0 — корневая)
  final int depth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryColor = _parseColor(category.color);

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withOpacity(0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16.0 + depth * 20.0,
            right: 16,
            top: 12,
            bottom: 12,
          ),
          child: Row(
            children: [
              // Если это подкатегория — вертикальная линия-индентор
              if (depth > 0) ...[
                SizedBox(
                  width: 4,
                  height: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Цветной индикатор
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Иконка категории (если есть)
              if (category.iconId != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.category_outlined,
                    color: categoryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Информация о категории
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (parentName != null) ...[
                          Icon(
                            Icons.subdirectory_arrow_right,
                            size: 12,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            parentName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          category.type,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        if (category.itemsCount > 0) ...[
                          Text(
                            ' • ${category.itemsCount} элементов',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Индикатор выбора
              if (isSelected)
                Icon(Icons.check_circle, color: colorScheme.primary, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return Colors.grey;
    try {
      final hexCode = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}
