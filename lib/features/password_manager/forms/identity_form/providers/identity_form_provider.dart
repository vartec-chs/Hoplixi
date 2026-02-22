import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

import '../models/identity_form_state.dart';

final identityFormProvider = AsyncNotifierProvider.autoDispose
    .family<IdentityFormNotifier, IdentityFormState, String?>(
      IdentityFormNotifier.new,
    );

class IdentityFormNotifier extends AsyncNotifier<IdentityFormState> {
  IdentityFormNotifier(this.identityId);

  final String? identityId;

  @override
  Future<IdentityFormState> build() async {
    if (identityId == null) return const IdentityFormState(isEditMode: false);
    final id = identityId!;

    final dao = await ref.read(identityDaoProvider.future);
    final row = await dao.getById(id);
    if (row == null) return const IdentityFormState(isEditMode: false);

    final item = row.$1;
    final identity = row.$2;

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    final tagIds = await vaultItemDao.getTagIds(id);
    final tagDao = await ref.read(tagDaoProvider.future);
    final tags = await tagDao.getTagsByIds(tagIds);

    return IdentityFormState(
      isEditMode: true,
      editingIdentityId: id,
      name: item.name,
      idType: identity.idType,
      idNumber: identity.idNumber,
      fullName: identity.fullName ?? '',
      dateOfBirth: identity.dateOfBirth?.toIso8601String() ?? '',
      placeOfBirth: identity.placeOfBirth ?? '',
      nationality: identity.nationality ?? '',
      issuingAuthority: identity.issuingAuthority ?? '',
      issueDate: identity.issueDate?.toIso8601String() ?? '',
      expiryDate: identity.expiryDate?.toIso8601String() ?? '',
      mrz: identity.mrz ?? '',
      scanAttachmentId: identity.scanAttachmentId ?? '',
      photoAttachmentId: identity.photoAttachmentId ?? '',
      notes: identity.notes ?? '',
      description: item.description ?? '',
      verified: identity.verified,
      noteId: item.noteId,
      categoryId: item.categoryId,
      tagIds: tagIds,
      tagNames: tags.map((t) => t.name).toList(),
    );
  }

  IdentityFormState get _current => state.value ?? const IdentityFormState();

  void _update(IdentityFormState Function(IdentityFormState value) cb) {
    state = AsyncData(cb(_current));
  }

  String? _req(String v, String m) => v.trim().isEmpty ? m : null;
  String? _dateErr(String v) {
    final s = v.trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s) == null ? 'Неверный ISO8601' : null;
  }

  void setName(String v) => _update(
    (s) => s.copyWith(name: v, nameError: _req(v, 'Название обязательно')),
  );
  void setIdType(String v) => _update(
    (s) => s.copyWith(idType: v, idTypeError: _req(v, 'Тип обязателен')),
  );
  void setIdNumber(String v) => _update(
    (s) => s.copyWith(idNumber: v, idNumberError: _req(v, 'Номер обязателен')),
  );
  void setFullName(String v) => _update((s) => s.copyWith(fullName: v));
  void setDateOfBirth(String v) =>
      _update((s) => s.copyWith(dateOfBirth: v, dateOfBirthError: _dateErr(v)));
  void setPlaceOfBirth(String v) => _update((s) => s.copyWith(placeOfBirth: v));
  void setNationality(String v) => _update((s) => s.copyWith(nationality: v));
  void setIssuingAuthority(String v) =>
      _update((s) => s.copyWith(issuingAuthority: v));
  void setIssueDate(String v) =>
      _update((s) => s.copyWith(issueDate: v, issueDateError: _dateErr(v)));
  void setExpiryDate(String v) =>
      _update((s) => s.copyWith(expiryDate: v, expiryDateError: _dateErr(v)));
  void setMrz(String v) => _update((s) => s.copyWith(mrz: v));
  void setScanAttachmentId(String v) =>
      _update((s) => s.copyWith(scanAttachmentId: v));
  void setPhotoAttachmentId(String v) =>
      _update((s) => s.copyWith(photoAttachmentId: v));
  void setNotes(String v) => _update((s) => s.copyWith(notes: v));
  void setDescription(String v) => _update((s) => s.copyWith(description: v));
  void setVerified(bool v) => _update((s) => s.copyWith(verified: v));
  void setNote(String? id, String? name) =>
      _update((s) => s.copyWith(noteId: id, noteName: name));
  void setCategory(String? id, String? name) =>
      _update((s) => s.copyWith(categoryId: id, categoryName: name));
  void setTags(List<String> ids, List<String> names) =>
      _update((s) => s.copyWith(tagIds: ids, tagNames: names));

  bool validate() {
    final c = _current;
    final nameError = _req(c.name, 'Название обязательно');
    final idTypeError = _req(c.idType, 'Тип обязателен');
    final idNumberError = _req(c.idNumber, 'Номер обязателен');
    final dateOfBirthError = _dateErr(c.dateOfBirth);
    final issueDateError = _dateErr(c.issueDate);
    final expiryDateError = _dateErr(c.expiryDate);

    _update(
      (s) => s.copyWith(
        nameError: nameError,
        idTypeError: idTypeError,
        idNumberError: idNumberError,
        dateOfBirthError: dateOfBirthError,
        issueDateError: issueDateError,
        expiryDateError: expiryDateError,
      ),
    );

    return nameError == null &&
        idTypeError == null &&
        idNumberError == null &&
        dateOfBirthError == null &&
        issueDateError == null &&
        expiryDateError == null;
  }

  Future<bool> save() async {
    if (!validate()) return false;

    final c = _current;
    _update((s) => s.copyWith(isSaving: true));

    String? clean(String value) {
      final v = value.trim();
      return v.isEmpty ? null : v;
    }

    DateTime? parseDate(String value) {
      final v = value.trim();
      if (v.isEmpty) return null;
      return DateTime.tryParse(v);
    }

    try {
      final dao = await ref.read(identityDaoProvider.future);

      if (c.isEditMode && c.editingIdentityId != null) {
        final updated = await dao.updateIdentity(
          c.editingIdentityId!,
          UpdateIdentityDto(
            name: c.name.trim(),
            idType: c.idType.trim(),
            idNumber: c.idNumber.trim(),
            fullName: clean(c.fullName),
            dateOfBirth: parseDate(c.dateOfBirth),
            placeOfBirth: clean(c.placeOfBirth),
            nationality: clean(c.nationality),
            issuingAuthority: clean(c.issuingAuthority),
            issueDate: parseDate(c.issueDate),
            expiryDate: parseDate(c.expiryDate),
            mrz: clean(c.mrz),
            scanAttachmentId: clean(c.scanAttachmentId),
            photoAttachmentId: clean(c.photoAttachmentId),
            notes: clean(c.notes),
            verified: c.verified,
            description: clean(c.description),
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
        await dao.createIdentity(
          CreateIdentityDto(
            name: c.name.trim(),
            idType: c.idType.trim(),
            idNumber: c.idNumber.trim(),
            fullName: clean(c.fullName),
            dateOfBirth: parseDate(c.dateOfBirth),
            placeOfBirth: clean(c.placeOfBirth),
            nationality: clean(c.nationality),
            issuingAuthority: clean(c.issuingAuthority),
            issueDate: parseDate(c.issueDate),
            expiryDate: parseDate(c.expiryDate),
            mrz: clean(c.mrz),
            scanAttachmentId: clean(c.scanAttachmentId),
            photoAttachmentId: clean(c.photoAttachmentId),
            notes: clean(c.notes),
            verified: c.verified,
            description: clean(c.description),
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
