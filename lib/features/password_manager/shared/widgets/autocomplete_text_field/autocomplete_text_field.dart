import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Text field with app styling and a ranked string autocomplete menu.
class AutocompleteTextField extends StatefulWidget {
  const AutocompleteTextField({
    super.key,
    required this.optionsBuilder,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.labelText,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.enabled,
    this.autofocus = false,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.inputFormatters,
  });

  final FutureOr<Iterable<String>> Function(String query) optionsBuilder;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool? enabled;
  final bool autofocus;
  final bool enableSuggestions;
  final bool autocorrect;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AutocompleteTextField> createState() => _AutocompleteTextFieldState();
}

class _AutocompleteTextFieldState extends State<AutocompleteTextField> {
  late final TextEditingController _fallbackController;
  late final FocusNode _fallbackFocusNode;

  TextEditingController get _effectiveController =>
      widget.controller ?? _fallbackController;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _fallbackFocusNode;

  @override
  void initState() {
    super.initState();
    _fallbackController = TextEditingController();
    _fallbackFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _fallbackController.dispose();
    _fallbackFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: _effectiveController,
      focusNode: _effectiveFocusNode,
      displayStringForOption: (option) => option,
      optionsBuilder: (textEditingValue) async {
        final query = textEditingValue.text.trim();
        if (query.isEmpty) return const Iterable<String>.empty();

        final options = await widget.optionsBuilder(query);
        return options.take(10);
      },
      onSelected: widget.onChanged,
      optionsViewOpenDirection: OptionsViewOpenDirection.mostSpace,
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              enableSuggestions: widget.enableSuggestions,
              autocorrect: widget.autocorrect,
              inputFormatters: widget.inputFormatters,
              decoration: primaryInputDecoration(
                context,
                labelText: widget.labelText,
                hintText: widget.hintText,
                errorText: widget.errorText,
                enabled: widget.enabled ?? true,
                prefixIcon: widget.prefixIcon,
                suffixIcon: widget.suffixIcon,
              ),
              onChanged: widget.onChanged,
              onSubmitted: (value) {
                onFieldSubmitted();
                widget.onSubmitted?.call(value);
              },
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        return _AutocompleteOptionsView(
          options: options.toList(growable: false),
          onSelected: onSelected,
        );
      },
    );
  }
}

class _AutocompleteOptionsView extends StatelessWidget {
  const _AutocompleteOptionsView({
    required this.options,
    required this.onSelected,
  });

  final List<String> options;
  final AutocompleteOnSelected<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          shrinkWrap: true,
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            final isHighlighted =
                AutocompleteHighlightedOption.of(context) == index;

            return _AutocompleteOptionTile(
              option: option,
              isHighlighted: isHighlighted,
              onTap: () => onSelected(option),
            );
          },
        ),
      ),
    );
  }
}

class _AutocompleteOptionTile extends StatelessWidget {
  const _AutocompleteOptionTile({
    required this.option,
    required this.isHighlighted,
    required this.onTap,
  });

  final String option;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface,
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        color: isHighlighted
            ? theme.colorScheme.secondary.withValues(alpha: 0.10)
            : null,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          option,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        ),
      ),
    );
  }
}
