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

import '../providers/crypto_wallet_form_provider.dart';

class CryptoWalletFormScreen extends ConsumerStatefulWidget {
  const CryptoWalletFormScreen({super.key, this.cryptoWalletId});

  final String? cryptoWalletId;

  @override
  ConsumerState<CryptoWalletFormScreen> createState() =>
      _CryptoWalletFormScreenState();
}

class _CryptoWalletFormScreenState
    extends ConsumerState<CryptoWalletFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _walletTypeController;
  late final TextEditingController _mnemonicController;
  late final TextEditingController _privateKeyController;
  late final TextEditingController _derivationPathController;
  late final TextEditingController _networkController;
  late final TextEditingController _addressesController;
  late final TextEditingController _xpubController;
  late final TextEditingController _xprvController;
  late final TextEditingController _hardwareController;
  late final TextEditingController _derivationSchemeController;
  late final TextEditingController _notesController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _walletTypeController = TextEditingController();
    _mnemonicController = TextEditingController();
    _privateKeyController = TextEditingController();
    _derivationPathController = TextEditingController();
    _networkController = TextEditingController();
    _addressesController = TextEditingController();
    _xpubController = TextEditingController();
    _xprvController = TextEditingController();
    _hardwareController = TextEditingController();
    _derivationSchemeController = TextEditingController();
    _notesController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _walletTypeController.dispose();
    _mnemonicController.dispose();
    _privateKeyController.dispose();
    _derivationPathController.dispose();
    _networkController.dispose();
    _addressesController.dispose();
    _xpubController.dispose();
    _xprvController.dispose();
    _hardwareController.dispose();
    _derivationSchemeController.dispose();
    _notesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final success = await ref
        .read(cryptoWalletFormProvider(widget.cryptoWalletId).notifier)
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
    final stateAsync = ref.watch(
      cryptoWalletFormProvider(widget.cryptoWalletId),
    );

    ref.listen(cryptoWalletFormProvider(widget.cryptoWalletId), (prev, next) {
      final wasSaved = prev?.value?.isSaved ?? false;
      final isSaved = next.value?.isSaved ?? false;
      if (!wasSaved && isSaved) {
        Toaster.success(
          title: widget.cryptoWalletId != null
              ? 'Криптокошелек обновлен'
              : 'Криптокошелек создан',
        );
        ref
            .read(cryptoWalletFormProvider(widget.cryptoWalletId).notifier)
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
          title: const Text('Ошибка формы'),
        ),
        body: Center(child: Text('$error')),
      ),
      data: (state) {
        if (_nameController.text != state.name)
          _nameController.text = state.name;
        if (_walletTypeController.text != state.walletType)
          _walletTypeController.text = state.walletType;
        if (_mnemonicController.text != state.mnemonic)
          _mnemonicController.text = state.mnemonic;
        if (_privateKeyController.text != state.privateKey)
          _privateKeyController.text = state.privateKey;
        if (_derivationPathController.text != state.derivationPath)
          _derivationPathController.text = state.derivationPath;
        if (_networkController.text != state.network)
          _networkController.text = state.network;
        if (_addressesController.text != state.addresses)
          _addressesController.text = state.addresses;
        if (_xpubController.text != state.xpub)
          _xpubController.text = state.xpub;
        if (_xprvController.text != state.xprv)
          _xprvController.text = state.xprv;
        if (_hardwareController.text != state.hardwareDevice)
          _hardwareController.text = state.hardwareDevice;
        if (_derivationSchemeController.text != state.derivationScheme)
          _derivationSchemeController.text = state.derivationScheme;
        if (_notesController.text != state.notesOnUsage)
          _notesController.text = state.notesOnUsage;
        if (_descriptionController.text != state.description)
          _descriptionController.text = state.description;

        final notifier = ref.read(
          cryptoWalletFormProvider(widget.cryptoWalletId).notifier,
        );

        return Scaffold(
          appBar: AppBar(
            leading: const FormCloseButton(),
            title: Text(
              state.isEditMode
                  ? 'Редактировать криптокошелек'
                  : 'Новый криптокошелек',
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
                controller: _walletTypeController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Тип кошелька *',
                  errorText: state.walletTypeError,
                ),
                onChanged: notifier.setWalletType,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _mnemonicController,
                minLines: 2,
                maxLines: 4,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Mnemonic',
                ),
                onChanged: notifier.setMnemonic,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _privateKeyController,
                minLines: 2,
                maxLines: 4,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Private key',
                ),
                onChanged: notifier.setPrivateKey,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _xprvController,
                minLines: 2,
                maxLines: 4,
                decoration: primaryInputDecoration(context, labelText: 'XPRV'),
                onChanged: notifier.setXprv,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _xpubController,
                decoration: primaryInputDecoration(context, labelText: 'XPUB'),
                onChanged: notifier.setXpub,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _networkController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Network',
                ),
                onChanged: notifier.setNetwork,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _derivationPathController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Derivation path',
                ),
                onChanged: notifier.setDerivationPath,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _derivationSchemeController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Derivation scheme',
                ),
                onChanged: notifier.setDerivationScheme,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressesController,
                minLines: 2,
                maxLines: 4,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Addresses (JSON)',
                ),
                onChanged: notifier.setAddresses,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hardwareController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Hardware device',
                ),
                onChanged: notifier.setHardwareDevice,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Notes on usage',
                ),
                onChanged: notifier.setNotesOnUsage,
              ),
              const SizedBox(height: 12),
              CategoryPickerField(
                selectedCategoryId: state.categoryId,
                selectedCategoryName: state.categoryName,
                filterByType: const [
                  CategoryType.cryptoWallet,
                  CategoryType.mixed,
                ],
                onCategorySelected: notifier.setCategory,
              ),
              const SizedBox(height: 12),
              TagPickerField(
                selectedTagIds: state.tagIds,
                selectedTagNames: state.tagNames,
                filterByType: const [TagType.cryptoWallet, TagType.mixed],
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
                  labelText: 'Описание',
                ),
                onChanged: notifier.setDescription,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: state.watchOnly,
                onChanged: notifier.setWatchOnly,
                title: const Text('Watch-only'),
              ),
            ],
          ),
        );
      },
    );
  }
}
