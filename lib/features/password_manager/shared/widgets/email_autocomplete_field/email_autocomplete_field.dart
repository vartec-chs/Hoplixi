import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/autocomplete_suggestions/autocomplete_suggestion_providers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/autocomplete_text_field/autocomplete_text_field.dart';

/// Email input field with suggestions from saved password manager entries.
class EmailAutocompleteField extends ConsumerWidget {
  const EmailAutocompleteField({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.labelText,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.enabled,
    this.autofocus = false,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final bool? enabled;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(currentStoreAutocompleteSuggestionsProvider);
    final suggestionsNotifier = ref.read(
      currentStoreAutocompleteSuggestionsProvider.notifier,
    );

    return AutocompleteTextField(
      optionsBuilder: suggestionsNotifier.searchEmails,
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      prefixIcon: prefixIcon ?? const Icon(Icons.email_outlined),
      suffixIcon: suffixIcon,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      enabled: enabled,
      autofocus: autofocus,
      enableSuggestions: false,
      autocorrect: false,
      inputFormatters: inputFormatters,
    );
  }
}
