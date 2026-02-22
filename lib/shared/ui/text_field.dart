import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/core/theme/colors.dart';

const EdgeInsets formPadding = EdgeInsets.all(12);

class CustomOutlineInputBorder extends UnderlineInputBorder {
  const CustomOutlineInputBorder({super.borderRadius, super.borderSide});

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    final RRect outer = borderRadius.toRRect(rect);
    final RRect center = outer.deflate(borderSide.width / 2.0);
    final Paint paint = borderSide.toPaint();
    canvas.drawRRect(center, paint);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is CustomOutlineInputBorder) {
      return CustomOutlineInputBorder(
        borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    return lerpTo(a, 1 - t);
  }

  @override
  bool operator ==(Object other) {
    if (other is CustomOutlineInputBorder) {
      return borderSide == other.borderSide &&
          borderSide == other.borderSide &&
          borderRadius == other.borderRadius;
    }

    return super == other;
  }

  @override
  int get hashCode => Object.hash(borderSide, borderRadius);
}

// Универсальный радиус по умолчанию
const BorderRadius defaultBorderRadiusValue = BorderRadius.all(
  Radius.circular(16),
);

/// Возвращает стандартный InputDecoration, основанный на закомментированном коде.
InputDecoration primaryInputDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
  String? errorText,
  Widget? error,
  Widget? helper,
  String? helperText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool enabled = true,
  bool filled = true,
  Widget? icon,
  VisualDensity? visualDensity,
  Widget? hint,
  Widget? suffix,
  BoxConstraints? constraints = const BoxConstraints(
    minWidth: 50,
    minHeight: 50,
  ),
  Color? focusColor,
  Color? hoverColor,
  Widget? prefix,
  String? suffixText,
  String? prefixText,
  bool? alignLabelWithHint,
  bool isCollapsed = false,
  bool isDense = false,
  EdgeInsetsGeometry? contentPadding,
  int? errorMaxLines = 1,
  int? helperMaxLines = 1,
  int? hintMaxLines = 1,
  bool isFocused = false,
  BorderRadius? borderRadius,
}) {
  final theme = Theme.of(context);
  final fillColor = AppColors.getInputFieldBackgroundColor(context);
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    errorText: errorText,
    error: error,
    enabled: enabled,
    helper: helper,
    helperText: helperText,
    icon: icon,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    hint: hint,
    suffix: suffix,
    constraints: constraints,

    prefix: prefix,
    focusColor: focusColor,
    hoverColor: hoverColor,
    suffixText: suffixText,
    prefixText: prefixText,
    errorStyle: TextStyle(color: theme.colorScheme.error, fontSize: 12),
    alignLabelWithHint: alignLabelWithHint,
    isCollapsed: isCollapsed,
    isDense: isDense,
    contentPadding:
        contentPadding ??
        const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
    errorMaxLines: errorMaxLines,
    helperMaxLines: helperMaxLines,
    hintMaxLines: hintMaxLines,
    suffixStyle: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
    suffixIconColor: theme.colorScheme.onSurface,
    prefixStyle: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
    iconColor: theme.colorScheme.onSurface,
    prefixIconColor: theme.colorScheme.onSurface,
    prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),

    // focusColor: theme.colorScheme.primary,
    hintStyle: TextStyle(
      fontSize: 14,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    ),
    border: CustomOutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: fillColor.withOpacity(0.6), width: 1),
    ),
    hintTextDirection: TextDirection.ltr,
    filled: filled,
    errorBorder: CustomOutlineInputBorder(
      borderRadius: defaultBorderRadiusValue,
      borderSide: BorderSide(color: theme.colorScheme.error, width: 0),
    ),
    focusedErrorBorder: CustomOutlineInputBorder(
      borderRadius: defaultBorderRadiusValue,
      borderSide: BorderSide(color: theme.colorScheme.error, width: 0),
    ),
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    floatingLabelAlignment: FloatingLabelAlignment.start,
    floatingLabelStyle: (errorText != null || error != null)
        ? TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.error,
          )
        : TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
    fillColor: fillColor,
    enabledBorder: CustomOutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: fillColor.withOpacity(0.6), width: 1),
    ),
    disabledBorder: CustomOutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: fillColor.withValues(alpha: 0.5), width: 1),
    ),

    focusedBorder: CustomOutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1),
    ),
    helperStyle: TextStyle(
      fontSize: 12,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    ),
    visualDensity: visualDensity ?? VisualDensity.standard,
  ).copyWith(
    // Apply disabled styles when enabled is false
    fillColor: !enabled
        ? fillColor.withValues(alpha: 0.5)
        : isFocused
        ? fillColor.withValues(alpha: 0.9)
        : fillColor,
    labelStyle: !enabled
        ? TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 14,
          )
        : null, // Allow Flutter to handle labelStyle for enabled state
    hintStyle: !enabled
        ? TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          )
        : TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
    prefixIconColor: !enabled
        ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
        : theme.colorScheme.onSurface,
    suffixIconColor: !enabled
        ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
        : theme.colorScheme.onSurface,
    helperStyle: !enabled
        ? TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          )
        : TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
  );
}

/// Простой обёрточный виджет для TextField с преднастроенной декорацией.
class PrimaryTextField extends StatelessWidget {
  final String? label;
  final TextEditingController? controller;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final String? hintText;
  final bool filled;
  final InputDecoration? decoration;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool? enabled;
  final bool autofocus;
  final TextAlign textAlign;
  final TextStyle? style;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool? showCursor;
  final Color? cursorColor;
  final double? cursorWidth;
  final double? cursorHeight;
  final bool enableSuggestions;
  final bool autocorrect;
  final ScrollPhysics? scrollPhysics;
  final EdgeInsets scrollPadding;
  final bool expands;

  const PrimaryTextField({
    super.key,
    this.label,
    this.controller,
    this.obscureText = false,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.hintText,
    this.filled = true,
    this.decoration,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
    this.style,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.showCursor,
    this.cursorColor,
    this.cursorWidth,
    this.cursorHeight,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.scrollPhysics,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.expands = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseDecoration = primaryInputDecoration(
      context,
      labelText: label,
      hintText: hintText,
      filled: filled,
      enabled: enabled ?? true,
    );

    final effectiveDecoration = baseDecoration.copyWith(
      prefixIcon: prefixIcon ?? decoration?.prefixIcon,
      suffixIcon: suffixIcon ?? decoration?.suffixIcon,
      prefix: prefix ?? decoration?.prefix,
      suffix: suffix ?? decoration?.suffix,
      labelText: decoration?.labelText ?? label,
      hintText: decoration?.hintText ?? hintText,
      fillColor: decoration?.fillColor,
      filled: decoration?.filled,
      border: decoration?.border,
      enabledBorder: decoration?.enabledBorder,
      focusedBorder: decoration?.focusedBorder,
      errorBorder: decoration?.errorBorder,
      floatingLabelStyle: decoration?.floatingLabelStyle,
    );

    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      focusNode: focusNode,
      decoration: effectiveDecoration,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      enabled: enabled,
      autofocus: autofocus,
      textAlign: textAlign,
      style: style,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      showCursor: showCursor,
      cursorColor: cursorColor,
      cursorWidth: cursorWidth ?? 2.0,
      cursorHeight: cursorHeight,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      scrollPhysics: scrollPhysics,
      scrollPadding: scrollPadding,
      expands: expands,
    );
  }
}

/// Простой обёрточный виджет для TextFormField с преднастроенной декорацией.
class PrimaryTextFormField extends StatelessWidget {
  final String? label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final String? hintText;
  final bool filled;
  final InputDecoration? decoration;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool? enabled;
  final bool autofocus;
  final TextAlign textAlign;
  final TextStyle? style;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool? showCursor;
  final Color? cursorColor;
  final double? cursorWidth;
  final double? cursorHeight;
  final bool enableSuggestions;
  final bool autocorrect;
  final ScrollPhysics? scrollPhysics;
  final EdgeInsets scrollPadding;
  final bool expands;
  final AutovalidateMode? autovalidateMode;
  final String? initialValue;
  final String? helperText;

  const PrimaryTextFormField({
    super.key,
    this.label,
    this.controller,
    this.validator,
    this.onSaved,
    this.obscureText = false,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.hintText,
    this.filled = true,
    this.decoration,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
    this.style,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.showCursor,
    this.cursorColor,
    this.cursorWidth,
    this.cursorHeight,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.scrollPhysics,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.expands = false,
    this.autovalidateMode,
    this.initialValue,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final baseDecoration = primaryInputDecoration(
      context,
      labelText: label,
      hintText: hintText,
      filled: filled,
      helperText: helperText,
      enabled: enabled ?? true,
    );

    final effectiveDecoration = baseDecoration.copyWith(
      prefixIcon: prefixIcon ?? decoration?.prefixIcon,
      suffixIcon: suffixIcon ?? decoration?.suffixIcon,
      prefix: prefix ?? decoration?.prefix,
      suffix: suffix ?? decoration?.suffix,
      labelText: decoration?.labelText ?? label,
      hintText: decoration?.hintText ?? hintText,
      fillColor: decoration?.fillColor,
      filled: decoration?.filled,
      border: decoration?.border,
      enabledBorder: decoration?.enabledBorder,
      focusedBorder: decoration?.focusedBorder,
      errorBorder: decoration?.errorBorder,
      floatingLabelStyle: decoration?.floatingLabelStyle,
      helperText: decoration?.helperText ?? helperText,
    );

    return TextFormField(
      controller: controller,
      // initialValue is ignored if controller is provided (TextFormField rule)
      initialValue: controller == null ? initialValue : null,
      validator: validator,
      onSaved: onSaved,
      obscureText: obscureText,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      focusNode: focusNode,
      decoration: effectiveDecoration,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      enabled: enabled,
      autofocus: autofocus,
      textAlign: textAlign,
      style: style,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      showCursor: showCursor,
      cursorColor: cursorColor,
      cursorWidth: cursorWidth ?? 2.0,
      cursorHeight: cursorHeight,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      scrollPhysics: scrollPhysics,
      scrollPadding: scrollPadding,
      expands: expands,
      autovalidateMode: autovalidateMode,
    );
  }
}

class PasswordField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool canRequestFocus;
  final bool autofocus;
  final String? Function(String?)? validator;

  const PasswordField({
    super.key,

    required this.label,
    this.focusNode,
    this.controller,
    this.canRequestFocus = true,
    this.autofocus = false,
    this.validator,
  });

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      canRequestFocus: widget.canRequestFocus,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      validator: widget.validator,
      decoration: primaryInputDecoration(context, labelText: widget.label)
          .copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
            prefixIcon: const Icon(Icons.lock),
          ),
    );
  }
}
