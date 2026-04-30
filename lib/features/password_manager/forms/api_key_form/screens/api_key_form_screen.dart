import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_db/core/models/dto/icon_ref_dto.dart';
import 'package:hoplixi/main_db/core/models/enums/entity_types.dart';
import 'package:hoplixi/features/password_manager/forms/form_close_button.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/note_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_editor.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:hoplixi/shared/widgets/icon_source_picker_button.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../providers/api_key_form_provider.dart';

class ApiKeyFormScreen extends ConsumerStatefulWidget {
  const ApiKeyFormScreen({super.key, this.apiKeyId});

  final String? apiKeyId;

  @override
  ConsumerState<ApiKeyFormScreen> createState() => _ApiKeyFormScreenState();
}

class _ApiKeyFormScreenState extends ConsumerState<ApiKeyFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _serviceController;
  late final TextEditingController _keyController;
  late final TextEditingController _tokenTypeController;
  late final TextEditingController _environmentController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _serviceController = TextEditingController();
    _keyController = TextEditingController();
    _tokenTypeController = TextEditingController();
    _environmentController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serviceController.dispose();
    _keyController.dispose();
    _tokenTypeController.dispose();
    _environmentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final success = await ref
        .read(apiKeyFormProvider(widget.apiKeyId).notifier)
        .save();

    if (!mounted) return;

    if (!success) {
      Toaster.error(
        title: context.t.dashboard_forms.api_key_save_error,
        description: context.t.dashboard_forms.api_key_check_fields_message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(apiKeyFormProvider(widget.apiKeyId));

    ref.listen(apiKeyFormProvider(widget.apiKeyId), (prev, next) {
      final wasSaved = prev?.value?.isSaved ?? false;
      final isSaved = next.value?.isSaved ?? false;
      if (!wasSaved && isSaved) {
        Toaster.success(
          title: widget.apiKeyId != null
              ? context.t.dashboard_forms.api_key_updated
              : context.t.dashboard_forms.api_key_created,
        );
        ref.read(apiKeyFormProvider(widget.apiKeyId).notifier).resetSaved();
        if (context.mounted) context.pop(true);
      }
    });

    return stateAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          leading: const FormCloseButton(),
          title: Text(context.t.dashboard_forms.api_key_form_error),
        ),
        body: Center(child: Text('$error')),
      ),
      data: (state) {
        if (_nameController.text != state.name) {
          _nameController.text = state.name;
        }
        if (_serviceController.text != state.service) {
          _serviceController.text = state.service;
        }
        if (_keyController.text != state.key) {
          _keyController.text = state.key;
        }
        if (_tokenTypeController.text != state.tokenType) {
          _tokenTypeController.text = state.tokenType;
        }
        if (_environmentController.text != state.environment) {
          _environmentController.text = state.environment;
        }
        if (_descriptionController.text != state.description) {
          _descriptionController.text = state.description;
        }

        return Scaffold(
          appBar: AppBar(
            leading: const FormCloseButton(),
            title: Text(
              state.isEditMode
                  ? context.t.dashboard_forms.edit_api_key
                  : context.t.dashboard_forms.new_api_key,
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
                TextField(
                  controller: _nameController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.api_key_name_label,
                    errorText: state.nameError,
                    prefixIcon: const Icon(LucideIcons.tag),
                  ),
                  onChanged: ref
                      .read(apiKeyFormProvider(widget.apiKeyId).notifier)
                      .setName,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _serviceController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.api_key_service_label,
                    errorText: state.serviceError,
                    prefixIcon: const Icon(LucideIcons.globe),
                  ),
                  onChanged: ref
                      .read(apiKeyFormProvider(widget.apiKeyId).notifier)
                      .setService,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _keyController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.api_key_key_label,
                    errorText: state.keyError,
                    prefixIcon: const Icon(LucideIcons.key),
                  ),
                  onChanged: ref
                      .read(apiKeyFormProvider(widget.apiKeyId).notifier)
                      .setKey,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tokenTypeController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText:
                        context.t.dashboard_forms.api_key_token_type_label,
                    prefixIcon: const Icon(LucideIcons.type),
                  ),
                  onChanged: ref
                      .read(apiKeyFormProvider(widget.apiKeyId).notifier)
                      .setTokenType,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _environmentController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText:
                        context.t.dashboard_forms.api_key_environment_label,
                    prefixIcon: const Icon(LucideIcons.server),
                  ),
                  onChanged: ref
                      .read(apiKeyFormProvider(widget.apiKeyId).notifier)
                      .setEnvironment,
                ),
                const SizedBox(height: 12),
                IconSourcePickerButton(
                  iconRef: IconRefDto.fromFields(
                    iconSource: state.iconSource,
                    iconValue: state.iconValue,
                  ),
                  fallbackIcon: Icons.api,
                  title: 'Иконка записи',
                  onChanged: ref
                      .read(apiKeyFormProvider(widget.apiKeyId).notifier)
                      .setIconRef,
                ),
                const SizedBox(height: 12),
                CategoryPickerField(
                  selectedCategoryId: state.categoryId,
                  selectedCategoryName: state.categoryName,
                  filterByType: const [CategoryType.apiKey, CategoryType.mixed],
                  onCategorySelected: ref
                      .read(apiKeyFormProvider(widget.apiKeyId).notifier)
                      .setCategory,
                ),
                const SizedBox(height: 12),
                TagPickerField(
                  selectedTagIds: state.tagIds,
                  selectedTagNames: state.tagNames,
                  filterByType: const [TagType.apiKey, TagType.mixed],
                  onTagsSelected: ref
                      .read(apiKeyFormProvider(widget.apiKeyId).notifier)
                      .setTags,
                ),
                const SizedBox(height: 12),
                NotePickerField(
                  selectedNoteId: state.noteId,
                  selectedNoteName: state.noteName,
                  onNoteSelected: ref
                      .read(apiKeyFormProvider(widget.apiKeyId).notifier)
                      .setNote,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: primaryInputDecoration(
                    context,
                    labelText:
                        context.t.dashboard_forms.api_key_description_label,
                    prefixIcon: const Icon(LucideIcons.fileText),
                  ),
                  onChanged: ref
                      .read(apiKeyFormProvider(widget.apiKeyId).notifier)
                      .setDescription,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(
                    text: state.expiresAt != null
                        ? DateFormat(
                            'dd.MM.yyyy HH:mm',
                          ).format(state.expiresAt!)
                        : '',
                  ),
                  readOnly: true,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.expiration_date_label,
                    hintText: context.t.dashboard_forms.select_date_time_hint,
                    prefixIcon: const Icon(LucideIcons.calendar),
                    suffixIcon: state.expiresAt != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => ref
                                .read(
                                  apiKeyFormProvider(widget.apiKeyId).notifier,
                                )
                                .setExpiresAt(null),
                          )
                        : null,
                  ),
                  onTap: () async {
                    final initialDate = state.expiresAt ?? DateTime.now();
                    final date = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(DateTime.now().year + 150),
                    );
                    if (date != null && context.mounted) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(initialDate),
                      );
                      if (time != null) {
                        final finalDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                        ref
                            .read(apiKeyFormProvider(widget.apiKeyId).notifier)
                            .setExpiresAt(finalDateTime);
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: state.revoked,
                  onChanged: ref
                      .read(apiKeyFormProvider(widget.apiKeyId).notifier)
                      .setRevoked,
                  title: Text(context.t.dashboard_forms.api_key_revoked_label),
                ),
                const SizedBox(height: 12),
                CustomFieldsEditor(
                  fields: state.customFields,
                  onChanged: ref
                      .read(apiKeyFormProvider(widget.apiKeyId).notifier)
                      .setCustomFields,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
