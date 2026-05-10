import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/theme/theme.dart';

import '../../models/dashboard_filter_tab.dart';
import '../../providers/dashboard_filter_provider.dart';

final class DashboardFilterTabs extends ConsumerStatefulWidget {
  const DashboardFilterTabs({
    super.key,
    this.onTabChanged,
    this.height = 40,
    this.labelPadding = const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
    this.borderRadius = 12,
  });

  final ValueChanged<DashboardFilterTab>? onTabChanged;
  final double height;
  final EdgeInsets labelPadding;
  final double borderRadius;

  @override
  ConsumerState<DashboardFilterTabs> createState() =>
      _DashboardFilterTabsState();
}

final class _DashboardFilterTabsState extends ConsumerState<DashboardFilterTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<DashboardFilterTab> get _tabs => DashboardFilterTab.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.of(context).size.width <= 600;
    final currentTab = ref.watch(dashboardFilterProvider.select((s) => s.tab));

    ref.listen<DashboardFilterTab>(
      dashboardFilterProvider.select((s) => s.tab),
      (previous, next) {
        final nextIndex = _tabs.indexOf(next);
        if (nextIndex != -1 && _tabController.index != nextIndex) {
          _tabController.animateTo(nextIndex);
        }
      },
    );

    final currentIndex = _tabs.indexOf(currentTab);
    if (currentIndex != -1 && _tabController.index != currentIndex) {
      _tabController.index = currentIndex;
    }

    final fillColor = AppColors.getInputFieldBackgroundColor(context);

    return Container(
      height: widget.height + 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        color: fillColor,
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: isCompact && _tabs.length > 3,
        tabAlignment: isCompact ? TabAlignment.center : TabAlignment.fill,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: _AnimatedTabIndicator(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: widget.borderRadius,
        ),
        indicatorPadding: const EdgeInsets.all(2),
        labelColor: theme.colorScheme.onSecondary,
        unselectedLabelColor: theme.colorScheme.onSurface.withValues(
          alpha: 0.7,
        ),
        splashFactory: InkRipple.splashFactory,
        dividerColor: Colors.transparent,
        physics: const BouncingScrollPhysics(),
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: theme.textTheme.bodyMedium,
        overlayColor: WidgetStateProperty.all(
          theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
        labelPadding: widget.labelPadding,
        splashBorderRadius: BorderRadius.circular(widget.borderRadius),
        tabs: [
          for (final tab in _tabs)
            Tab(icon: Icon(_iconFor(tab), size: 16), text: tab.label),
        ],
      ),
    );
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging ||
        _tabController.index < 0 ||
        _tabController.index >= _tabs.length) {
      return;
    }

    final selectedTab = _tabs[_tabController.index];
    logDebug(
      'DashboardFilterTabs: Изменена вкладка',
      data: {'tab': selectedTab.label},
    );

    ref.read(dashboardFilterProvider.notifier).setTab(selectedTab);
    widget.onTabChanged?.call(selectedTab);
  }

  IconData _iconFor(DashboardFilterTab tab) {
    return switch (tab) {
      DashboardFilterTab.active => Icons.list,
      DashboardFilterTab.favorites => Icons.star,
      DashboardFilterTab.frequentlyUsed => Icons.access_time,
      DashboardFilterTab.archived => Icons.archive,
      DashboardFilterTab.deleted => Icons.delete,
    };
  }
}

final class _AnimatedTabIndicator extends Decoration {
  const _AnimatedTabIndicator({
    required this.color,
    required this.borderRadius,
  });

  final Color color;
  final double borderRadius;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _AnimatedTabIndicatorPainter(
      color: color,
      borderRadius: borderRadius,
      onChanged: onChanged,
    );
  }
}

final class _AnimatedTabIndicatorPainter extends BoxPainter {
  _AnimatedTabIndicatorPainter({
    required this.color,
    required this.borderRadius,
    VoidCallback? onChanged,
  }) : super(onChanged);

  final Color color;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)),
      paint,
    );
  }
}
