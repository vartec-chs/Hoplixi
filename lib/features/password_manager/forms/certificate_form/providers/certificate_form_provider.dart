import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';
import 'package:hoplixi/vault_db/providers/service_providers.dart';

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

    final repositories = await ref.read(vaultRepositories.future);
    final relationsService = await ref.read(
      vaultItemRelationsServiceProvider.future,
    );
    final viewResult = await repositories.certificate.getViewById(id);

    final view = viewResult.getOrThrow().getOrNull();
    if (view == null) return const CertificateFormState(isEditMode: false);

    final item = view.item;
    final cert = view.certificate;

    // Load tags
    final tagIdsResult = await relationsService.getTagIdsForItem(id);
    final tagIds = tagIdsResult.getOrThrow();
    final tagsResult = await repositories.tag.getTagsByIds(tagIds);
    final tags = tagsResult.getOrThrow();
    final tagNames = tags.map((t) => t.name).toList();

    // Load category name if exists
    String? categoryName;
    if (item.categoryId != null) {
      final catResult = await repositories.category.getCategory(
        item.categoryId!,
      );
      categoryName = catResult.getOrThrow().getOrNull()?.name;
    }

    final customFields = await loadCustomFields(ref, id);

    return CertificateFormState(
      isEditMode: true,
      editingCertificateId: id,
      name: item.name,
      certificatePem: cert.certificatePem ?? '',
      privateKey: cert.privateKey ?? '',
      serialNumber: cert.serialNumber ?? '',
      issuer: cert.issuer ?? '',
      subject: cert.subject ?? '',
      description: item.description ?? '',
      categoryId: item.categoryId,
      categoryName: categoryName,
      tagIds: tagIds,
      tagNames: tagNames,
      customFields: customFields,
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
      nameError: v.trim().isEmpty
          ? t.dashboard_forms.validation_required_name
          : null,
    ),
  );
  void setCertificatePem(String v) => _update(
    (s) => s.copyWith(
      certificatePem: v,
      certificatePemError: v.trim().isEmpty
          ? t.dashboard_forms.validation_required_certificate_pem
          : null,
    ),
  );
  void setPrivateKey(String v) => _update((s) => s.copyWith(privateKey: v));
  void setSerialNumber(String v) => _update((s) => s.copyWith(serialNumber: v));
  void setIssuer(String v) => _update((s) => s.copyWith(issuer: v));
  void setSubject(String v) => _update((s) => s.copyWith(subject: v));
  void setDescription(String v) => _update((s) => s.copyWith(description: v));
  void setNote(String? id, String? name) =>
      _update((s) => s.copyWith(noteId: id, noteName: name));
  void setCategory(String? id, String? name) =>
      _update((s) => s.copyWith(categoryId: id, categoryName: name));
  void setTags(List<String> ids, List<String> names) =>
      _update((s) => s.copyWith(tagIds: ids, tagNames: names));

  void setCustomFields(List<CustomFieldEntry> fields) {
    _update((s) => s.copyWith(customFields: fields));
  }

  bool validate() {
    final c = _current;
    final nameError = c.name.trim().isEmpty
        ? t.dashboard_forms.validation_required_name
        : null;
    final certificatePemError = c.certificatePem.trim().isEmpty
        ? t.dashboard_forms.validation_required_certificate_pem
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
      final services = await ref.read(vaultEntityServices.future);

      if (c.isEditMode && c.editingCertificateId != null) {
        final res = await services.certificate.update(
          PatchCertificateDto(
            item: VaultItemPatchDto(
              itemId: c.editingCertificateId!,
              name: FieldUpdate.set(c.name.trim()),
              description: FieldUpdate.set(clean(c.description)),
              categoryId: FieldUpdate.set(c.categoryId),
            ),
            certificate: PatchCertificateDataDto(
              certificatePem: FieldUpdate.set(c.certificatePem.trim()),
              privateKey: FieldUpdate.set(clean(c.privateKey)),
              serialNumber: FieldUpdate.set(clean(c.serialNumber)),
              issuer: FieldUpdate.set(clean(c.issuer)),
              subject: FieldUpdate.set(clean(c.subject)),
            ),
            tags: FieldUpdate.set(c.tagIds),
          ),
        );

        res.getOrThrow();

        await saveCustomFields(ref, c.editingCertificateId!, c.customFields);

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.certificate,
              entityId: c.editingCertificateId,
            );
      } else {
        final res = await services.certificate.create(
          CreateCertificateDto(
            item: VaultItemCreateDto(
              name: c.name.trim(),
              description: clean(c.description),
              categoryId: c.categoryId,
            ),
            certificate: CertificateDataDto(
              certificatePem: c.certificatePem.trim(),
              privateKey: clean(c.privateKey),
              serialNumber: clean(c.serialNumber),
              issuer: clean(c.issuer),
              subject: clean(c.subject),
            ),
            tagIds: c.tagIds,
          ),
        );

        final id = res.getOrThrow();

        await saveCustomFields(ref, id, c.customFields);
        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityAdd(EntityType.certificate, entityId: id);
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

