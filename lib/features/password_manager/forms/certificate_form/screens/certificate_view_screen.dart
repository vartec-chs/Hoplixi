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
      if (!mounted) return;
      final viewResult = await repos.certificate.getViewById(
        widget.certificateId,
      );
      final view = viewResult.getOrNull()?.getOrNull();
      if (view == null) {
        if (mounted) {
          Toaster.error(title: context.t.dashboard_forms.certificate_not_found);
          context.pop();
        }
        return;
      }
      final item = view.item;
      final certificate = view.certificate;
      setState(() {
        _isDeleted = item.isDeleted;
        _name = item.name;
        _certificatePem = certificate.certificatePem ?? '';
        _serialNumber = certificate.serialNumber;
        _issuer = certificate.issuer;
        _subject = certificate.subject;
        _description = item.description;
        _privateKey = certificate.privateKey;
        _pfxPassword = certificate.passwordForPfx;
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

  void _revealPrivateKey() {
    setState(() => _showPrivateKey = !_showPrivateKey);
  }

  void _revealPfxPassword() {
    setState(() => _showPfxPassword = !_showPfxPassword);
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

  Future<void> _share() async {
    final l10n = context.t.dashboard_forms;
    final customFields = await loadCustomShareableFields(
      ref,
      widget.certificateId,
    );
    if (!mounted) return;
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
          value: _privateKey,
          isSensitive: true,
        ),
        shareableField(
          id: 'pfx_password',
          label: l10n.pfx_password_label,
          value: _pfxPassword,
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
      backgroundColor: getScreenBackgroundColor(context, ref),
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
