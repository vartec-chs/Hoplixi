import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:showcaseview/showcaseview.dart';

void registerAppGuideShowcase({
  required String scope,
  required VoidCallback onFinish,
  OnDismissCallback? onDismiss,
  bool enableAutoScroll = true,
  bool semanticEnable = true,
  bool autoPlay = false,
  bool skipIfTargetNotPresent = true,
  List<GlobalKey>? hideFloatingActionWidgetForShowcase,
  List<GlobalKey>? previousActionHideKeys,
  List<GlobalKey>? nextActionHideKeys,
  FloatingActionBuilderCallback? globalFloatingActionWidget,
  TooltipActionConfig? globalTooltipActionConfig,
  List<TooltipActionButton>? globalTooltipActions,
}) {
  final effectiveFloatingActionWidget =
      globalFloatingActionWidget ??
      (_) => FloatingActionWidget(
        left: 12,
        top: 32,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SmoothButton(
            onPressed: () => ShowcaseView.getNamed(scope).dismiss(),
            label: 'Пропустить',
            type: SmoothButtonType.outlined,
            size: SmoothButtonSize.small,
          ),
        ),
      );

  final effectiveTooltipActionConfig =
      globalTooltipActionConfig ??
      const TooltipActionConfig(
        position: TooltipActionPosition.inside,
        alignment: MainAxisAlignment.spaceBetween,
        actionGap: 20,
      );

  final effectiveTooltipActions =
      globalTooltipActions ??
      [
        TooltipActionButton(
          type: TooltipDefaultActionType.previous,
          textStyle: const TextStyle(color: Colors.white),
          hideActionWidgetForShowcase:
              previousActionHideKeys ?? const <GlobalKey>[],
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          textStyle: const TextStyle(color: Colors.white),
          hideActionWidgetForShowcase:
              nextActionHideKeys ?? const <GlobalKey>[],
        ),
      ];

  ShowcaseView.register(
    scope: scope,
    enableAutoScroll: enableAutoScroll,
    semanticEnable: semanticEnable,
    autoPlay: autoPlay,
    skipIfTargetNotPresent: skipIfTargetNotPresent,
    hideFloatingActionWidgetForShowcase:
        hideFloatingActionWidgetForShowcase ?? const <GlobalKey>[],
    globalFloatingActionWidget: effectiveFloatingActionWidget,
    globalTooltipActionConfig: effectiveTooltipActionConfig,
    globalTooltipActions: effectiveTooltipActions,
    onFinish: onFinish,

    onDismiss: onDismiss,
  );
}
