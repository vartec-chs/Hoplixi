import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/form_close_button.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/note_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

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
        title: 'Ошибка сохранения',
        description: 'Проверьте поля формы и попробуйте снова',
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
              ? 'API-ключ обновлен'
              : 'API-ключ создан',
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
          title: const Text('Ошибка формы'),
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
              state.isEditMode ? 'Редактировать API-ключ' : 'Новый API-ключ',
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
          body: ListView(
            padding: formPadding,
            children: [
              TextField(
                controller: _nameController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Название *',
                  errorText: state.nameError,
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
                  labelText: 'Сервис *',
                  errorText: state.serviceError,
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
                  labelText: 'Ключ *',
                  errorText: state.keyError,
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
                  labelText: 'Тип токена',
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
                  labelText: 'Окружение',
                ),
                onChanged: ref
                    .read(apiKeyFormProvider(widget.apiKeyId).notifier)
                    .setEnvironment,
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
                  labelText: 'Описание',
                ),
                onChanged: ref
                    .read(apiKeyFormProvider(widget.apiKeyId).notifier)
                    .setDescription,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: state.revoked,
                onChanged: ref
                    .read(apiKeyFormProvider(widget.apiKeyId).notifier)
                    .setRevoked,
                title: const Text('Ключ отозван'),
              ),
            ],
          ),
        );
      },
    );
  }
}
