import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/store_settings/providers/store_settings_provider.dart';

/// Секция выбора закреплённых типов сущностей в entity_type_dropdown.
/// Если ничего не выбрано — отображаются все типы.
class PinnedEntityTypesSelector extends ConsumerWidget {
  const PinnedEntityTypesSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeSettingsProvider);
    final notifier = ref.read(storeSettingsProvider.notifier);
    final theme = Theme.of(context);

    // Если список пустой — значит «показывать все»
    final selected = state.newPinnedEntityTypes.toSet();
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
              onPressed: state.isSaving
                  ? null
                  : () => notifier.updatePinnedEntityTypes(const []),
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
          children: EntityType.allTypes.map((type) {
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
              onSelected: state.isSaving
                  ? null
                  : (checked) {
                      final current = state.newPinnedEntityTypes.toSet();
                      // Если сейчас «все выбраны» (пустой список) — при снятии
                      // чипа переходим в явный режим: все, кроме снятого.
                      final base = current.isEmpty
                          ? EntityType.allTypes.map((t) => t.id).toSet()
                          : current;

                      final updated = checked
                          ? {...base, type.id}
                          : base.difference({type.id});

                      // Если отмечены все — храним пустой список
                      final allIds = EntityType.allTypes
                          .map((t) => t.id)
                          .toSet();
                      final result = updated.containsAll(allIds)
                          ? <String>[]
                          : updated.toList();

                      notifier.updatePinnedEntityTypes(result);
                    },
            );
          }).toList(),
        ),
      ],
    );
  }
}
