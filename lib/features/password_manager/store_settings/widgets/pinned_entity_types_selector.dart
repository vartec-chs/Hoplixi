import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';

/// Секция выбора закреплённых типов сущностей.
/// Если ничего не выбрано — отображаются все типы.
class PinnedEntityTypesSelector extends StatelessWidget {
  final List<String> selectedEntityTypeIds;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  const PinnedEntityTypesSelector({
    super.key,
    required this.selectedEntityTypeIds,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Если список пустой — значит «показывать все»
    final selected = selectedEntityTypeIds.toSet();
    final allSelected = selected.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Типы записей в панели навигации',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: enabled ? () => onChanged(const []) : null,
              child: Text(
                allSelected ? 'Все выбраны' : 'Выбрать все',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: allSelected
                      ? theme.colorScheme.outline
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Выберите типы, которые будут отображаться в выпадающем списке. '
          'Если ничего не отмечено — показываются все типы.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EntityType.values.map((type) {
            final isSelected = allSelected || selected.contains(type.id);
            return FilterChip(
              avatar: Icon(
                type.icon,
                size: 16,
                color: isSelected
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              label: Text(type.label),
              selected: isSelected,
              onSelected: enabled
                  ? (checked) {
                      final current = selected;
                      // Если сейчас «все выбраны» (пустой список) — при
                      // снятии чипа переходим в явный режим: все, кроме
                      // снятого.
                      final base = current.isEmpty
                          ? EntityType.values.map((t) => t.id).toSet()
                          : current;

                      final updated = checked
                          ? {...base, type.id}
                          : base.difference({type.id});

                      // Если отмечены все — храним пустой список.
                      final allIds = EntityType.values.map((t) => t.id).toSet();
                      final result = updated.containsAll(allIds)
                          ? <String>[]
                          : updated.toList();

                      onChanged(result);
                    }
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }
}
