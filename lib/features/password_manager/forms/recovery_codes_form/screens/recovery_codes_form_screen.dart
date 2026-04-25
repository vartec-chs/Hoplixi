import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/form_close_button.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/note_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/main_db/core/models/enums/entity_types.dart';
import 'package:hoplixi/shared/custom_fields/widgets/custom_fields_editor.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../providers/recovery_codes_form_provider.dart';

class RecoveryCodesFormScreen extends ConsumerStatefulWidget {
  const RecoveryCodesFormScreen({super.key, this.recoveryCodesId});

  final String? recoveryCodesId;

  @override
  ConsumerState<RecoveryCodesFormScreen> createState() =>
      _RecoveryCodesFormScreenState();
}

class _RecoveryCodesFormScreenState
    extends ConsumerState<RecoveryCodesFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _codesInputController;
  late final TextEditingController _displayHintController;
  late final TextEditingController _descriptionController;

  static final _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _codesInputController = TextEditingController();
    _displayHintController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codesInputController.dispose();
    _displayHintController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Открывает выбор даты + времени и передаёт результат в [onChanged] в ISO 8601.
  Future<void> _pickDateTime({
    required BuildContext context,
    required String current,
    required void Function(String) onChanged,
  }) async {
    final initial = DateTime.tryParse(current) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(DateTime.now().year + 150),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time != null) {
      final result = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      onChanged(result.toIso8601String());
    }
  }

  Future<void> _save() async {
    final success = await ref
        .read(recoveryCodesFormProvider(widget.recoveryCodesId).notifier)
        .save();

    if (!mounted) return;

    if (!success) {
      Toaster.error(
        title: context.t.dashboard_forms.save_error,
        description: context.t.dashboard_forms.check_form_fields_and_try_again,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(
      recoveryCodesFormProvider(widget.recoveryCodesId),
    );

    ref.listen(recoveryCodesFormProvider(widget.recoveryCodesId), (prev, next) {
      final wasSaved = prev?.value?.isSaved ?? false;
      final isSaved = next.value?.isSaved ?? false;
      if (!wasSaved && isSaved) {
        Toaster.success(
          title: widget.recoveryCodesId != null
              ? context.t.dashboard_forms.recovery_codes_updated
              : context.t.dashboard_forms.recovery_codes_created,
        );
        ref
            .read(recoveryCodesFormProvider(widget.recoveryCodesId).notifier)
            .resetSaved();
        if (context.mounted) context.pop(true);
      }
    });

    return stateAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          leading: const FormCloseButton(),
          title: Text(context.t.dashboard_forms.form_error),
        ),
        body: Center(child: Text('$error')),
      ),
      data: (state) {
        if (_nameController.text != state.name) {
          _nameController.text = state.name;
        }
        if (_codesInputController.text != state.codesInput) {
          _codesInputController.text = state.codesInput;
        }
        if (_displayHintController.text != state.displayHint) {
          _displayHintController.text = state.displayHint;
        }
        if (_descriptionController.text != state.description) {
          _descriptionController.text = state.description;
        }

        final notifier = ref.read(
          recoveryCodesFormProvider(widget.recoveryCodesId).notifier,
        );

        final generatedAtDisplay = state.generatedAt.isNotEmpty
            ? _dateTimeFormat.format(
                DateTime.tryParse(state.generatedAt) ?? DateTime.now(),
              )
            : '';

        return Scaffold(
          appBar: AppBar(
            leading: const FormCloseButton(),
            title: Text(
              state.isEditMode
                  ? context.t.dashboard_forms.edit_recovery_codes
                  : context.t.dashboard_forms.new_recovery_codes,
            ),
            actions: [
              if (state.isSaving)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(icon: const Icon(Icons.save), onPressed: _save),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: formPadding,
              children: [
                // Название
                TextField(
                  controller: _nameController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.name_label,
                    errorText: state.nameError,
                    prefixIcon: const Icon(LucideIcons.tag),
                  ),
                  onChanged: notifier.setName,
                ),
                const SizedBox(height: 12),

                // Существующие коды (только в режиме редактирования)
                if (state.isEditMode && state.existingCodes.isNotEmpty) ...[
                  Text(
                    context.t.dashboard_forms.codes_label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...state.existingCodes.map(
                    (c) => _ExistingCodeTile(
                      code: c.code,
                      used: c.used,
                      position: c.position,
                      onDelete: () => notifier.markCodeForDeletion(c.id),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Поле для добавления новых кодов
                TextField(
                  controller: _codesInputController,
                  minLines: 4,
                  maxLines: 10,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.codes_label,
                    hintText: context.t.dashboard_forms.paste_codes_hint,
                    errorText: state.codesInputError,
                    prefixIcon: const Icon(LucideIcons.code),
                  ),
                  onChanged: notifier.setCodesInput,
                ),
                const SizedBox(height: 12),

                // Дата генерации
                TextField(
                  controller: TextEditingController(text: generatedAtDisplay),
                  readOnly: true,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.generated_at_iso_label,
                    errorText: state.generatedAtError,
                    prefixIcon: const Icon(LucideIcons.calendar),
                    suffixIcon: state.generatedAt.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => notifier.setGeneratedAt(''),
                          )
                        : null,
                  ),
                  onTap: () => _pickDateTime(
                    context: context,
                    current: state.generatedAt,
                    onChanged: notifier.setGeneratedAt,
                  ),
                ),
                const SizedBox(height: 12),

                // Подсказка
                TextField(
                  controller: _displayHintController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.display_hint_label,
                    prefixIcon: const Icon(LucideIcons.info),
                  ),
                  onChanged: notifier.setDisplayHint,
                ),
                const SizedBox(height: 12),

                // Категория
                CategoryPickerField(
                  selectedCategoryId: state.categoryId,
                  selectedCategoryName: state.categoryName,
                  filterByType: const [
                    CategoryType.recoveryCodes,
                    CategoryType.mixed,
                  ],
                  onCategorySelected: notifier.setCategory,
                ),
                const SizedBox(height: 12),

                // Теги
                TagPickerField(
                  selectedTagIds: state.tagIds,
                  selectedTagNames: state.tagNames,
                  filterByType: const [TagType.recoveryCodes, TagType.mixed],
                  onTagsSelected: notifier.setTags,
                ),
                const SizedBox(height: 12),

                // Заметка
                NotePickerField(
                  selectedNoteId: state.noteId,
                  selectedNoteName: state.noteName,
                  onNoteSelected: notifier.setNote,
                ),
                const SizedBox(height: 12),

                // Описание
                TextField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.description_label,
                    prefixIcon: const Icon(LucideIcons.fileText),
                  ),
                  onChanged: notifier.setDescription,
                ),
                const SizedBox(height: 8),

                // Одноразовые коды
                SwitchListTile(
                  value: state.oneTime,
                  onChanged: notifier.setOneTime,
                  title: Text(context.t.dashboard_forms.one_time_codes_label),
                ),
                const SizedBox(height: 12),
                CustomFieldsEditor(
                  fields: state.customFields,
                  onChanged: notifier.setCustomFields,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExistingCodeTile extends StatelessWidget {
  const _ExistingCodeTile({
    required this.code,
    required this.used,
    this.position,
    this.onDelete,
  });

  final String code;
  final bool used;
  final int? position;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final textStyle = used
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: Theme.of(context).colorScheme.outline,
          )
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${(position ?? 0) + 1}.',
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(code, style: textStyle)),
          if (used)
            Icon(
              Icons.check_circle_outline,
              size: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: context.t.dashboard_forms.delete_code_label,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
