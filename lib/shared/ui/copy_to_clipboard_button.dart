import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/shared/ui/button.dart';

abstract class _CopyToClipboardState<T extends StatefulWidget>
    extends State<T> {
  Timer? _resetTimer;
  bool _copied = false;
  bool _isCopying = false;

  bool get copied => _copied;
  bool get isCopying => _isCopying;

  Future<void> copyText({
    required String text,
    required Duration successDuration,
    VoidCallback? onCopied,
  }) async {
    if (_isCopying || text.isEmpty) return;

    setState(() => _isCopying = true);
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;

      onCopied?.call();
      setState(() => _copied = true);
      _resetTimer?.cancel();
      _resetTimer = Timer(successDuration, () {
        if (!mounted) return;
        setState(() => _copied = false);
      });
    } finally {
      if (!mounted) return;
      setState(() => _isCopying = false);
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }
}

class CopyToClipboardIconButton extends StatefulWidget {
  const CopyToClipboardIconButton({
    super.key,
    required this.text,
    this.tooltip,
    this.copyIcon = Icons.content_copy,
    this.successIcon = Icons.check,
    this.iconSize,
    this.color,
    this.successColor,
    this.style,
    this.successDuration = const Duration(seconds: 2),
    this.onCopied,
  });

  final String text;
  final String? tooltip;
  final IconData copyIcon;
  final IconData successIcon;
  final double? iconSize;
  final Color? color;
  final Color? successColor;
  final ButtonStyle? style;
  final Duration successDuration;
  final VoidCallback? onCopied;

  @override
  State<CopyToClipboardIconButton> createState() =>
      _CopyToClipboardIconButtonState();
}

class _CopyToClipboardIconButtonState
    extends _CopyToClipboardState<CopyToClipboardIconButton> {
  @override
  Widget build(BuildContext context) {
    final effectiveTooltip =
        widget.tooltip ?? (copied ? 'Скопировано' : 'Копировать');

    return IconButton(
      tooltip: effectiveTooltip,
      style: widget.style,
      onPressed: isCopying
          ? null
          : () => copyText(
              text: widget.text,
              successDuration: widget.successDuration,
              onCopied: widget.onCopied,
            ),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          copied ? widget.successIcon : widget.copyIcon,
          key: ValueKey<bool>(copied),
          size: widget.iconSize,
          color: copied ? widget.successColor ?? widget.color : widget.color,
        ),
      ),
    );
  }
}

class CopySmoothButton extends StatefulWidget {
  const CopySmoothButton({
    super.key,
    required this.text,
    this.label = 'Копировать',
    this.copiedLabel = 'Скопировано',
    this.copyIcon = Icons.content_copy,
    this.successIcon = Icons.check,
    this.type = SmoothButtonType.tonal,
    this.size = SmoothButtonSize.medium,
    this.variant = SmoothButtonVariant.normal,
    this.iconPosition = SmoothButtonIconPosition.start,
    this.bold = false,
    this.isFullWidth = false,
    this.style,
    this.successDuration = const Duration(seconds: 2),
    this.onCopied,
  });

  final String text;
  final String label;
  final String copiedLabel;
  final IconData copyIcon;
  final IconData successIcon;
  final SmoothButtonType type;
  final SmoothButtonSize size;
  final SmoothButtonVariant variant;
  final SmoothButtonIconPosition iconPosition;
  final bool bold;
  final bool isFullWidth;
  final ButtonStyle? style;
  final Duration successDuration;
  final VoidCallback? onCopied;

  @override
  State<CopySmoothButton> createState() => _CopySmoothButtonState();
}

class _CopySmoothButtonState extends _CopyToClipboardState<CopySmoothButton> {
  @override
  Widget build(BuildContext context) {
    return SmoothButton(
      onPressed: isCopying
          ? null
          : () => copyText(
              text: widget.text,
              successDuration: widget.successDuration,
              onCopied: widget.onCopied,
            ),
      type: widget.type,
      size: widget.size,
      variant: widget.variant,
      iconPosition: widget.iconPosition,
      label: copied ? widget.copiedLabel : widget.label,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          copied ? widget.successIcon : widget.copyIcon,
          key: ValueKey<bool>(copied),
          size: 18,
        ),
      ),
      loading: isCopying,
      bold: widget.bold,
      isFullWidth: widget.isFullWidth,
      style: widget.style,
    );
  }
}
