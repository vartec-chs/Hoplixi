import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

class ShowcaseHelpButton extends StatelessWidget {
  const ShowcaseHelpButton({
    super.key,
    required this.keys,
    this.enabled = true,
    this.scope,
    this.color,
    this.tooltip = 'Показать подсказки',
    this.delay = const Duration(milliseconds: 250),
  });

  final List<GlobalKey> keys;
  final String? scope;
  final Color? color;
  final String tooltip;
  final Duration delay;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.help_outline),
      color: color,
      tooltip: tooltip,
      onPressed: enabled ? () {
        if (keys.isEmpty) {
          return;
        }

        final showcaseView = scope == null
            ? ShowcaseView.get()
            : ShowcaseView.getNamed(scope!);
        if (showcaseView.isShowcaseRunning) {
          return;
        }

        showcaseView.startShowCase(keys, delay: delay);
      } : null,
    );
  }
}
