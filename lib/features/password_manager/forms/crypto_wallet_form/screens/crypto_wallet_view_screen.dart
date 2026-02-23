import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/generated/l10n.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';

class CryptoWalletViewScreen extends ConsumerStatefulWidget {
  const CryptoWalletViewScreen({super.key, required this.cryptoWalletId});

  final String cryptoWalletId;

  @override
  ConsumerState<CryptoWalletViewScreen> createState() =>
      _CryptoWalletViewScreenState();
}

class _CryptoWalletViewScreenState
    extends ConsumerState<CryptoWalletViewScreen> {
  bool _loading = true;
  bool _showMnemonic = false;
  bool _showPrivateKey = false;
  bool _showXprv = false;

  String? _mnemonic;
  String? _privateKey;
  String? _xprv;

  String _name = '';
  String _walletType = '';
  String? _network;
  String? _derivationPath;
  String? _addresses;
  String? _xpub;
  String? _hardwareDevice;
  String? _derivationScheme;
  String? _description;
  bool _watchOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dao = await ref.read(cryptoWalletDaoProvider.future);
      final row = await dao.getById(widget.cryptoWalletId);
      if (row == null) {
        Toaster.error(title: S.of(context).cryptoWalletNotFound);
        if (mounted) context.pop();
        return;
      }
      final item = row.$1;
      final wallet = row.$2;

      setState(() {
        _name = item.name;
        _walletType = wallet.walletType;
        _network = wallet.network;
        _derivationPath = wallet.derivationPath;
        _addresses = wallet.addresses;
        _xpub = wallet.xpub;
        _hardwareDevice = wallet.hardwareDevice;
        _derivationScheme = wallet.derivationScheme;
        _description = item.description;
        _watchOnly = wallet.watchOnly;
      });
    } catch (e) {
      Toaster.error(title: S.of(context).commonLoadError, description: '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revealMnemonic() async {
    if (_mnemonic != null) {
      setState(() => _showMnemonic = !_showMnemonic);
      return;
    }

    try {
      final dao = await ref.read(cryptoWalletDaoProvider.future);
      final value = await dao.getMnemonicFieldById(widget.cryptoWalletId);
      if (value == null || value.isEmpty) {
        Toaster.warning(
          title: S.of(context).commonFieldMissing(S.of(context).mnemonicLabel),
        );
        return;
      }
      setState(() {
        _mnemonic = value;
        _showMnemonic = true;
      });
    } catch (e) {
      Toaster.error(
        title: S.of(context).commonErrorGettingField(S.of(context).mnemonicLabel),
        description: '$e',
      );
    }
  }

  Future<void> _revealPrivateKey() async {
    if (_privateKey != null) {
      setState(() => _showPrivateKey = !_showPrivateKey);
      return;
    }

    try {
      final dao = await ref.read(cryptoWalletDaoProvider.future);
      final value = await dao.getPrivateKeyFieldById(widget.cryptoWalletId);
      if (value == null || value.isEmpty) {
        Toaster.warning(
          title: S.of(context).commonFieldMissing(S.of(context).privateKeyLabel),
        );
        return;
      }
      setState(() {
        _privateKey = value;
        _showPrivateKey = true;
      });
    } catch (e) {
      Toaster.error(
        title: S.of(context).commonErrorGettingField(S.of(context).privateKeyLabel),
        description: '$e',
      );
    }
  }

  Future<void> _revealXprv() async {
    if (_xprv != null) {
      setState(() => _showXprv = !_showXprv);
      return;
    }

    try {
      final dao = await ref.read(cryptoWalletDaoProvider.future);
      final value = await dao.getXprvFieldById(widget.cryptoWalletId);
      if (value == null || value.isEmpty) {
        Toaster.warning(
          title: S.of(context).commonFieldMissing(S.of(context).xprvLabel),
        );
        return;
      }
      setState(() {
        _xprv = value;
        _showXprv = true;
      });
    } catch (e) {
      Toaster.error(
        title: S.of(context).commonErrorGettingField(S.of(context).xprvLabel),
        description: '$e',
      );
    }
  }

  Future<void> _copyText(String title, String? value) async {
    if (value == null || value.isEmpty) {
      Toaster.warning(title: S.of(context).commonFieldEmpty(title));
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    Toaster.success(title: S.of(context).commonFieldCopied(title));
  }

  Widget _buildSensitiveTile({
    required String title,
    required String? value,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: SelectableText(
        isVisible ? (value ?? '') : S.of(context).commonPressVisibilityToLoad,
      ),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            onPressed: onToggle,
            icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility),
          ),
          IconButton(
            onPressed: () => _copyText(title, value),
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.viewCryptoWallet),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            onPressed: () => context.push(
              AppRoutesPaths.dashboardEntityEdit(
                EntityType.cryptoWallet,
                widget.cryptoWalletId,
              ),
            ),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(_name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.walletTypeLabel),
                  subtitle: Text(_walletType),
                ),
                _buildSensitiveTile(
                  title: l10n.mnemonicLabel,
                  value: _mnemonic,
                  isVisible: _showMnemonic,
                  onToggle: _revealMnemonic,
                ),
                _buildSensitiveTile(
                  title: l10n.privateKeyLabel,
                  value: _privateKey,
                  isVisible: _showPrivateKey,
                  onToggle: _revealPrivateKey,
                ),
                _buildSensitiveTile(
                  title: l10n.xprvLabel,
                  value: _xprv,
                  isVisible: _showXprv,
                  onToggle: _revealXprv,
                ),
                if (_xpub?.isNotEmpty == true)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.xpubLabel),
                    subtitle: SelectableText(_xpub!),
                    trailing: IconButton(
                      onPressed: () => _copyText(l10n.xpubLabel, _xpub),
                      icon: const Icon(Icons.copy),
                    ),
                  ),
                if (_network?.isNotEmpty == true)
                  ListTile(title: Text(l10n.networkLabel), subtitle: Text(_network!)),
                if (_derivationPath?.isNotEmpty == true)
                  ListTile(
                    title: Text(l10n.derivationPathLabel),
                    subtitle: Text(_derivationPath!),
                  ),
                if (_derivationScheme?.isNotEmpty == true)
                  ListTile(
                    title: Text(l10n.derivationSchemeLabel),
                    subtitle: Text(_derivationScheme!),
                  ),
                if (_hardwareDevice?.isNotEmpty == true)
                  ListTile(
                    title: Text(l10n.hardwareDeviceLabel),
                    subtitle: Text(_hardwareDevice!),
                  ),
                if (_addresses?.isNotEmpty == true)
                  ListTile(
                    title: Text(l10n.addressesJsonLabel),
                    subtitle: SelectableText(_addresses!),
                  ),
                ListTile(
                  title: Text(l10n.watchOnlyLabel),
                  subtitle:
                      Text(_watchOnly ? l10n.commonEnabled : l10n.commonDisabled),
                ),
                if (_description?.isNotEmpty == true)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.descriptionLabel),
                    subtitle: Text(_description!),
                  ),
              ],
            ),
    );
  }
}
