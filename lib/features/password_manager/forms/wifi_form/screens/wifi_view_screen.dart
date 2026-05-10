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
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';

import '../services/wifi_os_bridge.dart';

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
  bool _isDeleted = false;
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
        Toaster.error(title: context.t.dashboard_forms.wifi_not_found);
        if (mounted) context.pop();
        return;
      }
      final item = row.$1;
      final wifi = row.$2;

      setState(() {
        _name = item.name;
        _ssid = wifi.ssid;
        _isDeleted = item.isDeleted;
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
      Toaster.error(
        title: context.t.dashboard_forms.common_load_error,
        description: '$e',
      );
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
          title: context.t.dashboard_forms.common_field_missing(
            Field: context.t.dashboard_forms.wifi_password_label,
          ),
        );
        return;
      }
      setState(() {
        _password = value;
        _showPassword = true;
      });
    } catch (e) {
      Toaster.error(
        title: context.t.dashboard_forms.common_error_getting_field(
          Field: context.t.dashboard_forms.wifi_password_label,
        ),
        description: '$e',
      );
    }
  }

  Future<void> _copyText(String title, String? value) async {
    if (value == null || value.isEmpty) {
      Toaster.warning(
        title: context.t.dashboard_forms.common_field_empty(Field: title),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    Toaster.success(
      title: context.t.dashboard_forms.common_field_copied(Field: title),
    );
  }

  Future<String?> _loadPasswordForConnection() async {
    if (_password != null) {
      return _password;
    }

    final dao = await ref.read(wifiDaoProvider.future);
    final value = await dao.getPasswordFieldById(widget.wifiId);
    return value?.trim().isEmpty == true ? null : value;
  }

  Future<void> _exportToWifi() async {
    final l10n = context.t.dashboard_forms;
    final ssid = _ssid.trim();

    if (ssid.isEmpty) {
      Toaster.warning(title: l10n.validation_required_ssid);
      return;
    }

    final password = await _loadPasswordForConnection();
    if (!mounted) return;

    final result = await WifiOsBridge.connect(ssid: ssid, password: password);
    if (!mounted) return;

    result.fold(
      (_) {
        Toaster.success(title: l10n.network_label, description: ssid);
      },
      (error) {
        Toaster.error(
          title: l10n.network_label,
          description: WifiOsBridge.describeError(error),
        );
      },
    );
  }

  Future<void> _share() async {
    final l10n = context.t.dashboard_forms;
    String? password;
    try {
      password = await _loadPasswordForConnection();
    } catch (e) {
      Toaster.error(
        title: l10n.common_error_getting_field(Field: l10n.wifi_password_label),
        description: '$e',
      );
    }

    final customFields = await loadCustomShareableFields(ref, widget.wifiId);
    final fields = [
      ...compactShareableFields([
        shareableField(id: 'name', label: l10n.share_name_label, value: _name),
        shareableField(id: 'ssid', label: 'SSID', value: _ssid),
        shareableField(
          id: 'password',
          label: l10n.wifi_password_label,
          value: password,
          isSensitive: true,
        ),
        shareableField(
          id: 'security',
          label: l10n.wifi_security_label,
          value: _security,
        ),
        shareableField(
          id: 'hidden',
          label: l10n.wifi_hidden_network_label,
          value: _hidden ? l10n.common_yes : l10n.common_no,
        ),
        shareableField(
          id: 'eap_method',
          label: l10n.wifi_eap_method_label,
          value: _eapMethod,
        ),
        shareableField(
          id: 'username',
          label: l10n.wifi_username_label,
          value: _username,
        ),
        shareableField(
          id: 'identity',
          label: l10n.wifi_identity_label,
          value: _identity,
        ),
        shareableField(
          id: 'domain',
          label: l10n.wifi_domain_label,
          value: _domain,
        ),
        shareableField(
          id: 'last_connected_bssid',
          label: l10n.wifi_last_connected_bssid_label,
          value: _lastConnectedBssid,
        ),
        shareableField(
          id: 'priority',
          label: l10n.wifi_priority_label,
          value: _priority,
        ),
        shareableField(
          id: 'qr_payload',
          label: l10n.wifi_qr_payload_label,
          value: _qrPayload,
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
        entityTypeLabel: EntityType.wifi.label,
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
        title: Text(l10n.view_wifi),
        actions: [
          IconButton(
            tooltip: l10n.network_label,
            onPressed: _loading ? null : _exportToWifi,
            icon: const Icon(Icons.upload_rounded),
          ),
          IconButton(
            tooltip: l10n.share_action,
            onPressed: _loading || _isDeleted ? null : _share,
            icon: const Icon(Icons.share),
          ),
          IconButton(
            tooltip: l10n.edit,
            onPressed: () => _isDeleted
                ? null
                : context.push(
                    AppRoutesPaths.dashboardEntityEdit(
                      EntityType.wifi,
                      widget.wifiId,
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
                  ListTile(title: const Text('SSID'), subtitle: Text(_ssid)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.wifi_password_label),
                    subtitle: SelectableText(
                      _showPassword
                          ? (_password ?? '')
                          : l10n.common_press_visibility_to_load,
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          onPressed: _revealPassword,
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _copyText(l10n.wifi_password_label, _password),
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  ),
                  if (_security?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.wifi_security_label),
                      subtitle: Text(_security!),
                    ),
                  ListTile(
                    title: Text(l10n.wifi_hidden_network_label),
                    subtitle: Text(_hidden ? l10n.common_yes : l10n.common_no),
                  ),
                  if (_eapMethod?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.wifi_eap_method_label),
                      subtitle: Text(_eapMethod!),
                    ),
                  if (_username?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.wifi_username_label),
                      subtitle: Text(_username!),
                    ),
                  if (_identity?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.wifi_identity_label),
                      subtitle: Text(_identity!),
                    ),
                  if (_domain?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.wifi_domain_label),
                      subtitle: Text(_domain!),
                    ),
                  if (_lastConnectedBssid?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.wifi_last_connected_bssid_label),
                      subtitle: Text(_lastConnectedBssid!),
                    ),
                  if (_priority != null)
                    ListTile(
                      title: Text(l10n.wifi_priority_label),
                      subtitle: Text('$_priority'),
                    ),
                  if (_qrPayload?.isNotEmpty == true)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.wifi_qr_payload_label),
                      subtitle: SelectableText(_qrPayload!),
                      trailing: IconButton(
                        onPressed: () =>
                            _copyText(l10n.wifi_qr_payload_label, _qrPayload),
                        icon: const Icon(Icons.copy),
                      ),
                    ),
                  if (_description?.isNotEmpty == true)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.description_label),
                      subtitle: Text(_description!),
                    ),
                  CustomFieldsViewSection(itemId: widget.wifiId),
                ],
              ),
      ),
    );
  }
}
