import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class CertificateFormScreen extends ConsumerStatefulWidget {
  const CertificateFormScreen({super.key, this.certificateId});

  final String? certificateId;

  bool get isEdit => certificateId != null;

  @override
  ConsumerState<CertificateFormScreen> createState() =>
      _CertificateFormScreenState();
}

class _CertificateFormScreenState extends ConsumerState<CertificateFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _certificatePemController = TextEditingController();
  final _privateKeyController = TextEditingController();
  final _serialController = TextEditingController();
  final _issuerController = TextEditingController();
  final _subjectController = TextEditingController();
  final _fingerprintController = TextEditingController();
  final _ocspController = TextEditingController();
  final _crlController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _autoRenew = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final dao = await ref.read(certificateDaoProvider.future);
      final row = await dao.getById(widget.certificateId!);
      if (row == null) return;
      final item = row.$1;
      final cert = row.$2;
      _nameController.text = item.name;
      _certificatePemController.text = cert.certificatePem;
      _privateKeyController.text = cert.privateKey ?? '';
      _serialController.text = cert.serialNumber ?? '';
      _issuerController.text = cert.issuer ?? '';
      _subjectController.text = cert.subject ?? '';
      _fingerprintController.text = cert.fingerprint ?? '';
      _ocspController.text = cert.ocspUrl ?? '';
      _crlController.text = cert.crlUrl ?? '';
      _descriptionController.text = item.description ?? '';
      _autoRenew = cert.autoRenew;
    } catch (e) {
      Toaster.error(title: 'Ошибка загрузки', description: '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _certificatePemController.dispose();
    _privateKeyController.dispose();
    _serialController.dispose();
    _issuerController.dispose();
    _subjectController.dispose();
    _fingerprintController.dispose();
    _ocspController.dispose();
    _crlController.dispose();
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
      final dao = await ref.read(certificateDaoProvider.future);

      final name = _nameController.text.trim();
      final certificatePem = _certificatePemController.text.trim();
      final privateKey = _privateKeyController.text.trim();
      final serial = _serialController.text.trim();
      final issuer = _issuerController.text.trim();
      final subject = _subjectController.text.trim();
      final fingerprint = _fingerprintController.text.trim();
      final ocsp = _ocspController.text.trim();
      final crl = _crlController.text.trim();
      final description = _descriptionController.text.trim();

      if (widget.isEdit) {
        await dao.updateCertificate(
          widget.certificateId!,
          UpdateCertificateDto(
            name: name,
            certificatePem: certificatePem,
            privateKey: privateKey.isEmpty ? null : privateKey,
            serialNumber: serial.isEmpty ? null : serial,
            issuer: issuer.isEmpty ? null : issuer,
            subject: subject.isEmpty ? null : subject,
            fingerprint: fingerprint.isEmpty ? null : fingerprint,
            ocspUrl: ocsp.isEmpty ? null : ocsp,
            crlUrl: crl.isEmpty ? null : crl,
            description: description.isEmpty ? null : description,
            autoRenew: _autoRenew,
          ),
        );
      } else {
        await dao.createCertificate(
          CreateCertificateDto(
            name: name,
            certificatePem: certificatePem,
            privateKey: privateKey.isEmpty ? null : privateKey,
            serialNumber: serial.isEmpty ? null : serial,
            issuer: issuer.isEmpty ? null : issuer,
            subject: subject.isEmpty ? null : subject,
            fingerprint: fingerprint.isEmpty ? null : fingerprint,
            ocspUrl: ocsp.isEmpty ? null : ocsp,
            crlUrl: crl.isEmpty ? null : crl,
            description: description.isEmpty ? null : description,
            autoRenew: _autoRenew,
          ),
        );
      }

      Toaster.success(
        title: widget.isEdit ? 'Сертификат обновлен' : 'Сертификат создан',
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
          widget.isEdit ? 'Редактировать сертификат' : 'Новый сертификат',
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
                    controller: _certificatePemController,
                    decoration: const InputDecoration(
                      labelText: 'Certificate PEM',
                    ),
                    minLines: 3,
                    maxLines: 8,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Certificate PEM обязателен'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _privateKeyController,
                    decoration: const InputDecoration(labelText: 'Private key'),
                    minLines: 2,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _serialController,
                    decoration: const InputDecoration(
                      labelText: 'Serial number',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _issuerController,
                    decoration: const InputDecoration(labelText: 'Issuer'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(labelText: 'Subject'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fingerprintController,
                    decoration: const InputDecoration(labelText: 'Fingerprint'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ocspController,
                    decoration: const InputDecoration(labelText: 'OCSP URL'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _crlController,
                    decoration: const InputDecoration(labelText: 'CRL URL'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Описание'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  SwitchListTile(
                    value: _autoRenew,
                    onChanged: (v) => setState(() => _autoRenew = v),
                    title: const Text('Auto-renew'),
                  ),
                ],
              ),
            ),
    );
  }
}
