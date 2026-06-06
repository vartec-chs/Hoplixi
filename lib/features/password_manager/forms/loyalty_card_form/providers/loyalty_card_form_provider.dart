import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/loyalty_card/loyalty_card_items.dart'
    show LoyaltyBarcodeType;
import 'package:hoplixi/vault_db/providers/providers.dart';

import '../models/loyalty_card_form_state.dart';

const _logTag = 'LoyaltyCardFormProvider';

final loyaltyCardFormProvider =
    NotifierProvider.autoDispose<LoyaltyCardFormNotifier, LoyaltyCardFormState>(
      LoyaltyCardFormNotifier.new,
    );

class LoyaltyCardFormNotifier extends Notifier<LoyaltyCardFormState> {
  @override
  LoyaltyCardFormState build() => const LoyaltyCardFormState();

  void initForCreate() {
    state = const LoyaltyCardFormState();
  }

  Future<void> initForEdit(String loyaltyCardId) async {
    state = state.copyWith(isLoading: true);

    try {
      final repositories = await ref.read(vaultRepositories.future);
      final relationsService = await ref.read(
        vaultItemRelationsServiceProvider.future,
      );
      final viewResult = await repositories.loyaltyCard.getViewById(
        loyaltyCardId,
      );

      final view = viewResult.getOrThrow().getOrNull();
      if (view == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final item = view.item;
      final loyalty = view.loyaltyCard;

      // Load tags
      final tagIdsResult = await relationsService.getTagIdsForItem(
        loyaltyCardId,
      );
      final tagIds = tagIdsResult.getOrThrow();
      final tagRecordsResult = await repositories.tag.getTagsByIds(tagIds);
      final tagRecords = tagRecordsResult.getOrThrow();

      final customFields = await loadCustomFields(ref, loyaltyCardId);

      // Load category name if exists
      String? categoryName;
      if (item.categoryId != null) {
        final catResult = await repositories.category.getCategory(
          item.categoryId!,
        );
        categoryName = catResult.getOrThrow().getOrNull()?.name;
      }

      state = LoyaltyCardFormState(
        isEditMode: true,
        editingLoyaltyCardId: loyaltyCardId,
        name: item.name,
        programName: loyalty.programName,
        cardNumber: loyalty.cardNumber ?? '',
        barcodeValue: loyalty.barcodeValue ?? '',
        password: loyalty.password ?? '',
        barcodeType: loyalty.barcodeType?.name,
        barcodeTypeOther: loyalty.barcodeTypeOther ?? '',
        issuer: loyalty.issuer ?? '',
        website: loyalty.website ?? '',
        phone: loyalty.phone ?? '',
        email: loyalty.email ?? '',
        validFrom: loyalty.validFrom?.toIso8601String() ?? '',
        validTo: loyalty.validTo?.toIso8601String() ?? '',
        description: item.description ?? '',
        categoryId: item.categoryId,
        categoryName: categoryName,
        tagIds: tagIds,
        tagNames: tagRecords.map((tag) => tag.name).toList(),
        customFields: customFields,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      logError(
        'Failed to load loyalty card for editing',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(isLoading: false);
    }
  }

  void setName(String value) {
    state = state.copyWith(name: value, nameError: _validateName(value));
  }

  void setProgramName(String value) {
    state = state.copyWith(
      programName: value,
      programNameError: _validateProgramName(value),
    );
  }

  void setCardNumber(String value) {
    state = state.copyWith(cardNumber: value, cardOrBarcodeError: null);
  }

  void setBarcodeValue(String value) =>
      state = state.copyWith(barcodeValue: value, cardOrBarcodeError: null);

  void setPassword(String value) => state = state.copyWith(password: value);

  void setBarcodeType(String? value) =>
      state = state.copyWith(barcodeType: value);

  void setBarcodeTypeOther(String value) =>
      state = state.copyWith(barcodeTypeOther: value);

  void setIssuer(String value) => state = state.copyWith(issuer: value);

  void setWebsite(String value) {
    state = state.copyWith(
      website: value,
      websiteError: _validateWebsite(value),
    );
  }

  void setPhone(String value) => state = state.copyWith(phone: value);

  void setEmail(String value) => state = state.copyWith(email: value);

  void setValidFrom(String value) {
    state = state.copyWith(
      validFrom: value,
      validFromError: _validateDate(value),
    );
  }

  void setValidTo(String value) {
    state = state.copyWith(validTo: value, validToError: _validateDate(value));
  }

  void setDescription(String value) =>
      state = state.copyWith(description: value);

  void setCategory(String? categoryId, String? categoryName) {
    state = state.copyWith(categoryId: categoryId, categoryName: categoryName);
  }

  void setTags(List<String> tagIds, List<String> tagNames) {
    state = state.copyWith(tagIds: tagIds, tagNames: tagNames);
  }

  void setCustomFields(List<CustomFieldEntry> fields) {
    state = state.copyWith(customFields: fields);
  }

  String? _validateName(String value) {
    if (value.trim().isEmpty) return 'Название обязательно';
    if (value.trim().length > 255) return 'Максимум 255 символов';
    return null;
  }

  String? _validateProgramName(String value) {
    if (value.trim().isEmpty) return 'Название программы обязательно';
    if (value.trim().length > 255) return 'Максимум 255 символов';
    return null;
  }

  String? _validateCardOrBarcode(String cardNumber, String barcodeValue) {
    if (cardNumber.trim().isEmpty && barcodeValue.trim().isEmpty) {
      return 'Укажите номер карты или штрихкод';
    }
    return null;
  }

  String? _validateDate(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized) == null
        ? 'Используйте формат YYYY-MM-DD'
        : null;
  }

  String? _validateWebsite(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    final uri = Uri.tryParse(normalized);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return 'Укажите корректный URL';
    }
    return null;
  }

  bool validateAll() {
    final nameError = _validateName(state.name);
    final programNameError = _validateProgramName(state.programName);
    final cardOrBarcodeError = _validateCardOrBarcode(
      state.cardNumber,
      state.barcodeValue,
    );
    final validFromError = _validateDate(state.validFrom);
    final validToError = _validateDate(state.validTo);
    final websiteError = _validateWebsite(state.website);

    state = state.copyWith(
      nameError: nameError,
      programNameError: programNameError,
      cardOrBarcodeError: cardOrBarcodeError,
      validFromError: validFromError,
      validToError: validToError,
      websiteError: websiteError,
    );

    return !state.hasErrors;
  }

  Future<bool> save() async {
    if (!validateAll()) {
      logWarning('Loyalty card form validation failed', tag: _logTag);
      return false;
    }

    state = state.copyWith(isSaving: true);

    try {
      final services = await ref.read(vaultEntityServices.future);

      DateTime? parseDate(String value) {
        final v = value.trim();
        if (v.isEmpty) return null;
        return DateTime.tryParse(v);
      }

      LoyaltyBarcodeType? parseBarcodeType(String? value) {
        if (value == null || value.isEmpty) return null;
        return LoyaltyBarcodeType.values.firstWhere(
          (e) => e.name == value,
          orElse: () => LoyaltyBarcodeType.other,
        );
      }

      String? clean(String v) => v.trim().isEmpty ? null : v.trim();

      if (state.isEditMode && state.editingLoyaltyCardId != null) {
        final res = await services.loyaltyCard.update(
          PatchLoyaltyCardDto(
            item: VaultItemPatchDto(
              itemId: state.editingLoyaltyCardId!,
              name: FieldUpdate.set(state.name.trim()),
              description: FieldUpdate.set(clean(state.description)),
              categoryId: FieldUpdate.set(state.categoryId),
            ),
            loyaltyCard: PatchLoyaltyCardDataDto(
              programName: FieldUpdate.set(state.programName.trim()),
              cardNumber: FieldUpdate.set(clean(state.cardNumber)),
              barcodeValue: FieldUpdate.set(clean(state.barcodeValue)),
              password: FieldUpdate.set(clean(state.password)),
              barcodeType: FieldUpdate.set(parseBarcodeType(state.barcodeType)),
              barcodeTypeOther: FieldUpdate.set(clean(state.barcodeTypeOther)),
              issuer: FieldUpdate.set(clean(state.issuer)),
              website: FieldUpdate.set(clean(state.website)),
              phone: FieldUpdate.set(clean(state.phone)),
              email: FieldUpdate.set(clean(state.email)),
              validFrom: FieldUpdate.set(parseDate(state.validFrom)),
              validTo: FieldUpdate.set(parseDate(state.validTo)),
            ),
            tags: FieldUpdate.set(state.tagIds),
          ),
        );

        res.getOrThrow();

        await saveCustomFields(
          ref,
          state.editingLoyaltyCardId!,
          state.customFields,
        );

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.loyaltyCard,
              entityId: state.editingLoyaltyCardId,
            );
      } else {
        final res = await services.loyaltyCard.create(
          CreateLoyaltyCardDto(
            item: VaultItemCreateDto(
              name: state.name.trim(),
              description: clean(state.description),
              categoryId: state.categoryId,
            ),
            loyaltyCard: LoyaltyCardDataDto(
              programName: state.programName.trim(),
              cardNumber: clean(state.cardNumber),
              barcodeValue: clean(state.barcodeValue),
              password: clean(state.password),
              barcodeType: parseBarcodeType(state.barcodeType),
              barcodeTypeOther: clean(state.barcodeTypeOther),
              issuer: clean(state.issuer),
              website: clean(state.website),
              phone: clean(state.phone),
              email: clean(state.email),
              validFrom: parseDate(state.validFrom),
              validTo: parseDate(state.validTo),
            ),
            tagIds: state.tagIds,
          ),
        );

        final loyaltyCardId = res.getOrThrow();
        await saveCustomFields(ref, loyaltyCardId, state.customFields);

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityAdd(EntityType.loyaltyCard, entityId: loyaltyCardId);
      }

      state = state.copyWith(isSaving: false, isSaved: true);
      return true;
    } catch (e, stackTrace) {
      logError(
        'Failed to save loyalty card',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  void resetSaved() {
    state = state.copyWith(isSaved: false);
  }
}
