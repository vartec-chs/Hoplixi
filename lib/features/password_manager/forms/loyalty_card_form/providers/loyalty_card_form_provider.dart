import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/main_db/core/old/models/dto/icon_ref_dto.dart';
import 'package:hoplixi/main_db/core/old/models/dto/loyalty_card_dto.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';

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
      final dao = await ref.read(loyaltyCardDaoProvider.future);
      final record = await dao.getById(loyaltyCardId);
      if (record == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final (vault, loyalty) = record;
      final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
      final tagIds = await vaultItemDao.getTagIds(loyaltyCardId);
      final tagDao = await ref.read(tagDaoProvider.future);
      final tagRecords = await tagDao.getTagsByIds(tagIds);
      final customFields = await loadCustomFields(ref, loyaltyCardId);
      String? categoryName;
      if (vault.categoryId != null) {
        final categoryDao = await ref.read(categoryDaoProvider.future);
        final category = await categoryDao.getCategoryById(vault.categoryId!);
        categoryName = category?.name;
      }

      state = LoyaltyCardFormState(
        isEditMode: true,
        editingLoyaltyCardId: loyaltyCardId,
        name: vault.name,
        programName: loyalty.programName,
        cardNumber: loyalty.cardNumber ?? '',
        holderName: loyalty.holderName ?? '',
        password: loyalty.password ?? '',
        barcodeValue: loyalty.barcodeValue ?? '',
        barcodeType: loyalty.barcodeType ?? '',
        pointsBalance: loyalty.pointsBalance ?? '',
        tier: loyalty.tier ?? '',
        expiryDate: loyalty.expiryDate?.toIso8601String() ?? '',
        website: loyalty.website ?? '',
        phoneNumber: loyalty.phoneNumber ?? '',
        description: vault.description ?? '',
        noteId: vault.noteId,
        categoryId: vault.categoryId,
        categoryName: categoryName,
        iconSource: vault.iconSource,
        iconValue: vault.iconValue,
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

  void setHolderName(String value) => state = state.copyWith(holderName: value);

  void setPassword(String value) => state = state.copyWith(password: value);

  void setBarcodeValue(String value) =>
      state = state.copyWith(barcodeValue: value, cardOrBarcodeError: null);

  void setBarcodeType(String value) =>
      state = state.copyWith(barcodeType: value);

  void setPointsBalance(String value) =>
      state = state.copyWith(pointsBalance: value);

  void setTier(String value) => state = state.copyWith(tier: value);

  void setExpiryDate(String value) {
    state = state.copyWith(
      expiryDate: value,
      expiryDateError: _validateExpiryDate(value),
    );
  }

  void setWebsite(String value) {
    state = state.copyWith(
      website: value,
      websiteError: _validateWebsite(value),
    );
  }

  void setPhoneNumber(String value) =>
      state = state.copyWith(phoneNumber: value);

  void setDescription(String value) =>
      state = state.copyWith(description: value);

  void setNoteId(String? value) => state = state.copyWith(noteId: value);

  void setCategory(String? categoryId, String? categoryName) {
    state = state.copyWith(categoryId: categoryId, categoryName: categoryName);
  }

  void setIconRef(IconRefDto? iconRef) {
    state = state.copyWith(
      iconSource: iconRef?.sourceValue,
      iconValue: iconRef?.value,
    );
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

  String? _validateExpiryDate(String value) {
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
    final expiryDateError = _validateExpiryDate(state.expiryDate);
    final websiteError = _validateWebsite(state.website);

    state = state.copyWith(
      nameError: nameError,
      programNameError: programNameError,
      cardOrBarcodeError: cardOrBarcodeError,
      expiryDateError: expiryDateError,
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
      final dao = await ref.read(loyaltyCardDaoProvider.future);
      final expiryDate = state.expiryDate.trim().isEmpty
          ? null
          : DateTime.tryParse(state.expiryDate.trim());

      if (state.isEditMode && state.editingLoyaltyCardId != null) {
        final dto = UpdateLoyaltyCardDto(
          name: state.name.trim(),
          programName: state.programName.trim(),
          cardNumber: state.cardNumber.trim().isEmpty
              ? null
              : state.cardNumber.trim(),
          holderName: state.holderName.trim().isEmpty
              ? null
              : state.holderName.trim(),
          barcodeValue: state.barcodeValue.trim().isEmpty
              ? null
              : state.barcodeValue.trim(),
          barcodeType: state.barcodeType.trim().isEmpty
              ? null
              : state.barcodeType.trim(),
          password: state.password.trim().isEmpty
              ? null
              : state.password.trim(),
          pointsBalance: state.pointsBalance.trim().isEmpty
              ? null
              : state.pointsBalance.trim(),
          tier: state.tier.trim().isEmpty ? null : state.tier.trim(),
          expiryDate: expiryDate,
          website: state.website.trim().isEmpty ? null : state.website.trim(),
          phoneNumber: state.phoneNumber.trim().isEmpty
              ? null
              : state.phoneNumber.trim(),
          description: state.description.trim().isEmpty
              ? null
              : state.description.trim(),
          noteId: state.noteId,
          categoryId: state.categoryId,
          tagsIds: state.tagIds,
        );

        final success = await dao.updateLoyaltyCard(
          state.editingLoyaltyCardId!,
          dto,
        );
        if (!success) {
          state = state.copyWith(isSaving: false);
          return false;
        }

        await saveCustomFields(
          ref,
          state.editingLoyaltyCardId!,
          state.customFields,
        );
        final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
        await vaultItemDao.setIconRef(
          state.editingLoyaltyCardId!,
          IconRefDto.fromFields(
            iconSource: state.iconSource,
            iconValue: state.iconValue,
          ),
        );

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.loyaltyCard,
              entityId: state.editingLoyaltyCardId,
            );
      } else {
        final dto = CreateLoyaltyCardDto(
          name: state.name.trim(),
          programName: state.programName.trim(),
          cardNumber: state.cardNumber.trim().isEmpty
              ? null
              : state.cardNumber.trim(),
          holderName: state.holderName.trim().isEmpty
              ? null
              : state.holderName.trim(),
          barcodeValue: state.barcodeValue.trim().isEmpty
              ? null
              : state.barcodeValue.trim(),
          barcodeType: state.barcodeType.trim().isEmpty
              ? null
              : state.barcodeType.trim(),
          password: state.password.trim().isEmpty
              ? null
              : state.password.trim(),
          pointsBalance: state.pointsBalance.trim().isEmpty
              ? null
              : state.pointsBalance.trim(),
          tier: state.tier.trim().isEmpty ? null : state.tier.trim(),
          expiryDate: expiryDate,
          website: state.website.trim().isEmpty ? null : state.website.trim(),
          phoneNumber: state.phoneNumber.trim().isEmpty
              ? null
              : state.phoneNumber.trim(),
          description: state.description.trim().isEmpty
              ? null
              : state.description.trim(),
          noteId: state.noteId,
          categoryId: state.categoryId,
          tagsIds: state.tagIds,
        );

        final loyaltyCardId = await dao.createLoyaltyCard(dto);
        await saveCustomFields(ref, loyaltyCardId, state.customFields);
        final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
        await vaultItemDao.setIconRef(
          loyaltyCardId,
          IconRefDto.fromFields(
            iconSource: state.iconSource,
            iconValue: state.iconValue,
          ),
        );
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
