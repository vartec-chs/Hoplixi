import 'package:flutter/material.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard_layout/dashboard_drawer/dashboard_drawer.dart';

import 'config/dashboard_layout_constants.dart';

const double _kCollapsedLeftPanelWidth = 60;

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
    with TickerProviderStateMixin {
  late final AnimationController _panelController;
  late final CurvedAnimation _panelAnimation;
  late final AnimationController _fadeController;

  Widget? _displayedRightPanel;
  String? _displayedPanelIdentity;
  bool _isLeftPanelOpen = true;

  @override
  void initState() {
    super.initState();
    _displayedRightPanel = widget.rightPanel;
    _displayedPanelIdentity = widget.panelIdentity;
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
    _panelController.addStatusListener(_handlePanelStatusChange);
  }

  @override
  void didUpdateWidget(covariant DesktopThreeColumnLayout oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.rightPanel == null) {
      _panelController.reverse();
      return;
    }

    final panelChanged = oldWidget.panelIdentity != widget.panelIdentity;
    final openedPanel = oldWidget.rightPanel == null;

    if (openedPanel || panelChanged) {
      setState(() {
        _displayedRightPanel = widget.rightPanel;
        _displayedPanelIdentity = widget.panelIdentity;
      });
      _fadeController
        ..value = 0.0
        ..forward();
    }

    if (openedPanel) {
      _panelController.forward();
    }
  }

  void _handlePanelStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && mounted) {
      setState(() {
        _displayedRightPanel = null;
        _displayedPanelIdentity = null;
      });
      _fadeController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _panelController.removeStatusListener(_handlePanelStatusChange);
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
    final rightPanelTakesExclusiveSpace =
        showDrawerAsPanel && !canShowBoth && widget.rightPanel != null;
    final canToggleLeftPanel =
        showDrawerAsPanel && (canShowBoth || widget.rightPanel == null);

    return LayoutBuilder(
      builder: (context, constraints) {
        final targetLeftPanelWidth =
            rightPanelTakesExclusiveSpace ||
                (canToggleLeftPanel && !_isLeftPanelOpen)
            ? _kCollapsedLeftPanelWidth
            : kLeftPanelWidth;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: targetLeftPanelWidth),
          duration: kPanelAnimationDuration,
          curve: Curves.easeOutCubic,
          builder: (context, animatedLeftPanelWidth, _) {
            final leftPanelFootprint =
                showDrawerAsPanel &&
                    (canShowBoth ||
                        widget.rightPanel == null ||
                        rightPanelTakesExclusiveSpace)
                ? animatedLeftPanelWidth + 1
                : 0.0;
            final contentWidth = (constraints.maxWidth - leftPanelFootprint)
                .clamp(0.0, constraints.maxWidth);
            final panelMaxWidth = (contentWidth / 2);

            return Row(
              children: [
                _buildLeftPanel(
                  context,
                  canShowBoth,
                  width: animatedLeftPanelWidth,
                  canToggleLeftPanel: canToggleLeftPanel,
                  forceCollapsed: rightPanelTakesExclusiveSpace,
                ),
                Expanded(
                  child: DashboardHomeScreen(
                    key: ValueKey('desktop_home_${widget.entityType.id}'),
                    initialEntityType: EntityType.fromId(widget.entityType.id)!,
                  ),
                ),
                AnimatedBuilder(
                  animation: _panelAnimation,
                  builder: (context, child) {
                    final width = _panelAnimation.value * panelMaxWidth;
                    if (width < 1 || _displayedRightPanel == null) {
                      return const SizedBox.shrink();
                    }

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const VerticalDivider(width: 1, thickness: 1),
                        SizedBox(
                          width: width - 1,
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.centerLeft,
                              maxWidth: panelMaxWidth - 1,
                              child: child,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  child: _displayedRightPanel == null
                      ? null
                      : FadeTransition(
                          opacity: _fadeController,
                          child: KeyedSubtree(
                            key: ValueKey(_displayedPanelIdentity),
                            child: _displayedRightPanel!,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLeftPanel(
    BuildContext context,
    bool canShowBoth, {
    required double width,
    required bool canToggleLeftPanel,
    required bool forceCollapsed,
  }) {
    final isPanelOpen =
        !forceCollapsed && (!canToggleLeftPanel || _isLeftPanelOpen);
    final panelWidth = isPanelOpen
        ? kLeftPanelWidth
        : _kCollapsedLeftPanelWidth;
    final panel = Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: panelWidth,
          maxWidth: panelWidth,
          child: SizedBox(
            width: panelWidth,
            child: DashboardDrawerContent(
              entityType: widget.entityType,
              isDesktopPanelOpen: isPanelOpen,
              showDesktopPanelToggle: forceCollapsed || canToggleLeftPanel,
              isDesktopPanelToggleEnabled: !forceCollapsed,
              onToggleDesktopPanel: canToggleLeftPanel
                  ? () => setState(() => _isLeftPanelOpen = !_isLeftPanelOpen)
                  : null,
            ),
          ),
        ),
      ),
    );

    if (forceCollapsed || canShowBoth || widget.rightPanel == null) {
      return panel;
    }

    return AnimatedBuilder(
      animation: _panelAnimation,
      builder: (context, child) {
        final progress = 1.0 - _panelAnimation.value;
        final width = progress * panelWidth;
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
