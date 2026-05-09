import 'package:flutter/material.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';

import '../models/dashboard_view_mode.dart';
import 'entity_cards/dashboard_v2_entity_card_builder.dart';

final class DashboardV2ItemsView extends StatelessWidget {
  const DashboardV2ItemsView({
    required this.items,
    required this.viewMode,
    required this.selectedIds,
    required this.onOpen,
    required this.onToggleSelection,
    required this.onStartSelection,
    required this.onToggleFavorite,
    required this.onTogglePinned,
    required this.onToggleArchived,
    required this.onDelete,
    required this.onRestore,
    super.key,
  });

  final List<BaseCardDto> items;
  final DashboardViewMode viewMode;
  final Set<String> selectedIds;
  final ValueChanged<BaseCardDto> onOpen;
  final ValueChanged<String> onToggleSelection;
  final ValueChanged<String> onStartSelection;
  final ValueChanged<BaseCardDto> onToggleFavorite;
  final ValueChanged<BaseCardDto> onTogglePinned;
  final ValueChanged<BaseCardDto> onToggleArchived;
  final ValueChanged<BaseCardDto> onDelete;
  final ValueChanged<BaseCardDto> onRestore;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyDashboardList();

    if (viewMode.isGrid) {
      return SliverLayoutBuilder(
        builder: (context, constraints) {
          final columns = (constraints.crossAxisExtent / 360).floor().clamp(
            1,
            4,
          );
          return SliverGrid.builder(
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisExtent: 168,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) => _itemCard(items[index]),
          );
        },
      );
    }

    return SliverList.builder(
      itemCount: items.length * 2 - 1,
      itemBuilder: (context, index) {
        if (index.isOdd) return const SizedBox(height: 6);
        return _itemCard(items[index ~/ 2]);
      },
    );
  }

  Widget _itemCard(BaseCardDto item) {
    return DashboardV2EntityCardBuilder.build(
      item: item,
      viewMode: viewMode,
      selectedIds: selectedIds,
      actions: DashboardV2EntityCardActions(
        onOpen: onOpen,
        onToggleSelection: onToggleSelection,
        onStartSelection: onStartSelection,
        onToggleFavorite: onToggleFavorite,
        onTogglePinned: onTogglePinned,
        onToggleArchived: onToggleArchived,
        onDelete: onDelete,
        onRestore: onRestore,
      ),
    );
  }
}

final class _EmptyDashboardList extends StatelessWidget {
  const _EmptyDashboardList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ничего не найдено',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
