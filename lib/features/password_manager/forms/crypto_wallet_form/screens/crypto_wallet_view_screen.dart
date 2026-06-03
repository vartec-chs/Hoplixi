import 'package:hoplixi/shared/ui/background_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/share_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/shareable_field.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_view_section.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';
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
  bool _isDeleted = false;
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
      final repos = await ref.read(vaultRepositories.future);
      if (!mounted) return;
      final viewResult = await repos.cryptoWallet.getViewById(
        widget.cryptoWalletId,
      );
      final view = viewResult.getOrNull()?.getOrNull();
      if (view == null) {
        if (mounted) {
          Toaster.error(
            title: context.t.dashboard_forms.crypto_wallet_not_found,
          );
          context.pop();
        }
        return;
      }
      final item = view.item;
      final cryptoWallet = view.cryptoWallet;

      setState(() {
        _isDeleted = item.isDeleted;
        _name = item.name;
        _walletType = cryptoWallet.walletType?.name ?? '';
        _network = cryptoWallet.network?.name;
        _derivationPath = cryptoWallet.derivationPath;
        _addresses = cryptoWallet.addresses;
        _xpub = cryptoWallet.xpub;
        _hardwareDevice = cryptoWallet.hardwareDevice;
        _derivationScheme = cryptoWallet.derivationScheme?.name;
        _description = item.description;
        _watchOnly = cryptoWallet.watchOnly;
        _mnemonic = cryptoWallet.mnemonic;
        _privateKey = cryptoWallet.privateKey;
        _xprv = cryptoWallet.xprv;
      });
    } catch (e) {
      if (mounted) {
        Toaster.error(
          title: context.t.dashboard_forms.common_load_error,
          description: '$e',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _revealMnemonic() {
    setState(() => _showMnemonic = !_showMnemonic);
  }

  void _revealPrivateKey() {
    setState(() => _showPrivateKey = !_showPrivateKey);
  }

  void _revealXprv() {
    setState(() => _showXprv = !_showXprv);
  }

  Future<void> _copyText(String title, String? value) async {
    if (value == null || value.isEmpty) {
      if (mounted) {
        Toaster.warning(
          title: context.t.dashboard_forms.common_field_empty(Field: title),
        );
      }
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      Toaster.success(
        title: context.t.dashboard_forms.common_field_copied(Field: title),
      );
    }
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
        isVisible
            ? (value ?? '')
            : context.t.dashboard_forms.common_press_visibility_to_load,
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

  Future<void> _share() async {
    final l10n = context.t.dashboard_forms;
    final customFields = await loadCustomShareableFields(
      ref,
      widget.cryptoWalletId,
    );
    if (!mounted) return;
    final fields = [
      ...compactShareableFields([
        shareableField(id: 'name', label: l10n.share_name_label, value: _name),
        shareableField(
          id: 'wallet_type',
          label: l10n.wallet_type_label,
          value: _walletType,
        ),
        shareableField(
          id: 'mnemonic',
          label: l10n.mnemonic_label,
          value: _mnemonic,
          isSensitive: true,
        ),
        shareableField(
          id: 'private_key',
          label: l10n.private_key_label,
          value: _privateKey,
          isSensitive: true,
        ),
        shareableField(
          id: 'xprv',
          label: l10n.xprv_label,
          value: _xprv,
          isSensitive: true,
        ),
        shareableField(id: 'xpub', label: l10n.xpub_label, value: _xpub),
        shareableField(
          id: 'network',
          label: l10n.network_label,
          value: _network,
        ),
        shareableField(
          id: 'derivation_path',
          label: l10n.derivation_path_label,
          value: _derivationPath,
        ),
        shareableField(
          id: 'derivation_scheme',
          label: l10n.derivation_scheme_label,
          value: _derivationScheme,
        ),
        shareableField(
          id: 'hardware_device',
          label: l10n.hardware_device_label,
          value: _hardwareDevice,
        ),
        shareableField(
          id: 'addresses',
          label: l10n.addresses_json_label,
          value: _addresses,
        ),
        shareableField(
          id: 'watch_only',
          label: l10n.watch_only_label,
          value: _watchOnly ? l10n.common_enabled : l10n.common_disabled,
        ),
        shareableField(
          id: 'description',
          label: l10n.description_label,
          value: _description,
        ),
      ]),
      ...customFields,
    ];

    await shareEntityFields(
      context: context,
      entity: ShareableEntity(
        title: _name,
        entityTypeLabel: EntityType.cryptoWallet.label,
        fields: fields,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.dashboard_forms;

    return Scaffold(
      backgroundColor: getScreenBackgroundColor(context, ref),
      appBar: AppBar(
        title: Text(l10n.view_crypto_wallet),
        actions: [
          IconButton(
            tooltip: l10n.share_action,
            onPressed: _loading || _isDeleted ? null : _share,
            icon: const Icon(Icons.share),
          ),
          IconButton(
            tooltip: l10n.edit,
            onPressed: _isDeleted
                ? null
                : () => context.push(
                    AppRoutesPaths.dashboardEntityEdit(
                      EntityType.cryptoWallet,
                      widget.cryptoWalletId,
                    ),
                  ),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(_name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.wallet_type_label),
                    subtitle: Text(_walletType),
                  ),
                  _buildSensitiveTile(
                    title: l10n.mnemonic_label,
                    value: _mnemonic,
                    isVisible: _showMnemonic,
                    onToggle: _revealMnemonic,
                  ),
                  _buildSensitiveTile(
                    title: l10n.private_key_label,
                    value: _privateKey,
                    isVisible: _showPrivateKey,
                    onToggle: _revealPrivateKey,
                  ),
                  _buildSensitiveTile(
                    title: l10n.xprv_label,
                    value: _xprv,
                    isVisible: _showXprv,
                    onToggle: _revealXprv,
                  ),
                  if (_xpub?.isNotEmpty == true)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.xpub_label),
                      subtitle: SelectableText(_xpub!),
                      trailing: IconButton(
                        onPressed: () => _copyText(l10n.xpub_label, _xpub),
                        icon: const Icon(Icons.copy),
                      ),
                    ),
                  if (_network?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.network_label),
                      subtitle: Text(_network!),
                    ),
                  if (_derivationPath?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.derivation_path_label),
                      subtitle: Text(_derivationPath!),
                    ),
                  if (_derivationScheme?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.derivation_scheme_label),
                      subtitle: Text(_derivationScheme!),
                    ),
                  if (_hardwareDevice?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.hardware_device_label),
                      subtitle: Text(_hardwareDevice!),
                    ),
                  if (_addresses?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.addresses_json_label),
                      subtitle: SelectableText(_addresses!),
                    ),
                  ListTile(
                    title: Text(l10n.watch_only_label),
                    subtitle: Text(
                      _watchOnly ? l10n.common_enabled : l10n.common_disabled,
                    ),
                  ),
                  if (_description?.isNotEmpty == true)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.description_label),
                      subtitle: Text(_description!),
                    ),
                  CustomFieldsViewSection(itemId: widget.cryptoWalletId),
                ],
              ),
      ),
    );
  }
}
