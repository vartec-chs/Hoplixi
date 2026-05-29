import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/shared/widgets/icon_ref_preview.dart';

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
    final categoryColor = Color(0xFF000000 | category.color);

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
              if (category.iconRefId != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconRefPreview(
                    fallbackIcon: Icons.category_outlined,
                    size: 20,
                    color: categoryColor,
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
                          'Категория',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
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

}
