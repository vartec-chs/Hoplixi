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

class CertificateViewScreen extends ConsumerStatefulWidget {
  const CertificateViewScreen({super.key, required this.certificateId});

  final String certificateId;

  @override
  ConsumerState<CertificateViewScreen> createState() =>
      _CertificateViewScreenState();
}

class _CertificateViewScreenState extends ConsumerState<CertificateViewScreen> {
  bool _loading = true;
  bool _isDeleted = false;
  bool _showPrivateKey = false;
  bool _showPfxPassword = false;
  String? _privateKey;
  String? _pfxPassword;

  String _name = '';
  String _certificatePem = '';
  String? _serialNumber;
  String? _issuer;
  String? _subject;
  String? _fingerprint;
  String? _ocspUrl;
  String? _crlUrl;
  String? _description;
  bool _autoRenew = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dao = await ref.read(certificateDaoProvider.future);
      final row = await dao.getById(widget.certificateId);
      if (row == null) {
        Toaster.error(title: context.t.dashboard_forms.certificate_not_found);
        if (mounted) context.pop();
        return;
      }
      final item = row.$1;
      final cert = row.$2;
      setState(() {
        _isDeleted = item.isDeleted;
        _name = item.name;
        _certificatePem = cert.certificatePem;
        _serialNumber = cert.serialNumber;
        _issuer = cert.issuer;
        _subject = cert.subject;
        _fingerprint = cert.fingerprint;
        _ocspUrl = cert.ocspUrl;
        _crlUrl = cert.crlUrl;
        _description = item.description;
        _autoRenew = cert.autoRenew;
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

  Future<void> _revealPrivateKey() async {
    if (_privateKey != null) {
      setState(() => _showPrivateKey = !_showPrivateKey);
      return;
    }

    try {
      final dao = await ref.read(certificateDaoProvider.future);
      final value = await dao.getPrivateKeyFieldById(widget.certificateId);
      if (value == null || value.isEmpty) {
        Toaster.warning(
          title: context.t.dashboard_forms.common_field_missing(
            Field: context.t.dashboard_forms.private_key_label,
          ),
        );
        return;
      }
      setState(() {
        _privateKey = value;
        _showPrivateKey = true;
      });
    } catch (e) {
      Toaster.error(
        title: context.t.dashboard_forms.common_error_getting_field(
          Field: context.t.dashboard_forms.private_key_label,
        ),
        description: '$e',
      );
    }
  }

  Future<void> _revealPfxPassword() async {
    if (_pfxPassword != null) {
      setState(() => _showPfxPassword = !_showPfxPassword);
      return;
    }

    try {
      final dao = await ref.read(certificateDaoProvider.future);
      final value = await dao.getPasswordForPfxFieldById(widget.certificateId);
      if (value == null || value.isEmpty) {
        Toaster.warning(
          title: context.t.dashboard_forms.common_field_missing(
            Field: context.t.dashboard_forms.pfx_password_label,
          ),
        );
        return;
      }
      setState(() {
        _pfxPassword = value;
        _showPfxPassword = true;
      });
    } catch (e) {
      Toaster.error(
        title: context.t.dashboard_forms.common_error_getting_field(
          Field: context.t.dashboard_forms.pfx_password_label,
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

  Future<void> _share() async {
    final l10n = context.t.dashboard_forms;
    String? privateKey = _privateKey;
    String? pfxPassword = _pfxPassword;
    try {
      final dao = await ref.read(certificateDaoProvider.future);
      privateKey ??= await dao.getPrivateKeyFieldById(widget.certificateId);
      pfxPassword ??= await dao.getPasswordForPfxFieldById(
        widget.certificateId,
      );
    } catch (e) {
      Toaster.error(title: l10n.common_load_error, description: '$e');
    }

    final customFields = await loadCustomShareableFields(
      ref,
      widget.certificateId,
    );
    final fields = [
      ...compactShareableFields([
        shareableField(id: 'name', label: l10n.share_name_label, value: _name),
        shareableField(
          id: 'certificate_pem',
          label: l10n.certificate_pem_label,
          value: _certificatePem,
        ),
        shareableField(
          id: 'private_key',
          label: l10n.private_key_label,
          value: privateKey,
          isSensitive: true,
        ),
        shareableField(
          id: 'pfx_password',
          label: l10n.pfx_password_label,
          value: pfxPassword,
          isSensitive: true,
        ),
        shareableField(id: 'issuer', label: l10n.issuer_label, value: _issuer),
        shareableField(
          id: 'subject',
          label: l10n.subject_label,
          value: _subject,
        ),
        shareableField(
          id: 'serial_number',
          label: l10n.serial_number_label,
          value: _serialNumber,
        ),
        shareableField(
          id: 'fingerprint',
          label: l10n.fingerprint_label,
          value: _fingerprint,
        ),
        shareableField(
          id: 'ocsp_url',
          label: l10n.ocsp_url_label,
          value: _ocspUrl,
        ),
        shareableField(
          id: 'crl_url',
          label: l10n.crl_url_label,
          value: _crlUrl,
        ),
        shareableField(
          id: 'auto_renew',
          label: l10n.auto_renew_label,
          value: _autoRenew ? l10n.common_enabled : l10n.common_disabled,
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
        entityTypeLabel: EntityType.certificate.label,
        fields: fields,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.dashboard_forms;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.view_certificate),
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
                      EntityType.certificate,
                      widget.certificateId,
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
                    title: Text(l10n.certificate_pem_label),
                    subtitle: SelectableText(_certificatePem),
                    trailing: IconButton(
                      onPressed: () => _copyText(
                        l10n.certificate_pem_label,
                        _certificatePem,
                      ),
                      icon: const Icon(Icons.copy),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.private_key_label),
                    subtitle: SelectableText(
                      _showPrivateKey
                          ? (_privateKey ?? '')
                          : l10n.common_press_visibility_to_load,
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          onPressed: _revealPrivateKey,
                          icon: Icon(
                            _showPrivateKey
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _copyText(l10n.private_key_label, _privateKey),
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.pfx_password_label),
                    subtitle: Text(
                      _showPfxPassword
                          ? (_pfxPassword ?? '')
                          : l10n.common_press_visibility_to_load,
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          onPressed: _revealPfxPassword,
                          icon: Icon(
                            _showPfxPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _copyText(l10n.pfx_password_label, _pfxPassword),
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  ),
                  if (_issuer?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.issuer_label),
                      subtitle: Text(_issuer!),
                    ),
                  if (_subject?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.subject_label),
                      subtitle: Text(_subject!),
                    ),
                  if (_serialNumber?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.serial_number_label),
                      subtitle: Text(_serialNumber!),
                    ),
                  if (_fingerprint?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.fingerprint_label),
                      subtitle: Text(_fingerprint!),
                    ),
                  if (_ocspUrl?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.ocsp_url_label),
                      subtitle: Text(_ocspUrl!),
                    ),
                  if (_crlUrl?.isNotEmpty == true)
                    ListTile(
                      title: Text(l10n.crl_url_label),
                      subtitle: Text(_crlUrl!),
                    ),
                  ListTile(
                    title: Text(l10n.auto_renew_label),
                    subtitle: Text(
                      _autoRenew ? l10n.common_enabled : l10n.common_disabled,
                    ),
                  ),
                  if (_description?.isNotEmpty == true)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.description_label),
                      subtitle: Text(_description!),
                    ),
                  CustomFieldsViewSection(itemId: widget.certificateId),
                ],
              ),
      ),
    );
  }
}
