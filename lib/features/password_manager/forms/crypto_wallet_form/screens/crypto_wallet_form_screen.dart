import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class CryptoWalletFormScreen extends ConsumerStatefulWidget {
  const CryptoWalletFormScreen({super.key, this.cryptoWalletId});

  final String? cryptoWalletId;

  bool get isEdit => cryptoWalletId != null;

  @override
  ConsumerState<CryptoWalletFormScreen> createState() =>
      _CryptoWalletFormScreenState();
}

class _CryptoWalletFormScreenState
    extends ConsumerState<CryptoWalletFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _walletTypeController = TextEditingController();
  final _mnemonicController = TextEditingController();
  final _privateKeyController = TextEditingController();
  final _derivationPathController = TextEditingController();
  final _networkController = TextEditingController();
  final _addressesController = TextEditingController();
  final _xpubController = TextEditingController();
  final _xprvController = TextEditingController();
  final _hardwareController = TextEditingController();
  final _derivationSchemeController = TextEditingController();
  final _notesController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _watchOnly = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final dao = await ref.read(cryptoWalletDaoProvider.future);
      final row = await dao.getById(widget.cryptoWalletId!);
      if (row == null) return;
      final item = row.$1;
      final wallet = row.$2;

      _nameController.text = item.name;
      _walletTypeController.text = wallet.walletType;
      _mnemonicController.text = wallet.mnemonic ?? '';
      _privateKeyController.text = wallet.privateKey ?? '';
      _derivationPathController.text = wallet.derivationPath ?? '';
      _networkController.text = wallet.network ?? '';
      _addressesController.text = wallet.addresses ?? '';
      _xpubController.text = wallet.xpub ?? '';
      _xprvController.text = wallet.xprv ?? '';
      _hardwareController.text = wallet.hardwareDevice ?? '';
      _derivationSchemeController.text = wallet.derivationScheme ?? '';
      _notesController.text = wallet.notesOnUsage ?? '';
      _descriptionController.text = item.description ?? '';
      _watchOnly = wallet.watchOnly;
    } catch (e) {
      Toaster.error(title: 'Ошибка загрузки', description: '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      Toaster.error(title: 'Проверьте поля формы');
      return;
    }

    setState(() => _loading = true);
    try {
      final dao = await ref.read(cryptoWalletDaoProvider.future);

      String? clean(TextEditingController c) {
        final v = c.text.trim();
        return v.isEmpty ? null : v;
      }

      final name = _nameController.text.trim();
      final walletType = _walletTypeController.text.trim();

      if (widget.isEdit) {
        await dao.updateCryptoWallet(
          widget.cryptoWalletId!,
          UpdateCryptoWalletDto(
            name: name,
            walletType: walletType,
            mnemonic: clean(_mnemonicController),
            privateKey: clean(_privateKeyController),
            derivationPath: clean(_derivationPathController),
            network: clean(_networkController),
            addresses: clean(_addressesController),
            xpub: clean(_xpubController),
            xprv: clean(_xprvController),
            hardwareDevice: clean(_hardwareController),
            derivationScheme: clean(_derivationSchemeController),
            notesOnUsage: clean(_notesController),
            description: clean(_descriptionController),
            watchOnly: _watchOnly,
          ),
        );
      } else {
        await dao.createCryptoWallet(
          CreateCryptoWalletDto(
            name: name,
            walletType: walletType,
            mnemonic: clean(_mnemonicController),
            privateKey: clean(_privateKeyController),
            derivationPath: clean(_derivationPathController),
            network: clean(_networkController),
            addresses: clean(_addressesController),
            xpub: clean(_xpubController),
            xprv: clean(_xprvController),
            hardwareDevice: clean(_hardwareController),
            derivationScheme: clean(_derivationSchemeController),
            notesOnUsage: clean(_notesController),
            description: clean(_descriptionController),
            watchOnly: _watchOnly,
          ),
        );
      }

      Toaster.success(
        title: widget.isEdit
            ? 'Криптокошелек обновлен'
            : 'Криптокошелек создан',
      );
      if (mounted) context.pop();
    } catch (e) {
      Toaster.error(title: 'Ошибка сохранения', description: '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'Редактировать криптокошелек' : 'Новый криптокошелек',
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: const Text('Сохранить'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Название'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Название обязательно'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _walletTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Тип кошелька (seed/private_key/hardware)',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Тип кошелька обязателен'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mnemonicController,
                    decoration: const InputDecoration(labelText: 'Mnemonic'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _privateKeyController,
                    decoration: const InputDecoration(labelText: 'Private key'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _xprvController,
                    decoration: const InputDecoration(labelText: 'XPRV'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _xpubController,
                    decoration: const InputDecoration(labelText: 'XPUB'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _networkController,
                    decoration: const InputDecoration(labelText: 'Network'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _derivationPathController,
                    decoration: const InputDecoration(
                      labelText: 'Derivation path',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _derivationSchemeController,
                    decoration: const InputDecoration(
                      labelText: 'Derivation scheme',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressesController,
                    decoration: const InputDecoration(
                      labelText: 'Addresses (JSON)',
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hardwareController,
                    decoration: const InputDecoration(
                      labelText: 'Hardware device',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes on usage',
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Описание'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  SwitchListTile(
                    value: _watchOnly,
                    onChanged: (v) => setState(() => _watchOnly = v),
                    title: const Text('Watch-only'),
                  ),
                ],
              ),
            ),
    );
  }
}
