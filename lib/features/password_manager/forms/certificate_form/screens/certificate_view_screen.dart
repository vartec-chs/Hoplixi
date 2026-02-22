import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
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
        Toaster.error(title: 'Сертификат не найден');
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
      Toaster.error(title: 'Ошибка загрузки', description: '$e');
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
        Toaster.warning(title: 'Private key отсутствует');
        return;
      }
      setState(() {
        _privateKey = value;
        _showPrivateKey = true;
      });
    } catch (e) {
      Toaster.error(title: 'Ошибка получения private key', description: '$e');
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
        Toaster.warning(title: 'Пароль PFX отсутствует');
        return;
      }
      setState(() {
        _pfxPassword = value;
        _showPfxPassword = true;
      });
    } catch (e) {
      Toaster.error(title: 'Ошибка получения пароля PFX', description: '$e');
    }
  }

  Future<void> _copyText(String title, String? value) async {
    if (value == null || value.isEmpty) {
      Toaster.warning(title: '$title пуст');
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    Toaster.success(title: '$title скопирован');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Просмотр сертификата'),
        actions: [
          IconButton(
            tooltip: 'Редактировать',
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
                  title: const Text('Certificate PEM'),
                  subtitle: SelectableText(_certificatePem),
                  trailing: IconButton(
                    onPressed: () =>
                        _copyText('Certificate PEM', _certificatePem),
                    icon: const Icon(Icons.copy),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Private key'),
                  subtitle: SelectableText(
                    _showPrivateKey
                        ? (_privateKey ?? '')
                        : 'Нажмите кнопку видимости для загрузки',
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
                        onPressed: () => _copyText('Private key', _privateKey),
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('PFX password'),
                  subtitle: Text(
                    _showPfxPassword
                        ? (_pfxPassword ?? '')
                        : 'Нажмите кнопку видимости для загрузки',
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
                            _copyText('PFX password', _pfxPassword),
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
                ),
                if (_issuer?.isNotEmpty == true)
                  ListTile(
                    title: const Text('Issuer'),
                    subtitle: Text(_issuer!),
                  ),
                if (_subject?.isNotEmpty == true)
                  ListTile(
                    title: const Text('Subject'),
                    subtitle: Text(_subject!),
                  ),
                if (_serialNumber?.isNotEmpty == true)
                  ListTile(
                    title: const Text('Serial number'),
                    subtitle: Text(_serialNumber!),
                  ),
                if (_fingerprint?.isNotEmpty == true)
                  ListTile(
                    title: const Text('Fingerprint'),
                    subtitle: Text(_fingerprint!),
                  ),
                if (_ocspUrl?.isNotEmpty == true)
                  ListTile(
                    title: const Text('OCSP URL'),
                    subtitle: Text(_ocspUrl!),
                  ),
                if (_crlUrl?.isNotEmpty == true)
                  ListTile(
                    title: const Text('CRL URL'),
                    subtitle: Text(_crlUrl!),
                  ),
                ListTile(
                  title: const Text('Auto-renew'),
                  subtitle: Text(_autoRenew ? 'Включен' : 'Выключен'),
                ),
                if (_description?.isNotEmpty == true)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Описание'),
                    subtitle: Text(_description!),
                  ),
              ],
            ),
    );
  }
}
