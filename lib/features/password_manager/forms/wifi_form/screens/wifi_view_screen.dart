import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/generated/l10n.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';

class WifiViewScreen extends ConsumerStatefulWidget {
  const WifiViewScreen({super.key, required this.wifiId});

  final String wifiId;

  @override
  ConsumerState<WifiViewScreen> createState() => _WifiViewScreenState();
}

class _WifiViewScreenState extends ConsumerState<WifiViewScreen> {
  bool _loading = true;
  bool _showPassword = false;

  String? _password;
  String _name = '';
  String _ssid = '';
  String? _security;
  bool _hidden = false;
  String? _eapMethod;
  String? _username;
  String? _identity;
  String? _domain;
  String? _lastConnectedBssid;
  int? _priority;
  String? _qrPayload;
  String? _description;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dao = await ref.read(wifiDaoProvider.future);
      final row = await dao.getById(widget.wifiId);
      if (row == null) {
        Toaster.error(title: S.of(context).wifiNotFound);
        if (mounted) context.pop();
        return;
      }
      final item = row.$1;
      final wifi = row.$2;

      setState(() {
        _name = item.name;
        _ssid = wifi.ssid;
        _security = wifi.security;
        _hidden = wifi.hidden;
        _eapMethod = wifi.eapMethod;
        _username = wifi.username;
        _identity = wifi.identity;
        _domain = wifi.domain;
        _lastConnectedBssid = wifi.lastConnectedBssid;
        _priority = wifi.priority;
        _qrPayload = wifi.qrCodePayload;
        _description = item.description;
      });
    } catch (e) {
      Toaster.error(title: S.of(context).commonLoadError, description: '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revealPassword() async {
    if (_password != null) {
      setState(() => _showPassword = !_showPassword);
      return;
    }

    try {
      final dao = await ref.read(wifiDaoProvider.future);
      final value = await dao.getPasswordFieldById(widget.wifiId);
      if (value == null || value.isEmpty) {
        Toaster.warning(
          title: S.of(context).commonFieldMissing(S.of(context).wifiPasswordLabel),
        );
        return;
      }
      setState(() {
        _password = value;
        _showPassword = true;
      });
    } catch (e) {
      Toaster.error(
        title: S.of(context).commonErrorGettingField(
          S.of(context).wifiPasswordLabel,
        ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.viewWifi),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            onPressed: () => context.push(
              AppRoutesPaths.dashboardEntityEdit(EntityType.wifi, widget.wifiId),
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
                ListTile(title: const Text('SSID'), subtitle: Text(_ssid)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.wifiPasswordLabel),
                  subtitle: SelectableText(
                    _showPassword
                        ? (_password ?? '')
                        : l10n.commonPressVisibilityToLoad,
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        onPressed: _revealPassword,
                        icon: Icon(
                          _showPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _copyText(l10n.wifiPasswordLabel, _password),
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
                ),
                if (_security?.isNotEmpty == true)
                  ListTile(title: Text(l10n.wifiSecurityLabel), subtitle: Text(_security!)),
                ListTile(
                  title: Text(l10n.wifiHiddenNetworkLabel),
                  subtitle: Text(_hidden ? l10n.commonYes : l10n.commonNo),
                ),
                if (_eapMethod?.isNotEmpty == true)
                  ListTile(title: Text(l10n.wifiEapMethodLabel), subtitle: Text(_eapMethod!)),
                if (_username?.isNotEmpty == true)
                  ListTile(title: Text(l10n.wifiUsernameLabel), subtitle: Text(_username!)),
                if (_identity?.isNotEmpty == true)
                  ListTile(title: Text(l10n.wifiIdentityLabel), subtitle: Text(_identity!)),
                if (_domain?.isNotEmpty == true)
                  ListTile(title: Text(l10n.wifiDomainLabel), subtitle: Text(_domain!)),
                if (_lastConnectedBssid?.isNotEmpty == true)
                  ListTile(
                    title: Text(l10n.wifiLastConnectedBssidLabel),
                    subtitle: Text(_lastConnectedBssid!),
                  ),
                if (_priority != null)
                  ListTile(
                    title: Text(l10n.wifiPriorityLabel),
                    subtitle: Text('$_priority'),
                  ),
                if (_qrPayload?.isNotEmpty == true)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.wifiQrPayloadLabel),
                    subtitle: SelectableText(_qrPayload!),
                    trailing: IconButton(
                      onPressed: () =>
                          _copyText(l10n.wifiQrPayloadLabel, _qrPayload),
                      icon: const Icon(Icons.copy),
                    ),
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
