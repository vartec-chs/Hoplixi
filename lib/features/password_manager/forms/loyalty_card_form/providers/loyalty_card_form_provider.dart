import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/main_store/models/dto/loyalty_card_dto.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

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
        cardNumber: loyalty.cardNumber,
        holderName: loyalty.holderName ?? '',
        barcodeValue: loyalty.barcodeValue ?? '',
        barcodeType: loyalty.barcodeType ?? '',
        pointsBalance: loyalty.pointsBalance ?? '',
        tier: loyalty.tier ?? '',
        expiryDate: loyalty.expiryDate?.toIso8601String().split('T').first ?? '',
        website: loyalty.website ?? '',
        phoneNumber: loyalty.phoneNumber ?? '',
        description: vault.description ?? '',
        noteId: vault.noteId,
        categoryId: vault.categoryId,
        categoryName: categoryName,
        tagIds: tagIds,
        tagNames: tagRecords.map((tag) => tag.name).toList(),
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
    state = state.copyWith(
      cardNumber: value,
      cardNumberError: _validateCardNumber(value),
    );
  }

  void setHolderName(String value) => state = state.copyWith(holderName: value);

  void setBarcodeValue(String value) => state = state.copyWith(barcodeValue: value);

  void setBarcodeType(String value) => state = state.copyWith(barcodeType: value);

  void setPointsBalance(String value) => state = state.copyWith(pointsBalance: value);

  void setTier(String value) => state = state.copyWith(tier: value);

  void setExpiryDate(String value) {
    state = state.copyWith(
      expiryDate: value,
      expiryDateError: _validateExpiryDate(value),
    );
  }

  void setWebsite(String value) {
    state = state.copyWith(website: value, websiteError: _validateWebsite(value));
  }

  void setPhoneNumber(String value) => state = state.copyWith(phoneNumber: value);

  void setDescription(String value) => state = state.copyWith(description: value);

  void setNoteId(String? value) => state = state.copyWith(noteId: value);

  void setCategory(String? categoryId, String? categoryName) {
    state = state.copyWith(categoryId: categoryId, categoryName: categoryName);
  }

  void setTags(List<String> tagIds, List<String> tagNames) {
    state = state.copyWith(tagIds: tagIds, tagNames: tagNames);
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

  String? _validateCardNumber(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'Номер карты обязателен';
    if (normalized.length < 3 || normalized.length > 255) {
      return 'Номер карты должен содержать от 3 до 255 символов';
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
    final cardNumberError = _validateCardNumber(state.cardNumber);
    final expiryDateError = _validateExpiryDate(state.expiryDate);
    final websiteError = _validateWebsite(state.website);

    state = state.copyWith(
      nameError: nameError,
      programNameError: programNameError,
      cardNumberError: cardNumberError,
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
          cardNumber: state.cardNumber.trim(),
          holderName: state.holderName.trim().isEmpty ? null : state.holderName.trim(),
          barcodeValue: state.barcodeValue.trim().isEmpty ? null : state.barcodeValue.trim(),
          barcodeType: state.barcodeType.trim().isEmpty ? null : state.barcodeType.trim(),
          pointsBalance: state.pointsBalance.trim().isEmpty ? null : state.pointsBalance.trim(),
          tier: state.tier.trim().isEmpty ? null : state.tier.trim(),
          expiryDate: expiryDate,
          website: state.website.trim().isEmpty ? null : state.website.trim(),
          phoneNumber: state.phoneNumber.trim().isEmpty ? null : state.phoneNumber.trim(),
          description: state.description.trim().isEmpty ? null : state.description.trim(),
          noteId: state.noteId,
          categoryId: state.categoryId,
          tagsIds: state.tagIds,
        );

        final success = await dao.updateLoyaltyCard(state.editingLoyaltyCardId!, dto);
        if (!success) {
          state = state.copyWith(isSaving: false);
          return false;
        }

        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(EntityType.loyaltyCard, entityId: state.editingLoyaltyCardId);
      } else {
        final dto = CreateLoyaltyCardDto(
          name: state.name.trim(),
          programName: state.programName.trim(),
          cardNumber: state.cardNumber.trim(),
          holderName: state.holderName.trim().isEmpty ? null : state.holderName.trim(),
          barcodeValue: state.barcodeValue.trim().isEmpty ? null : state.barcodeValue.trim(),
          barcodeType: state.barcodeType.trim().isEmpty ? null : state.barcodeType.trim(),
          pointsBalance: state.pointsBalance.trim().isEmpty ? null : state.pointsBalance.trim(),
          tier: state.tier.trim().isEmpty ? null : state.tier.trim(),
          expiryDate: expiryDate,
          website: state.website.trim().isEmpty ? null : state.website.trim(),
          phoneNumber: state.phoneNumber.trim().isEmpty ? null : state.phoneNumber.trim(),
          description: state.description.trim().isEmpty ? null : state.description.trim(),
          noteId: state.noteId,
          categoryId: state.categoryId,
          tagsIds: state.tagIds,
        );

        final loyaltyCardId = await dao.createLoyaltyCard(dto);
        ref
            .read(dataRefreshTriggerProvider.notifier)
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
