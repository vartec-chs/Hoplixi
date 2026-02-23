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
import 'package:hoplixi/generated/l10n.dart';


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
  late final TextEditingController _codesBlobController;
  late final TextEditingController _codesCountController;
  late final TextEditingController _usedCountController;
  late final TextEditingController _perCodeStatusController;
  late final TextEditingController _generatedAtController;
  late final TextEditingController _displayHintController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _codesBlobController = TextEditingController();
    _codesCountController = TextEditingController();
    _usedCountController = TextEditingController();
    _perCodeStatusController = TextEditingController();
    _generatedAtController = TextEditingController();
    _displayHintController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codesBlobController.dispose();
    _codesCountController.dispose();
    _usedCountController.dispose();
    _perCodeStatusController.dispose();
    _generatedAtController.dispose();
    _displayHintController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final success = await ref
        .read(recoveryCodesFormProvider(widget.recoveryCodesId).notifier)
        .save();

    if (!mounted) return;

    if (!success) {
      Toaster.error(
        title: S.of(context).saveError,
        description: S.of(context).checkFormFieldsAndTryAgain,
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
              ? S.of(context).recoveryCodesUpdated
              : S.of(context).recoveryCodesCreated,
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
          title: Text(S.of(context).formError),
        ),
        body: Center(child: Text('$error')),
      ),
      data: (state) {
        if (_nameController.text != state.name) {
          _nameController.text = state.name;
        }
        if (_codesBlobController.text != state.codesBlob) {
          _codesBlobController.text = state.codesBlob;
        }
        if (_codesCountController.text != state.codesCount) {
          _codesCountController.text = state.codesCount;
        }
        if (_usedCountController.text != state.usedCount) {
          _usedCountController.text = state.usedCount;
        }
        if (_perCodeStatusController.text != state.perCodeStatus) {
          _perCodeStatusController.text = state.perCodeStatus;
        }
        if (_generatedAtController.text != state.generatedAt) {
          _generatedAtController.text = state.generatedAt;
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

        return Scaffold(
          appBar: AppBar(
            leading: const FormCloseButton(),
            title: Text(
              state.isEditMode
                  ? S.of(context).editRecoveryCodes
                  : S.of(context).newRecoveryCodes,
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
                  labelText: S.of(context).nameLabel,
                  errorText: state.nameError,
                ),
                onChanged: notifier.setName,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codesBlobController,
                minLines: 4,
                maxLines: 8,
                decoration: primaryInputDecoration(
                  context,
                  labelText: S.of(context).codesBlobRequiredLabel,
                  errorText: state.codesBlobError,
                ),
                onChanged: notifier.setCodesBlob,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codesCountController,
                keyboardType: TextInputType.number,
                decoration: primaryInputDecoration(
                  context,
                  labelText: S.of(context).totalCodesLabel,
                  errorText: state.codesCountError,
                ),
                onChanged: notifier.setCodesCount,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usedCountController,
                keyboardType: TextInputType.number,
                decoration: primaryInputDecoration(
                  context,
                  labelText: S.of(context).usedCodesLabel,
                  errorText: state.usedCountError,
                ),
                onChanged: notifier.setUsedCount,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _perCodeStatusController,
                minLines: 2,
                maxLines: 4,
                decoration: primaryInputDecoration(
                  context,
                  labelText: S.of(context).perCodeStatusJsonLabel,
                ),
                onChanged: notifier.setPerCodeStatus,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _generatedAtController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: S.of(context).generatedAtIsoLabel,
                  errorText: state.generatedAtError,
                ),
                onChanged: notifier.setGeneratedAt,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _displayHintController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: S.of(context).displayHintLabel,
                ),
                onChanged: notifier.setDisplayHint,
              ),
              const SizedBox(height: 12),
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
              TagPickerField(
                selectedTagIds: state.tagIds,
                selectedTagNames: state.tagNames,
                filterByType: const [TagType.recoveryCodes, TagType.mixed],
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
                  labelText: S.of(context).descriptionLabel,
                ),
                onChanged: notifier.setDescription,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: state.oneTime,
                onChanged: notifier.setOneTime,
                title: Text(S.of(context).oneTimeCodesLabel),
              ),
            ],
          ),
        );
      },
    );
  }
}



