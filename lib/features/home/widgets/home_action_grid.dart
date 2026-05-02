import 'package:flutter/material.dart';
import 'package:hoplixi/features/home/models/action_item.dart';
import 'package:hoplixi/features/home/widgets/action_button.dart';
import 'package:hoplixi/features/home/widgets/action_button_compact.dart';

class HomeActionGrid extends StatelessWidget {
  const HomeActionGrid({super.key, required this.items});

  final List<ActionItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 500;
        return isSmallScreen
            ? _CompactActionGrid(items: items)
            : _WideActionGrid(items: items);
      },
    );
  }
}

class _CompactActionGrid extends StatelessWidget {
  const _CompactActionGrid({required this.items});

  final List<ActionItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1,
      children: items
          .map(
            (item) => ActionButtonCompact(
              icon: item.icon,
              label: item.label,
              description: item.description,
              isPrimary: item.isPrimary,
              disabled: item.disabled,
              onTap: item.onTap,
            ),
          )
          .toList(),
    );
  }
}

class _WideActionGrid extends StatelessWidget {
  const _WideActionGrid({required this.items});

  final List<ActionItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.8,
      children: items
          .map(
            (item) => ActionButton(
              icon: item.icon,
              label: item.label,
              description: item.description,
              isPrimary: item.isPrimary,
              disabled: item.disabled,
              onTap: item.onTap,
            ),
          )
          .toList(),
    );
  }
}
