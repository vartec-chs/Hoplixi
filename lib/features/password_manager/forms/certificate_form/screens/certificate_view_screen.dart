import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/generated/l10n.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
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
        Toaster.error(title: S.of(context).certificateNotFound);
        if (mounted) context.pop();
        return;
      }
      final item = row.$1;
      final cert = row.$2;
      setState(() {
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
      Toaster.error(title: S.of(context).commonLoadError, description: '$e');
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
          title: S.of(context).commonFieldMissing(S.of(context).pfxPasswordLabel),
        );
        return;
      }
      setState(() {
        _pfxPassword = value;
        _showPfxPassword = true;
      });
    } catch (e) {
      Toaster.error(
        title: S.of(context).commonErrorGettingField(S.of(context).pfxPasswordLabel),
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
        title: Text(l10n.viewCertificate),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            onPressed: () => context.push(
              AppRoutesPaths.dashboardEntityEdit(
                EntityType.certificate,
                widget.certificateId,
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
                  title: Text(l10n.certificatePemLabel),
                  subtitle: SelectableText(_certificatePem),
                  trailing: IconButton(
                    onPressed: () =>
                        _copyText(l10n.certificatePemLabel, _certificatePem),
                    icon: const Icon(Icons.copy),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.privateKeyLabel),
                  subtitle: SelectableText(
                    _showPrivateKey
                        ? (_privateKey ?? '')
                        : l10n.commonPressVisibilityToLoad,
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        onPressed: _revealPrivateKey,
                        icon: Icon(
                          _showPrivateKey ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _copyText(l10n.privateKeyLabel, _privateKey),
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.pfxPasswordLabel),
                  subtitle: Text(
                    _showPfxPassword
                        ? (_pfxPassword ?? '')
                        : l10n.commonPressVisibilityToLoad,
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        onPressed: _revealPfxPassword,
                        icon: Icon(
                          _showPfxPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _copyText(l10n.pfxPasswordLabel, _pfxPassword),
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
                ),
                if (_issuer?.isNotEmpty == true)
                  ListTile(title: Text(l10n.issuerLabel), subtitle: Text(_issuer!)),
                if (_subject?.isNotEmpty == true)
                  ListTile(title: Text(l10n.subjectLabel), subtitle: Text(_subject!)),
                if (_serialNumber?.isNotEmpty == true)
                  ListTile(
                    title: Text(l10n.serialNumberLabel),
                    subtitle: Text(_serialNumber!),
                  ),
                if (_fingerprint?.isNotEmpty == true)
                  ListTile(
                    title: Text(l10n.fingerprintLabel),
                    subtitle: Text(_fingerprint!),
                  ),
                if (_ocspUrl?.isNotEmpty == true)
                  ListTile(title: Text(l10n.ocspUrlLabel), subtitle: Text(_ocspUrl!)),
                if (_crlUrl?.isNotEmpty == true)
                  ListTile(title: Text(l10n.crlUrlLabel), subtitle: Text(_crlUrl!)),
                ListTile(
                  title: Text(l10n.autoRenewLabel),
                  subtitle:
                      Text(_autoRenew ? l10n.commonEnabled : l10n.commonDisabled),
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
