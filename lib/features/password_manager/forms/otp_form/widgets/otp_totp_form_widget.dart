import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_db/core/old/models/dto/icon_ref_dto.dart';
import 'package:hoplixi/main_db/core/models/enums/entity_types.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/note_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/login_autocomplete_field/login_autocomplete_field.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_editor.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:hoplixi/shared/widgets/icon_source_picker_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/otp_form_state.dart';
import '../providers/otp_form_provider.dart';
import 'otp_qr_scan_button.dart';

class OtpTotpFormWidget extends ConsumerStatefulWidget {
  final OtpFormState state;
  final TextEditingController secretController;
  final TextEditingController issuerController;
  final TextEditingController accountNameController;
  final TextEditingController periodController;
  final String? noteName;
  final Future<void> Function() onScanQr;

  const OtpTotpFormWidget({
    super.key,
    required this.state,
    required this.secretController,
    required this.issuerController,
    required this.accountNameController,
    required this.periodController,
    required this.noteName,
    required this.onScanQr,
  });

  @override
  ConsumerState<OtpTotpFormWidget> createState() => _OtpTotpFormWidgetState();
}

class _OtpTotpFormWidgetState extends ConsumerState<OtpTotpFormWidget> {
  final _formKey = GlobalKey<FormState>();
  bool _obscureSecret = true;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!state.isEditMode) ...[
            OtpQrScanButton(onTap: widget.onScanQr),
            const SizedBox(height: 24),
            const _OtpDividerWithText(text: 'или введите вручную'),
            const SizedBox(height: 16),
          ],
          if (state.isFromQrCode) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.t.dashboard_forms.data_loaded_from_qr_code,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: widget.secretController,
            obscureText: _obscureSecret,
            decoration: primaryInputDecoration(
              context,
              labelText: context.t.dashboard_forms.otp_secret_key_label,
              hintText: 'JBSWY3DPEHPK3PXP',
              errorText: state.secretError,
              helperText: context.t.dashboard_forms.otp_secret_helper_text,
              prefixIcon: const Icon(LucideIcons.key),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _obscureSecret ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureSecret = !_obscureSecret;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_paste),
                    tooltip: 'Вставить из буфера',
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        widget.secretController.text = data!.text!;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.issuerController,
            decoration: primaryInputDecoration(
              context,
              labelText: context.t.dashboard_forms.otp_issuer_label,
              hintText: 'Google, GitHub, Steam...',
              prefixIcon: const Icon(LucideIcons.building),
            ),
          ),
          const SizedBox(height: 16),
          LoginAutocompleteField(
            controller: widget.accountNameController,
            labelText: context.t.dashboard_forms.otp_account_name_label,
            hintText: 'email@example.com',
            prefixIcon: const Icon(LucideIcons.user),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          _OtpExpandableSection(
            title: context.t.dashboard_forms.advanced_settings,
            initiallyExpanded:
                state.algorithm != AlgorithmOtp.SHA1 ||
                state.digits != 6 ||
                state.period != 30,
            children: [
              _OtpDropdownField<AlgorithmOtp>(
                label: context.t.dashboard_forms.algorithm_label,
                value: state.algorithm,
                items: AlgorithmOtp.values,
                itemLabel: (item) => item.name,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(otpFormProvider.notifier).setAlgorithm(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              _OtpDropdownField<int>(
                label: context.t.dashboard_forms.digits_count_label,
                value: state.digits,
                items: const [6, 7, 8],
                itemLabel: (item) => item.toString(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(otpFormProvider.notifier).setDigits(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: widget.periodController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: context.t.dashboard_forms.period_seconds_label,
                  hintText: '30',
                  errorText: state.periodError,
                  prefixIcon: const Icon(LucideIcons.clock),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
          const SizedBox(height: 16),
          IconSourcePickerButton(
            iconRef: IconRefDto.fromFields(
              iconSource: state.iconSource,
              iconValue: state.iconValue,
            ),
            fallbackIcon: Icons.vpn_key,
            title: 'Иконка записи',
            onChanged: ref.read(otpFormProvider.notifier).setIconRef,
          ),
          const SizedBox(height: 16),
          CategoryPickerField(
            selectedCategoryId: state.categoryId,
            selectedCategoryName: state.categoryName,
            label: context.t.dashboard_forms.pickers_category_label,
            hintText: context.t.dashboard_forms.select_category_hint,
            filterByType: const [CategoryType.totp, CategoryType.mixed],
            onCategorySelected: (categoryId, categoryName) {
              ref
                  .read(otpFormProvider.notifier)
                  .setCategory(categoryId, categoryName);
            },
          ),
          const SizedBox(height: 16),
          TagPickerField(
            selectedTagIds: state.tagIds,
            selectedTagNames: state.tagNames,
            label: context.t.dashboard_forms.pickers_tags_label,
            hintText: context.t.dashboard_forms.select_tags_hint,
            filterByType: const [TagType.totp, TagType.mixed],
            onTagsSelected: (tagIds, tagNames) {
              ref.read(otpFormProvider.notifier).setTags(tagIds, tagNames);
            },
          ),
          const SizedBox(height: 16),
          NotePickerField(
            selectedNoteId: state.noteId,
            selectedNoteName: widget.noteName,
            hintText: context.t.dashboard_forms.select_note_hint,
            onNoteSelected: (noteId, noteName) {
              ref.read(otpFormProvider.notifier).setNoteId(noteId);
            },
          ),
          const SizedBox(height: 16),
          CustomFieldsEditor(
            fields: state.customFields,
            onChanged: ref.read(otpFormProvider.notifier).setCustomFields,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _OtpDividerWithText extends StatelessWidget {
  final String text;

  const _OtpDividerWithText({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(child: Divider(color: colorScheme.outline.withOpacity(0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: colorScheme.outline.withOpacity(0.3))),
      ],
    );
  }
}

class _OtpExpandableSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  const _OtpExpandableSection({
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        children: children,
      ),
    );
  }
}

class _OtpDropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _OtpDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          decoration: primaryInputDecoration(context),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
