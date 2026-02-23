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

import '../providers/wifi_form_provider.dart';

class WifiFormScreen extends ConsumerStatefulWidget {
  const WifiFormScreen({super.key, this.wifiId});

  final String? wifiId;

  @override
  ConsumerState<WifiFormScreen> createState() => _WifiFormScreenState();
}

class _WifiFormScreenState extends ConsumerState<WifiFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _ssidController;
  late final TextEditingController _passwordController;
  late final TextEditingController _securityController;
  late final TextEditingController _eapMethodController;
  late final TextEditingController _usernameController;
  late final TextEditingController _identityController;
  late final TextEditingController _domainController;
  late final TextEditingController _bssidController;
  late final TextEditingController _priorityController;
  late final TextEditingController _qrPayloadController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ssidController = TextEditingController();
    _passwordController = TextEditingController();
    _securityController = TextEditingController();
    _eapMethodController = TextEditingController();
    _usernameController = TextEditingController();
    _identityController = TextEditingController();
    _domainController = TextEditingController();
    _bssidController = TextEditingController();
    _priorityController = TextEditingController();
    _qrPayloadController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _securityController.dispose();
    _eapMethodController.dispose();
    _usernameController.dispose();
    _identityController.dispose();
    _domainController.dispose();
    _bssidController.dispose();
    _priorityController.dispose();
    _qrPayloadController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final success = await ref
        .read(wifiFormProvider(widget.wifiId).notifier)
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
    final stateAsync = ref.watch(wifiFormProvider(widget.wifiId));

    ref.listen(wifiFormProvider(widget.wifiId), (prev, next) {
      final wasSaved = prev?.value?.isSaved ?? false;
      final isSaved = next.value?.isSaved ?? false;
      if (!wasSaved && isSaved) {
        Toaster.success(
          title: widget.wifiId != null ? 'Wi-Fi обновлен' : 'Wi-Fi создан',
        );
        ref.read(wifiFormProvider(widget.wifiId).notifier).resetSaved();
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
        if (_ssidController.text != state.ssid) {
          _ssidController.text = state.ssid;
        }
        if (_passwordController.text != state.password) {
          _passwordController.text = state.password;
        }
        if (_securityController.text != state.security) {
          _securityController.text = state.security;
        }
        if (_eapMethodController.text != state.eapMethod) {
          _eapMethodController.text = state.eapMethod;
        }
        if (_usernameController.text != state.username) {
          _usernameController.text = state.username;
        }
        if (_identityController.text != state.identity) {
          _identityController.text = state.identity;
        }
        if (_domainController.text != state.domain) {
          _domainController.text = state.domain;
        }
        if (_bssidController.text != state.lastConnectedBssid) {
          _bssidController.text = state.lastConnectedBssid;
        }
        if (_priorityController.text != state.priority) {
          _priorityController.text = state.priority;
        }
        if (_qrPayloadController.text != state.qrCodePayload) {
          _qrPayloadController.text = state.qrCodePayload;
        }
        if (_descriptionController.text != state.description) {
          _descriptionController.text = state.description;
        }

        final notifier = ref.read(wifiFormProvider(widget.wifiId).notifier);

        return Scaffold(
          appBar: AppBar(
            leading: const FormCloseButton(),
            title: Text(
              state.isEditMode ? 'Редактировать Wi-Fi' : 'Новая Wi-Fi сеть',
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
                onChanged: notifier.setName,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ssidController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'SSID *',
                  errorText: state.ssidError,
                ),
                onChanged: notifier.setSsid,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Password',
                ),
                onChanged: notifier.setPassword,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _securityController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Security',
                ),
                onChanged: notifier.setSecurity,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _eapMethodController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'EAP method',
                ),
                onChanged: notifier.setEapMethod,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Username',
                ),
                onChanged: notifier.setUsername,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _identityController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Identity',
                ),
                onChanged: notifier.setIdentity,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _domainController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Domain',
                ),
                onChanged: notifier.setDomain,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bssidController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Last connected BSSID',
                ),
                onChanged: notifier.setLastConnectedBssid,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priorityController,
                keyboardType: TextInputType.number,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Priority',
                  errorText: state.priorityError,
                ),
                onChanged: notifier.setPriority,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _qrPayloadController,
                maxLines: 2,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'QR payload',
                ),
                onChanged: notifier.setQrCodePayload,
              ),
              const SizedBox(height: 12),
              CategoryPickerField(
                selectedCategoryId: state.categoryId,
                selectedCategoryName: state.categoryName,
                filterByType: const [CategoryType.wifi, CategoryType.mixed],
                onCategorySelected: notifier.setCategory,
              ),
              const SizedBox(height: 12),
              TagPickerField(
                selectedTagIds: state.tagIds,
                selectedTagNames: state.tagNames,
                filterByType: const [TagType.wifi, TagType.mixed],
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
                maxLines: 4,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Описание',
                ),
                onChanged: notifier.setDescription,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: state.hidden,
                onChanged: notifier.setHidden,
                title: const Text('Скрытая сеть'),
              ),
            ],
          ),
        );
      },
    );
  }
}
