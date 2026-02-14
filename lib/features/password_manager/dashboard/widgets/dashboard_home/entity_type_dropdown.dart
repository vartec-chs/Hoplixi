import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/theme/index.dart';

import '../../models/entity_type.dart';

/// Компактный выпадающий список для выбора типа сущности
/// Используется в AppBar для переключения между типами
class EntityTypeCompactDropdown extends StatelessWidget {
  /// Callback при изменении типа сущности
  final ValueChanged<EntityType>? onEntityTypeChanged;

  /// Показывать иконки в выпадающем списке
  final bool showIcons;

  /// Пользовательский стиль текста
  final TextStyle? textStyle;

  const EntityTypeCompactDropdown({
    super.key,
    this.onEntityTypeChanged,
    this.showIcons = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Получаем текущий тип из пути
    final pathParams = GoRouterState.of(context).pathParameters;
    final entityId = pathParams['entity'];
    final currentType =
        EntityType.fromId(entityId ?? '') ?? EntityType.password;

    // Получаем все доступные типы
    final availableTypes = EntityType.allTypes;

    if (availableTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    final fillColor = AppColors.getInputFieldBackgroundColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButton<EntityType>(
        value: currentType,
        underline: const SizedBox.shrink(),
        isDense: true,
        icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface),
        style:
            textStyle ??
            theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        borderRadius: BorderRadius.circular(12),
        dropdownColor: fillColor,
        items: availableTypes.map((type) {
          return DropdownMenuItem<EntityType>(
            value: type,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIcons) ...[
                  Icon(type.icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(type.label),
              ],
            ),
          );
        }).toList(),
        onChanged: (EntityType? newType) {
          if (newType != null && newType != currentType) {
            logInfo(
              'EntityTypeCompactDropdown: Изменен тип сущности',
              data: {'from': currentType.id, 'to': newType.id},
            );

            // Навигация с помощью Go Router
            context.go('/dashboard/${newType.id}');

            // Вызываем callback
            onEntityTypeChanged?.call(newType);
          }
        },
      ),
    );
  }
}

/// Расширенный выпадающий список для выбора типа сущности
/// Используется на главном экране или в настройках
class EntityTypeFullDropdown extends StatelessWidget {
  /// Callback при изменении типа сущности
  final ValueChanged<EntityType>? onEntityTypeChanged;

  /// Заголовок
  final String? label;

  /// Показывать описания типов
  final bool showDescriptions;

  const EntityTypeFullDropdown({
    super.key,
    this.onEntityTypeChanged,
    this.label,
    this.showDescriptions = false,
  });

  String _getTypeDescription(EntityType type) {
    switch (type) {
      case EntityType.password:
        return 'Логины, пароли и учетные записи';
      case EntityType.note:
        return 'Текстовые заметки и записи';
      case EntityType.bankCard:
        return 'Банковские карты и платежные данные';
      case EntityType.file:
        return 'Защищенные файлы и документы';
      case EntityType.otp:
        return 'Коды двухфакторной аутентификации';
      case EntityType.document:
        return 'Сканированные и цифровые документы';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Получаем текущий тип из пути
    final pathParams = GoRouterState.of(context).pathParameters;
    final entityId = pathParams['entity'];
    final currentType =
        EntityType.fromId(entityId ?? '') ?? EntityType.password;

    // Получаем все доступные типы
    final availableTypes = EntityType.allTypes;

    if (availableTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: DropdownButton<EntityType>(
            value: currentType,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurface,
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            borderRadius: BorderRadius.circular(12),
            dropdownColor: theme.colorScheme.surfaceContainerHighest,
            items: availableTypes.map((type) {
              return DropdownMenuItem<EntityType>(
                value: type,
                child: Row(
                  children: [
                    Icon(type.icon, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            type.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (showDescriptions) ...[
                            const SizedBox(height: 2),
                            Text(
                              _getTypeDescription(type),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (EntityType? newType) {
              if (newType != null && newType != currentType) {
                logInfo(
                  'EntityTypeFullDropdown: Изменен тип сущности',
                  data: {'from': currentType.id, 'to': newType.id},
                );

                // Навигация с помощью Go Router
                context.go('/dashboard/${newType.id}');

                // Вызываем callback
                onEntityTypeChanged?.call(newType);
              }
            },
          ),
        ),
      ],
    );
  }
}
