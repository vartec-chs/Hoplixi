import 'package:flutter/material.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
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
    return _buildActionSections(
      context,
      visibleItems: items.where((item) => !item.isDevModeOnly).toList(),
      devItems: MainConstants.isProduction
          ? const <ActionItem>[]
          : items.where((item) => item.isDevModeOnly).toList(),
      showcaseScope: showcaseScope,
      childAspectRatio: 1,
      childBuilder: (item) => ActionButtonCompact(
        icon: item.icon,
        label: item.label,
        description: item.description,
        isPrimary: item.isPrimary,
        disabled: item.disabled,
        onTap: item.onTap,
      ),
    );
  }
}

class _WideActionGrid extends StatelessWidget {
  const _WideActionGrid({required this.items, this.showcaseScope});

  final List<ActionItem> items;
  final String? showcaseScope;

  @override
  Widget build(BuildContext context) {
    return _buildActionSections(
      context,
      visibleItems: items.where((item) => !item.isDevModeOnly).toList(),
      devItems: MainConstants.isProduction
          ? const <ActionItem>[]
          : items.where((item) => item.isDevModeOnly).toList(),
      showcaseScope: showcaseScope,
      childAspectRatio: 2.8,
      childBuilder: (item) => ActionButton(
        icon: item.icon,
        label: item.label,
        description: item.description,
        isPrimary: item.isPrimary,
        disabled: item.disabled,
        onTap: item.onTap,
      ),
    );
  }
}

Widget _buildActionSections(
  BuildContext context, {
  required List<ActionItem> visibleItems,
  required List<ActionItem> devItems,
  required String? showcaseScope,
  required double childAspectRatio,
  required Widget Function(ActionItem item) childBuilder,
}) {
  final sections = <Widget>[];

  if (visibleItems.isNotEmpty) {
    sections.add(
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
        children: visibleItems
            .map(
              (item) => _wrapShowcase(
                context,
                item,
                showcaseScope,
                childBuilder(item),
              ),
            )
            .toList(),
      ),
    );
  }

  if (!MainConstants.isProduction && devItems.isNotEmpty) {
    if (sections.isNotEmpty) {
      sections.add(const SizedBox(height: 8));
    }

    sections.add(const _DevDividerLabel());
    sections.add(const SizedBox(height: 8));
    sections.add(
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
        children: devItems
            .map(
              (item) => _wrapShowcase(
                context,
                item,
                showcaseScope,
                childBuilder(item),
              ),
            )
            .toList(),
      ),
    );
    sections.add(const SizedBox(height: 8));
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: sections,
  );
}

class _DevDividerLabel extends StatelessWidget {
  const _DevDividerLabel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(child: Divider(color: colorScheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Dev',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(child: Divider(color: colorScheme.outlineVariant)),
      ],
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
