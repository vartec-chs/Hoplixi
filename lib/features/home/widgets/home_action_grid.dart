import 'package:flutter/material.dart';
import 'package:hoplixi/features/home/models/action_item.dart';
import 'package:hoplixi/features/home/widgets/action_button.dart';
import 'package:hoplixi/features/home/widgets/action_button_compact.dart';
import 'package:hoplixi/features/onboarding/presentation/custom_showcase_tooltip.dart';
import 'package:showcaseview/showcaseview.dart';

class HomeActionGrid extends StatelessWidget {
  const HomeActionGrid({super.key, required this.items, this.showcaseScope});

  final List<ActionItem> items;
  final String? showcaseScope;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 500;
        return isSmallScreen
            ? _CompactActionGrid(items: items, showcaseScope: showcaseScope)
            : _WideActionGrid(items: items, showcaseScope: showcaseScope);
      },
    );
  }
}

class _CompactActionGrid extends StatelessWidget {
  const _CompactActionGrid({required this.items, this.showcaseScope});

  final List<ActionItem> items;
  final String? showcaseScope;

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
            (item) => _wrapShowcase(
              context,
              item,
              showcaseScope,
              ActionButtonCompact(
                icon: item.icon,
                label: item.label,
                description: item.description,
                isPrimary: item.isPrimary,
                disabled: item.disabled,
                onTap: item.onTap,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _WideActionGrid extends StatelessWidget {
  const _WideActionGrid({required this.items, this.showcaseScope});

  final List<ActionItem> items;
  final String? showcaseScope;

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
            (item) => _wrapShowcase(
              context,
              item,
              showcaseScope,
              ActionButton(
                icon: item.icon,
                label: item.label,
                description: item.description,
                isPrimary: item.isPrimary,
                disabled: item.disabled,
                onTap: item.onTap,
              ),
            ),
          )
          .toList(),
    );
  }
}

Widget _wrapShowcase(
  BuildContext context,
  ActionItem item,
  String? scope,
  Widget child,
) {
  final showcaseKey = item.showcaseKey;
  final title = item.showcaseTitle;
  final description = item.showcaseDescription;
  if (showcaseKey == null || title == null || description == null) {
    return child;
  }

  return Showcase.withWidget(
    key: showcaseKey,
    scope: scope,
    container: CustomShowcaseTooltip(title: title, description: description),
    child: child,
  );
}
