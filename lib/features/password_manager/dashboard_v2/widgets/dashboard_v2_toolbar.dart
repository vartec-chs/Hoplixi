import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/dashboard_entity_type.dart';
import '../models/dashboard_filter_tab.dart';
import '../models/dashboard_view_mode.dart';

final class DashboardV2Toolbar extends StatelessWidget {
  const DashboardV2Toolbar({
    required this.entityType,
    required this.query,
    required this.tab,
    required this.viewMode,
    required this.totalCount,
    required this.onEntityTypeChanged,
    required this.onQueryChanged,
    required this.onTabChanged,
    required this.onViewModeChanged,
    required this.onRefresh,
    super.key,
  });

  final DashboardEntityType entityType;
  final String query;
  final DashboardFilterTab tab;
  final DashboardViewMode viewMode;
  final int totalCount;
  final ValueChanged<DashboardEntityType> onEntityTypeChanged;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<DashboardFilterTab> onTabChanged;
  final ValueChanged<DashboardViewMode> onViewModeChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<DashboardEntityType>(
                value: entityType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Тип',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final type in DashboardEntityType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(type.icon, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(type.label)),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) onEntityTypeChanged(value);
                },
              ),
            ),
            SizedBox(
              width: 360,
              child: TextFormField(
                key: ValueKey(query),
                initialValue: query,
                onChanged: onQueryChanged,
                decoration: const InputDecoration(
                  labelText: 'Поиск',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SegmentedButton<DashboardViewMode>(
              segments: const [
                ButtonSegment(
                  value: DashboardViewMode.list,
                  icon: Icon(Icons.view_list),
                  tooltip: 'Список',
                ),
                ButtonSegment(
                  value: DashboardViewMode.grid,
                  icon: Icon(Icons.grid_view),
                  tooltip: 'Сетка',
                ),
              ],
              selected: {viewMode},
              onSelectionChanged: (value) => onViewModeChanged(value.first),
            ),
            IconButton.filledTonal(
              tooltip: 'Обновить',
              onPressed: onRefresh,
              icon: const Icon(LucideIcons.refreshCw),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<DashboardFilterTab>(
                  segments: [
                    for (final item in DashboardFilterTab.values)
                      ButtonSegment(value: item, label: Text(item.label)),
                  ],
                  selected: {tab},
                  onSelectionChanged: (value) => onTabChanged(value.first),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '$totalCount',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}
