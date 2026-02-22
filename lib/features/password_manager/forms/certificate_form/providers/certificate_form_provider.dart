import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

import '../models/certificate_form_state.dart';

final certificateFormProvider = AsyncNotifierProvider.autoDispose
    .family<CertificateFormNotifier, CertificateFormState, String?>(
      CertificateFormNotifier.new,
    );

class CertificateFormNotifier extends AsyncNotifier<CertificateFormState> {
  CertificateFormNotifier(this.certificateId);

  final String? certificateId;

  @override
  Future<CertificateFormState> build() async {
    if (certificateId == null) {
      return const CertificateFormState(isEditMode: false);
    }
    final id = certificateId!;

    final dao = await ref.read(certificateDaoProvider.future);
    final row = await dao.getById(id);
    if (row == null) return const CertificateFormState(isEditMode: false);

    final item = row.$1;
    final cert = row.$2;

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    final tagIds = await vaultItemDao.getTagIds(id);
    final tagDao = await ref.read(tagDaoProvider.future);
    final tags = await tagDao.getTagsByIds(tagIds);

    return CertificateFormState(
      isEditMode: true,
      editingCertificateId: id,
      name: item.name,
      certificatePem: cert.certificatePem,
      privateKey: cert.privateKey ?? '',
      serialNumber: cert.serialNumber ?? '',
      issuer: cert.issuer ?? '',
      subject: cert.subject ?? '',
      fingerprint: cert.fingerprint ?? '',
      ocspUrl: cert.ocspUrl ?? '',
      crlUrl: cert.crlUrl ?? '',
      description: item.description ?? '',
      autoRenew: cert.autoRenew,
      noteId: item.noteId,
      categoryId: item.categoryId,
      tagIds: tagIds,
      tagNames: tags.map((t) => t.name).toList(),
    );
  }

  CertificateFormState get _current =>
      state.value ?? const CertificateFormState();

  void _update(CertificateFormState Function(CertificateFormState v) cb) {
    state = AsyncData(cb(_current));
  }

  void setName(String v) => _update(
    (s) => s.copyWith(
      name: v,
      nameError: v.trim().isEmpty ? 'Название обязательно' : null,
    ),
  );
  void setCertificatePem(String v) => _update(
    (s) => s.copyWith(
      certificatePem: v,
      certificatePemError: v.trim().isEmpty
          ? 'Certificate PEM обязателен'
          : null,
    ),
  );
  void setPrivateKey(String v) => _update((s) => s.copyWith(privateKey: v));
  void setSerialNumber(String v) => _update((s) => s.copyWith(serialNumber: v));
  void setIssuer(String v) => _update((s) => s.copyWith(issuer: v));
  void setSubject(String v) => _update((s) => s.copyWith(subject: v));
  void setFingerprint(String v) => _update((s) => s.copyWith(fingerprint: v));
  void setOcspUrl(String v) => _update((s) => s.copyWith(ocspUrl: v));
  void setCrlUrl(String v) => _update((s) => s.copyWith(crlUrl: v));
  void setDescription(String v) => _update((s) => s.copyWith(description: v));
  void setAutoRenew(bool v) => _update((s) => s.copyWith(autoRenew: v));
  void setNote(String? id, String? name) =>
      _update((s) => s.copyWith(noteId: id, noteName: name));
  void setCategory(String? id, String? name) =>
      _update((s) => s.copyWith(categoryId: id, categoryName: name));
  void setTags(List<String> ids, List<String> names) =>
      _update((s) => s.copyWith(tagIds: ids, tagNames: names));

  bool validate() {
    final c = _current;
    final nameError = c.name.trim().isEmpty ? 'Название обязательно' : null;
    final certificatePemError = c.certificatePem.trim().isEmpty
        ? 'Certificate PEM обязателен'
        : null;

    _update(
      (s) => s.copyWith(
        nameError: nameError,
        certificatePemError: certificatePemError,
      ),
    );
    return nameError == null && certificatePemError == null;
  }

  Future<bool> save() async {
    if (!validate()) return false;

    final c = _current;
    _update((s) => s.copyWith(isSaving: true));

    String? clean(String value) {
      final v = value.trim();
      return v.isEmpty ? null : v;
    }

    try {
      final dao = await ref.read(certificateDaoProvider.future);

      if (c.isEditMode && c.editingCertificateId != null) {
        final updated = await dao.updateCertificate(
          c.editingCertificateId!,
          UpdateCertificateDto(
            name: c.name.trim(),
            certificatePem: c.certificatePem.trim(),
            privateKey: clean(c.privateKey),
            serialNumber: clean(c.serialNumber),
            issuer: clean(c.issuer),
            subject: clean(c.subject),
            fingerprint: clean(c.fingerprint),
            ocspUrl: clean(c.ocspUrl),
            crlUrl: clean(c.crlUrl),
            description: clean(c.description),
            autoRenew: c.autoRenew,
            noteId: c.noteId,
            categoryId: c.categoryId,
            tagsIds: c.tagIds,
          ),
        );

        if (!updated) {
          _update((s) => s.copyWith(isSaving: false));
          return false;
        }
      } else {
        await dao.createCertificate(
          CreateCertificateDto(
            name: c.name.trim(),
            certificatePem: c.certificatePem.trim(),
            privateKey: clean(c.privateKey),
            serialNumber: clean(c.serialNumber),
            issuer: clean(c.issuer),
            subject: clean(c.subject),
            fingerprint: clean(c.fingerprint),
            ocspUrl: clean(c.ocspUrl),
            crlUrl: clean(c.crlUrl),
            description: clean(c.description),
            autoRenew: c.autoRenew,
            noteId: c.noteId,
            categoryId: c.categoryId,
            tagsIds: c.tagIds,
          ),
        );
      }

      _update((s) => s.copyWith(isSaving: false, isSaved: true));
      return true;
    } catch (_) {
      _update((s) => s.copyWith(isSaving: false));
      return false;
    }
  }

  void resetSaved() => _update((s) => s.copyWith(isSaved: false));
}
