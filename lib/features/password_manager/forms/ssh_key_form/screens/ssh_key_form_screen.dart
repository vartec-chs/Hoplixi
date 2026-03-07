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
import 'package:hoplixi/generated/l10n/translations.g.dart';

import '../providers/ssh_key_form_provider.dart';

class SshKeyFormScreen extends ConsumerStatefulWidget {
  const SshKeyFormScreen({super.key, this.sshKeyId});

  final String? sshKeyId;

  @override
  ConsumerState<SshKeyFormScreen> createState() => _SshKeyFormScreenState();
}

class _SshKeyFormScreenState extends ConsumerState<SshKeyFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _publicKeyController;
  late final TextEditingController _privateKeyController;
  late final TextEditingController _keyTypeController;
  late final TextEditingController _fingerprintController;
  late final TextEditingController _usageController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _publicKeyController = TextEditingController();
    _privateKeyController = TextEditingController();
    _keyTypeController = TextEditingController();
    _fingerprintController = TextEditingController();
    _usageController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _publicKeyController.dispose();
    _privateKeyController.dispose();
    _keyTypeController.dispose();
    _fingerprintController.dispose();
    _usageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final success = await ref
        .read(sshKeyFormProvider(widget.sshKeyId).notifier)
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
    final stateAsync = ref.watch(sshKeyFormProvider(widget.sshKeyId));

    ref.listen(sshKeyFormProvider(widget.sshKeyId), (prev, next) {
      final wasSaved = prev?.value?.isSaved ?? false;
      final isSaved = next.value?.isSaved ?? false;
      if (!wasSaved && isSaved) {
        Toaster.success(
          title: widget.sshKeyId != null
              ? context.t.dashboard_forms.ssh_key_updated
              : context.t.dashboard_forms.ssh_key_created,
        );
        ref.read(sshKeyFormProvider(widget.sshKeyId).notifier).resetSaved();
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
        if (_publicKeyController.text != state.publicKey) {
          _publicKeyController.text = state.publicKey;
        }
        if (_privateKeyController.text != state.privateKey) {
          _privateKeyController.text = state.privateKey;
        }
        if (_keyTypeController.text != state.keyType) {
          _keyTypeController.text = state.keyType;
        }
        if (_fingerprintController.text != state.fingerprint) {
          _fingerprintController.text = state.fingerprint;
        }
        if (_usageController.text != state.usage) {
          _usageController.text = state.usage;
        }
        if (_descriptionController.text != state.description) {
          _descriptionController.text = state.description;
        }

        final notifier = ref.read(sshKeyFormProvider(widget.sshKeyId).notifier);

        return Scaffold(
          appBar: AppBar(
            leading: const FormCloseButton(),
            title: Text(
              state.isEditMode
                  ? context.t.dashboard_forms.edit_ssh_key
                  : context.t.dashboard_forms.new_ssh_key,
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
                    labelText: context.t.dashboard_forms.name_label,
                    errorText: state.nameError,
                  ),
                  onChanged: notifier.setName,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _publicKeyController,
                  minLines: 2,
                  maxLines: 5,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.public_key_required_label,
                    errorText: state.publicKeyError,
                  ),
                  onChanged: notifier.setPublicKey,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _privateKeyController,
                  minLines: 2,
                  maxLines: 6,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.private_key_required_label,
                    errorText: state.privateKeyError,
                  ),
                  onChanged: notifier.setPrivateKey,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _keyTypeController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.key_type_label,
                  ),
                  onChanged: notifier.setKeyType,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _fingerprintController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.fingerprint_label,
                  ),
                  onChanged: notifier.setFingerprint,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _usageController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.usage_label,
                  ),
                  onChanged: notifier.setUsage,
                ),
                const SizedBox(height: 12),
                CategoryPickerField(
                  selectedCategoryId: state.categoryId,
                  selectedCategoryName: state.categoryName,
                  filterByType: const [CategoryType.sshKey, CategoryType.mixed],
                  onCategorySelected: notifier.setCategory,
                ),
                const SizedBox(height: 12),
                TagPickerField(
                  selectedTagIds: state.tagIds,
                  selectedTagNames: state.tagNames,
                  filterByType: const [TagType.sshKey, TagType.mixed],
                  onTagsSelected: notifier.setTags,
                ),
                const SizedBox(height: 12),
                NotePickerField(
                  selectedNoteId: state.noteId,
                  selectedNoteName: state.noteName,
                  onNoteSelected: notifier.setNote,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.description_label,
                  ),
                  onChanged: notifier.setDescription,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: state.addedToAgent,
                  onChanged: notifier.setAddedToAgent,
                  title: Text(context.t.dashboard_forms.added_to_ssh_agent_label),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
