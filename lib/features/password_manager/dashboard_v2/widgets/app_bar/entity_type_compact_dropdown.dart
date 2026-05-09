import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/theme/theme.dart';

import '../../models/dashboard_entity_type.dart';

final class DashboardV2EntityTypeCompactDropdown extends ConsumerWidget {
  const DashboardV2EntityTypeCompactDropdown({
    required this.currentType,
    required this.onEntityTypeChanged,
    super.key,
    this.showIcons = true,
    this.textStyle,
  });

  final DashboardEntityType currentType;
  final ValueChanged<DashboardEntityType> onEntityTypeChanged;
  final bool showIcons;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fillColor = AppColors.getInputFieldBackgroundColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButton<DashboardEntityType>(
        value: currentType,
        underline: const SizedBox.shrink(),
        isDense: true,
        icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface),
        style:
            textStyle ??
            theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        borderRadius: BorderRadius.circular(12),
        dropdownColor: fillColor,
        menuMaxHeight: MediaQuery.of(context).size.height * 0.8,
        items: [
          for (final type in DashboardEntityType.values)
            DropdownMenuItem<DashboardEntityType>(
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
            ),
        ],
        onChanged: (newType) {
          if (newType == null || newType == currentType) return;

          logInfo(
            'DashboardV2EntityTypeCompactDropdown: Изменен тип сущности',
            data: {'from': currentType.id, 'to': newType.id},
          );
          String newPath = '/dashboard/${newType.id}';
          if (GoRouterState.of(context).fullPath!.contains('/add')) {
            newPath += '/add';
          }
          context.go(newPath);
          onEntityTypeChanged(newType);
        },
      ),
    );
  }
}
