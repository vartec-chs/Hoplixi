import 'package:flutter/material.dart';
import 'package:hoplixi/features/home/models/action_item.dart';
import 'package:hoplixi/features/home/widgets/action_button.dart';
import 'package:hoplixi/features/home/widgets/action_button_compact.dart';
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

  if (item.useCustomShowcaseTooltip) {
    return Showcase.withWidget(
      key: showcaseKey,
      scope: scope,

      container: _CustomShowcaseTooltip(title: title, description: description),
      child: child,
    );
  }

  return Showcase(
    key: showcaseKey,
    scope: scope,
    title: title,
    description: description,
    child: child,
  );
}

class _CustomShowcaseTooltip extends StatelessWidget {
  const _CustomShowcaseTooltip({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Нажмите, чтобы проверить работу подсказки',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
