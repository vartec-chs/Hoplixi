import 'package:flutter/material.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_home_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer/dashboard_drawer.dart';

import 'dashboard_layout_constants.dart';

class DesktopThreeColumnLayout extends StatefulWidget {
  final EntityType entityType;
  final Widget? rightPanel;
  final String? panelIdentity;

  const DesktopThreeColumnLayout({
    required this.entityType,
    this.rightPanel,
    this.panelIdentity,
    super.key,
  });

  @override
  State<DesktopThreeColumnLayout> createState() =>
      _DesktopThreeColumnLayoutState();
}

class _DesktopThreeColumnLayoutState extends State<DesktopThreeColumnLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _panelController;
  late final CurvedAnimation _panelAnimation;
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: kPanelAnimationDuration,
      value: widget.rightPanel == null ? 0.0 : 1.0,
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: kFadeAnimationDuration,
      value: widget.rightPanel == null ? 0.0 : 1.0,
    );
  }

  @override
  void didUpdateWidget(covariant DesktopThreeColumnLayout oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.rightPanel == null) {
      _panelController.reverse();
      _fadeController.value = 0.0;
      return;
    }

    if (oldWidget.rightPanel == null) {
      _panelController.forward();
    }

    if (oldWidget.rightPanel == null ||
        oldWidget.panelIdentity != widget.panelIdentity) {
      _fadeController
        ..value = 0.0
        ..forward();
    }
  }

  @override
  void dispose() {
    _panelAnimation.dispose();
    _panelController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showDrawerAsPanel = screenWidth >= MainConstants.kDesktopBreakpoint;
    final canShowBoth = screenWidth >= kBothPanelsBreakpoint;

    return LayoutBuilder(
      builder: (context, constraints) {
        final leftPanelFootprint = showDrawerAsPanel && canShowBoth
            ? kLeftPanelWidth + 1
            : 0.0;
        final contentWidth = (constraints.maxWidth - leftPanelFootprint).clamp(
          0.0,
          constraints.maxWidth,
        );
        final panelMaxWidth = contentWidth / 2;

        return Row(
          children: [
            if (showDrawerAsPanel) _buildLeftPanel(context, canShowBoth),
            Expanded(
              child: DashboardHomeScreen(
                key: ValueKey('desktop_home_${widget.entityType.id}'),
                entityType: widget.entityType,
              ),
            ),
            AnimatedBuilder(
              animation: _panelAnimation,
              builder: (context, child) {
                final width = _panelAnimation.value * panelMaxWidth;
                if (width < 1 || widget.rightPanel == null) {
                  return const SizedBox.shrink();
                }

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const VerticalDivider(width: 1, thickness: 1),
                    SizedBox(
                      width: width - 1,
                      child: ClipRect(child: child),
                    ),
                  ],
                );
              },
              child: widget.rightPanel == null
                  ? null
                  : FadeTransition(
                      opacity: _fadeController,
                      child: KeyedSubtree(
                        key: ValueKey(widget.panelIdentity),
                        child: widget.rightPanel!,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLeftPanel(BuildContext context, bool canShowBoth) {
    final panel = Container(
      width: kLeftPanelWidth,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: DashboardDrawerContent(entityType: widget.entityType),
    );

    if (canShowBoth) {
      return panel;
    }

    return AnimatedBuilder(
      animation: _panelAnimation,
      builder: (context, child) {
        final progress = 1.0 - _panelAnimation.value;
        final width = progress * kLeftPanelWidth;
        if (width < 1) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          width: width,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerRight,
              maxWidth: kLeftPanelWidth,
              child: child,
            ),
          ),
        );
      },
      child: panel,
    );
  }
}
