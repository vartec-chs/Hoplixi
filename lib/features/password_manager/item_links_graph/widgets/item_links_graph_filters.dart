import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/item_links_graph/widgets/item_link_type_label.dart';
import 'package:hoplixi/vault_db/core/models/item_links_graph/item_links_graph_models.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/system/item_link/item_links.dart';

class ItemLinksGraphFilters extends StatelessWidget {
  const ItemLinksGraphFilters({
    super.key,
    required this.mode,
    required this.onModeChanged,
  });

  final ItemLinksGraphMode mode;
  final ValueChanged<ItemLinksGraphMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedTypes = switch (mode) {
      AllItemLinksGraphMode() => <ItemLinkType>{},
      RelationTypesItemLinksGraphMode(:final relationTypes) => relationTypes,
    };
    final isAll = mode is AllItemLinksGraphMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                icon: Icon(Icons.hub_outlined),
                label: Text('Все связи'),
              ),
              ButtonSegment(
                value: false,
                icon: Icon(Icons.filter_alt_outlined),
                label: Text('По типам'),
              ),
            ],
            selected: {isAll},
            onSelectionChanged: (selection) {
              final nextIsAll = selection.first;
              onModeChanged(
                nextIsAll
                    ? const AllItemLinksGraphMode()
                    : RelationTypesItemLinksGraphMode(selectedTypes),
              );
            },
          ),
          if (!isAll) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final type in ItemLinkType.values) ...[
                    FilterChip(
                      label: Text(itemLinkTypeLabel(type)),
                      selected: selectedTypes.contains(type),
                      onSelected: (selected) {
                        final nextTypes = {...selectedTypes};
                        if (selected) {
                          nextTypes.add(type);
                        } else {
                          nextTypes.remove(type);
                        }
                        onModeChanged(
                          RelationTypesItemLinksGraphMode(nextTypes),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            if (selectedTypes.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'SQL-запрос не выполняется, пока не выбран тип связи.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
