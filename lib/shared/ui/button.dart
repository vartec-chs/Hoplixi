import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:hoplixi/core/theme/colors.dart';

enum SmoothButtonType { text, filled, tonal, outlined, dashed }

enum SmoothButtonSize { small, medium, large }

enum SmoothButtonIconPosition { start, end }

enum SmoothButtonVariant { normal, error, warning, info, success }

/// A smooth button with customizable properties.
class SmoothButton extends StatelessWidget {
  final SmoothButtonType type;
  final SmoothButtonSize size;
  final SmoothButtonVariant variant;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Function(bool)? onHover;
  final Function(bool)? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip clipBehavior;
  final ButtonStyle? style;
  final Widget? icon;
  final SmoothButtonIconPosition iconPosition;
  final String label;
  final bool loading;
  final bool bold;
  final bool isFullWidth;

  const SmoothButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = SmoothButtonType.filled,
    this.size = SmoothButtonSize.medium,
    this.variant = SmoothButtonVariant.normal,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.onHover,
    this.onFocusChange,
    this.style,
    this.icon,
    this.iconPosition = SmoothButtonIconPosition.start,
    this.loading = false,
    this.bold = false,
    this.isFullWidth = false,
  });

  double get _fontSize {
    switch (size) {
      case SmoothButtonSize.small:
        return 14;
      case SmoothButtonSize.medium:
        return 16;
      case SmoothButtonSize.large:
        return 18;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case SmoothButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case SmoothButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 22, vertical: 18);
      case SmoothButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 26, vertical: 20);
    }
  }

  Color _getVariantColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (variant) {
      case SmoothButtonVariant.normal:
        return colorScheme.primary;
      case SmoothButtonVariant.error:
        return AppColors.getErrorColor(context); // Яркий красный
      case SmoothButtonVariant.warning:
        return Colors.orangeAccent.shade700; // Яркий оранжевый
      case SmoothButtonVariant.info:
        return Colors.blueAccent.shade700; // Яркий синий
      case SmoothButtonVariant.success:
        return Colors.green.shade700; // Яркий зелёный
    }
  }

  Color _disabledForegroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.38);
  }

  Color _disabledBackgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.12);
  }

  Color _loadingIndicatorColor(BuildContext context) {
    if (onPressed == null && !loading) {
      return _disabledForegroundColor(context);
    }

    final theme = Theme.of(context);
    final variantColor = _getVariantColor(context);

    if (variant != SmoothButtonVariant.normal) {
      if (type == SmoothButtonType.filled) {
        return theme.colorScheme.onPrimary;
      }
      return variantColor;
    }

    switch (type) {
      case SmoothButtonType.filled:
        return theme.colorScheme.onPrimary;
      case SmoothButtonType.tonal:
        return theme.colorScheme.onSecondaryContainer;
      case SmoothButtonType.outlined:
      case SmoothButtonType.dashed:
      case SmoothButtonType.text:
        return theme.colorScheme.primary;
    }
  }

  Widget _buildChild(BuildContext context) {
    final textWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: TextStyle(
        fontSize: _fontSize,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: loading ? _loadingIndicatorColor(context) : null,
      ),
    );

    if (loading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _fontSize,
            height: _fontSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _loadingIndicatorColor(context),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(child: textWidget),
        ],
      );
    }

    if (icon != null) {
      final iconWidget = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: icon,
      );

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: iconPosition == SmoothButtonIconPosition.start
            ? [iconWidget, Flexible(child: textWidget)]
            : [Flexible(child: textWidget), iconWidget],
      );
    }

    return textWidget;
  }

  Widget _buildButton(BuildContext context) {
    final buttonChild = _buildChild(context);
    final variantColor = _getVariantColor(context);
    final theme = Theme.of(context);
    final disabledForegroundColor = _disabledForegroundColor(context);
    final disabledBackgroundColor = _disabledBackgroundColor(context);

    final effectiveStyle = (style ?? const ButtonStyle()).copyWith(
      padding: WidgetStateProperty.all(_padding),
    );

    // Apply variant color for non-normal variants
    ButtonStyle styledWithVariant = effectiveStyle;
    if (variant != SmoothButtonVariant.normal) {
      switch (type) {
        case SmoothButtonType.filled:
          styledWithVariant = effectiveStyle.copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return disabledBackgroundColor;
              }
              return variantColor;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return disabledForegroundColor;
              }
              return theme.colorScheme.onPrimary;
            }),
          );
          break;
        case SmoothButtonType.tonal:
          styledWithVariant = effectiveStyle.copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return disabledBackgroundColor;
              }
              return variantColor.withOpacity(0.2);
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return disabledForegroundColor;
              }
              return variantColor;
            }),
          );
          break;
        case SmoothButtonType.outlined:
          styledWithVariant = effectiveStyle.copyWith(
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return BorderSide(
                  color: theme.colorScheme.onSurface.withOpacity(0.12),
                  width: 1,
                );
              }
              return BorderSide(color: variantColor, width: 1);
            }),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return Colors.transparent;
              }
              return variantColor.withOpacity(0.1);
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return disabledForegroundColor;
              }
              return variantColor;
            }),
          );
          break;
        case SmoothButtonType.text || SmoothButtonType.dashed:
          styledWithVariant = effectiveStyle.copyWith(
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return disabledForegroundColor;
              }
              return variantColor;
            }),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return Colors.transparent;
              }
              return variantColor.withOpacity(0.1);
            }),
          );
          break;
      }
    }

    switch (type) {
      case SmoothButtonType.text:
        return TextButton(
          onPressed: loading ? null : onPressed,
          onLongPress: onLongPress,
          focusNode: focusNode,
          autofocus: autofocus,
          clipBehavior: clipBehavior,
          style: styledWithVariant,
          child: buttonChild,
          onHover: (isHovered) {
            onHover?.call(isHovered);
          },
          onFocusChange: (value) => {onFocusChange?.call(value)},
        );

      case SmoothButtonType.filled:
        return FilledButton(
          onPressed: loading ? null : onPressed,
          onLongPress: onLongPress,
          focusNode: focusNode,
          autofocus: autofocus,
          clipBehavior: clipBehavior,
          style: styledWithVariant,
          child: buttonChild,
          onHover: (isHovered) {
            onHover?.call(isHovered);
          },
          onFocusChange: (value) => {onFocusChange?.call(value)},
        );

      case SmoothButtonType.tonal:
        return FilledButton.tonal(
          onPressed: loading ? null : onPressed,
          onLongPress: onLongPress,
          focusNode: focusNode,
          autofocus: autofocus,
          clipBehavior: clipBehavior,
          style: styledWithVariant,
          child: buttonChild,
          onHover: (isHovered) {
            onHover?.call(isHovered);
          },
          onFocusChange: (value) => {onFocusChange?.call(value)},
        );

      case SmoothButtonType.outlined:
        return OutlinedButton(
          onPressed: loading ? null : onPressed,
          onLongPress: onLongPress,
          onHover: (isHovered) {
            onHover?.call(isHovered);
          },
          onFocusChange: (value) {
            onFocusChange?.call(value);
          },
          focusNode: focusNode,
          autofocus: autofocus,

          clipBehavior: clipBehavior,
          style: styledWithVariant.copyWith(
            side: WidgetStateProperty.resolveWith((states) {
              final defaultBorderColor = theme.colorScheme.onSurface
                  .withOpacity(0.12);

              if (states.contains(WidgetState.disabled)) {
                return BorderSide(color: defaultBorderColor, width: 1.5);
              }

              return BorderSide(
                color: variant == SmoothButtonVariant.normal
                    ? defaultBorderColor
                    : variantColor,
                width: 1.5,
              );
            }),
          ),
          child: buttonChild,
        );

      case SmoothButtonType.dashed:
        // DottedBorder paints a dashed border around the child. Wrap the
        // interactive TextButton inside so we keep focus/hover behavior.
        final isActuallyDisabled = onPressed == null && !loading;
        final dashColor =
            isActuallyDisabled || variant == SmoothButtonVariant.normal
            ? theme.colorScheme.onSurface.withOpacity(0.12)
            : variantColor;

        final button = TextButton(
          onPressed: loading ? null : onPressed,
          onLongPress: onLongPress,
          focusNode: focusNode,
          autofocus: autofocus,
          clipBehavior: clipBehavior,
          style: styledWithVariant.copyWith(
            padding: WidgetStateProperty.all(_padding),
            backgroundColor: WidgetStateProperty.all(Colors.transparent),
            // keep side unset here, DottedBorder handles border
          ),
          child: buttonChild,
          onHover: (isHovered) {
            onHover?.call(isHovered);
          },
          onFocusChange: (value) => {onFocusChange?.call(value)},
        );

        return Material(
          color: Colors.transparent,
          child: DottedBorder(
            options: RoundedRectDottedBorderOptions(
              color: dashColor,
              strokeWidth: 1.5,
              dashPattern: const <double>[6, 4],
              radius: const Radius.circular(16),
              padding: EdgeInsets.zero,
            ),
            child: isFullWidth
                ? SizedBox(width: double.infinity, child: button)
                : button,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return isFullWidth
        ? SizedBox(width: double.infinity, child: _buildButton(context))
        : _buildButton(context);
  }
}
