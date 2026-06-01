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
import 'package:hoplixi/vault_db/core/scheme/tables/wifi/wifi_items.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';
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
  bool _isDeleted = false;

  String _name = '';
  String _ssid = '';
  String? _password;
  WifiSecurityType? _securityType;
  String? _securityTypeOther;
  WifiEncryptionType? _encryption;
  String? _encryptionOther;
  bool _hiddenSsid = false;
  String? _description;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repos = await ref.read(vaultRepositories.future);
      final viewResult = await repos.wifi.getViewById(widget.wifiId);
      final view = viewResult.getOrNull()?.getOrNull();
      if (view == null) {
        if (mounted) {
          Toaster.error(
            title: context.t.dashboard_forms.wifi_not_found,
          );
          context.pop();
        }
        return;
      }
      final item = view.item;
      final wifi = view.wifi;

      setState(() {
        _name = item.name;
        _ssid = wifi.ssid;
        _isDeleted = item.isDeleted;
        _password = wifi.password;
        _securityType = wifi.securityType;
        _securityTypeOther = wifi.securityTypeOther;
        _encryption = wifi.encryption;
        _encryptionOther = wifi.encryptionOther;
        _hiddenSsid = wifi.hiddenSsid;
        _description = item.description;
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

  Future<void> _revealPassword() async {
    setState(() => _showPassword = !_showPassword);
  }

  Future<void> _copyText(String title, String? value) async {
    if (value == null || value.isEmpty) {
      Toaster.warning(
        title: context.t.dashboard_forms.common_field_empty(Field: title),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      Toaster.success(
        title: context.t.dashboard_forms.common_field_copied(Field: title),
      );
    }
  }

  Future<void> _exportToWifi() async {
    final l10n = context.t.dashboard_forms;
    final ssid = _ssid.trim();

    if (ssid.isEmpty) {
      Toaster.warning(title: l10n.validation_required_ssid);
      return;
    }

    final password = _password?.trim().isEmpty == true ? null : _password;

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

    final customFields = await loadCustomShareableFields(ref, widget.wifiId);
    if (!mounted) return;

    String? securityLabel = _securityType?.name ?? _securityTypeOther;
    String? encryptionLabel = _encryption?.name ?? _encryptionOther;

    final fields = [
      ...compactShareableFields([
        shareableField(id: 'name', label: l10n.share_name_label, value: _name),
        shareableField(id: 'ssid', label: 'SSID', value: _ssid),
        shareableField(
          id: 'password',
          label: l10n.wifi_password_label,
          value: _password,
          isSensitive: true,
        ),
        shareableField(
          id: 'security',
          label: l10n.wifi_security_label,
          value: securityLabel,
        ),
        shareableField(
          id: 'encryption',
          label: l10n.wifi_encryption_label,
          value: encryptionLabel,
        ),
        shareableField(
          id: 'hidden',
          label: l10n.wifi_hidden_network_label,
          value: _hiddenSsid ? l10n.common_yes : l10n.common_no,
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
                          ? (_password ?? l10n.common_not_set)
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
                  if (_securityType != null)
                    ListTile(
                      title: Text(l10n.wifi_security_label),
                      subtitle: Text(_securityType!.name),
                    )
                  else if (_securityTypeOther?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.wifi_security_label),
                      subtitle: Text(_securityTypeOther!),
                    ),
                  if (_encryption != null)
                    ListTile(
                      title: Text(l10n.wifi_encryption_label),
                      subtitle: Text(_encryption!.name),
                    )
                  else if (_encryptionOther?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.wifi_encryption_label),
                      subtitle: Text(_encryptionOther!),
                    ),
                  ListTile(
                    title: Text(l10n.wifi_hidden_network_label),
                    subtitle: Text(
                      _hiddenSsid ? l10n.common_yes : l10n.common_no,
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
