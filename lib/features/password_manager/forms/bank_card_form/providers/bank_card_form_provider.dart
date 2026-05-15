import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/providers/repository_providers.dart';
import 'package:hoplixi/main_db/core/tables/bank_card/bank_card_items.dart';

import '../models/bank_card_form_state.dart';

const _logTag = 'BankCardFormProvider';

final bankCardFormProvider =
    NotifierProvider.autoDispose<BankCardFormNotifier, BankCardFormState>(
      BankCardFormNotifier.new,
    );

class BankCardFormNotifier extends Notifier<BankCardFormState> {
  @override
  BankCardFormState build() {
    return const BankCardFormState(isEditMode: false);
  }

  void initForCreate() {
    state = const BankCardFormState(isEditMode: false);
  }

  Future<void> initForEdit(String bankCardId) async {
    state = state.copyWith(isLoading: true);

    try {
      final repository = await ref.read(bankCardRepositoryProvider.future);
      final view = await repository.getViewById(bankCardId);

      if (view == null) {
        logWarning('Bank card not found: $bankCardId', tag: _logTag);
        state = state.copyWith(isLoading: false);
        return;
      }

      final item = view.item;
      final details = view.bankCard;
      
      // TODO: handle tags properly
      final tagIds = <String>[];
      final tagNames = <String>[];

      final customFields = await loadCustomFields(ref, bankCardId);

      state = BankCardFormState(
        isEditMode: true,
        editingBankCardId: bankCardId,
        name: item.name,
        cardholderName: details.cardholderName ?? '',
        cardNumber: details.cardNumber,
        expiryMonth: details.expiryMonth ?? '',
        expiryYear: details.expiryYear ?? '',
        cvv: details.cvv ?? '',
        bankName: details.bankName ?? '',
        accountNumber: details.accountNumber ?? '',
        routingNumber: details.routingNumber ?? '',
        description: item.description ?? '',
        cardType: details.cardType?.name,
        cardNetwork: details.cardNetwork?.name,
        categoryId: item.categoryId,
        tagIds: tagIds,
        tagNames: tagNames,
        customFields: customFields,
        isLoading: false,
      );
    } catch (e, stack) {
      logError(
        'Failed to load bank card for editing',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
      state = state.copyWith(isLoading: false);
    }
  }

  void setName(String value) {
    state = state.copyWith(name: value, nameError: _validateName(value));
  }

  void setCardholderName(String value) {
    state = state.copyWith(
      cardholderName: value,
      cardholderNameError: _validateCardholderName(value),
    );
  }

  void setCardNumber(String value) {
    state = state.copyWith(
      cardNumber: value,
      cardNumberError: _validateCardNumber(value),
    );
  }

  void setExpiryMonth(String value) {
    state = state.copyWith(
      expiryMonth: value,
      expiryMonthError: _validateExpiryMonth(value),
    );
  }

  void setExpiryYear(String value) {
    state = state.copyWith(
      expiryYear: value,
      expiryYearError: _validateExpiryYear(value),
    );
  }

  void setCvv(String value) {
    state = state.copyWith(cvv: value, cvvError: _validateCvv(value));
  }

  void setBankName(String value) {
    state = state.copyWith(bankName: value);
  }

  void setAccountNumber(String value) {
    state = state.copyWith(accountNumber: value);
  }

  void setRoutingNumber(String value) {
    state = state.copyWith(routingNumber: value);
  }

  void setDescription(String value) {
    state = state.copyWith(description: value);
  }

  void setNoteId(String? value) {
    state = state.copyWith(noteId: value);
  }

  void setCardType(String? value) {
    state = state.copyWith(cardType: value);
  }

  void setCardNetwork(String? value) {
    state = state.copyWith(cardNetwork: value);
  }

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

  void setCvvFocused(bool isFocused) {
    state = state.copyWith(isCvvFocused: isFocused);
  }

  String? _validateName(String value) {
    if (value.trim().isEmpty) {
      return 'Название обязательно';
    }
    if (value.trim().length > 255) {
      return 'Название не должно превышать 255 символов';
    }
    return null;
  }

  String? _validateCardholderName(String value) {
    if (value.trim().isEmpty) {
      return 'Имя владельца обязательно';
    }
    if (value.trim().length > 255) {
      return 'Имя владельца не должно превышать 255 символов';
    }
    return null;
  }

  String? _validateCardNumber(String value) {
    final cleanNumber = value.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.isEmpty) {
      return 'Номер карты обязателен';
    }
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return 'Номер карты должен содержать 13-19 цифр';
    }
    return null;
  }

  String? _validateExpiryMonth(String value) {
    if (value.trim().isEmpty) {
      return 'Месяц обязателен';
    }
    final month = int.tryParse(value);
    if (month == null || month < 1 || month > 12) {
      return 'Месяц должен быть от 01 до 12';
    }
    return null;
  }

  String? _validateExpiryYear(String value) {
    if (value.trim().isEmpty) {
      return 'Год обязателен';
    }
    final year = int.tryParse(value);
    if (year == null) {
      return 'Введите корректный год';
    }
    final currentYear = DateTime.now().year;
    if (year < currentYear || year > currentYear + 20) {
      return 'Год должен быть от $currentYear до ${currentYear + 20}';
    }
    return null;
  }

  String? _validateCvv(String value) {
    if (value.isEmpty) {
      return null;
    }
    final cleanCvv = value.replaceAll(RegExp(r'\D'), '');
    if (cleanCvv.length < 3 || cleanCvv.length > 4) {
      return 'CVV должен содержать 3-4 цифры';
    }
    return null;
  }

  bool validateAll() {
    final nameError = _validateName(state.name);
    final cardholderNameError = _validateCardholderName(state.cardholderName);
    final cardNumberError = _validateCardNumber(state.cardNumber);
    final expiryMonthError = _validateExpiryMonth(state.expiryMonth);
    final expiryYearError = _validateExpiryYear(state.expiryYear);
    final cvvError = _validateCvv(state.cvv);

    state = state.copyWith(
      nameError: nameError,
      cardholderNameError: cardholderNameError,
      cardNumberError: cardNumberError,
      expiryMonthError: expiryMonthError,
      expiryYearError: expiryYearError,
      cvvError: cvvError,
    );

    return !state.hasErrors;
  }

  Future<bool> save() async {
    if (!validateAll()) {
      logWarning('Form validation failed', tag: _logTag);
      return false;
    }

    state = state.copyWith(isSaving: true);

    try {
      final repository = await ref.read(bankCardRepositoryProvider.future);

      if (state.isEditMode && state.editingBankCardId != null) {
        await repository.update(
          PatchBankCardDto(
            item: VaultItemPatchDto(
              itemId: state.editingBankCardId!,
              name: FieldUpdate.set(state.name.trim()),
              description: FieldUpdate.set(
                state.description.trim().isEmpty ? null : state.description.trim(),
              ),
              categoryId: FieldUpdate.set(state.categoryId),
            ),
            bankCard: PatchBankCardDataDto(
              cardholderName: FieldUpdate.set(state.cardholderName.trim()),
              cardNumber: FieldUpdate.set(
                state.cardNumber.replaceAll(RegExp(r'\D'), ''),
              ),
              expiryMonth: FieldUpdate.set(state.expiryMonth.padLeft(2, '0')),
              expiryYear: FieldUpdate.set(state.expiryYear),
              cvv: FieldUpdate.set(state.cvv.isEmpty ? null : state.cvv),
              bankName: FieldUpdate.set(
                state.bankName.trim().isEmpty ? null : state.bankName.trim(),
              ),
              accountNumber: FieldUpdate.set(
                state.accountNumber.trim().isEmpty
                    ? null
                    : state.accountNumber.trim(),
              ),
              routingNumber: FieldUpdate.set(
                state.routingNumber.trim().isEmpty
                    ? null
                    : state.routingNumber.trim(),
              ),
              cardType: FieldUpdate.set(
                state.cardType != null
                    ? CardType.values.byName(state.cardType!)
                    : null,
              ),
              cardNetwork: FieldUpdate.set(
                state.cardNetwork != null
                    ? CardNetwork.values.byName(state.cardNetwork!)
                    : null,
              ),
            ),
            tags: FieldUpdate.set(state.tagIds),
          ),
        );

        await saveCustomFields(
          ref,
          state.editingBankCardId!,
          state.customFields,
        );
        // TODO: handle icon ref

        logInfo(
          'Bank card updated: ${state.editingBankCardId}',
          tag: _logTag,
        );
        state = state.copyWith(isSaving: false, isSaved: true);

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.bankCard,
              entityId: state.editingBankCardId,
            );

        return true;
      } else {
        final id = await repository.create(
          CreateBankCardDto(
            item: VaultItemCreateDto(
              name: state.name.trim(),
              description: state.description.trim().isEmpty
                  ? null
                  : state.description.trim(),
              categoryId: state.categoryId,
            ),
            bankCard: BankCardDataDto(
              cardholderName: state.cardholderName.trim(),
              cardNumber: state.cardNumber.replaceAll(RegExp(r'\D'), ''),
              expiryMonth: state.expiryMonth.padLeft(2, '0'),
              expiryYear: state.expiryYear,
              cvv: state.cvv.isEmpty ? null : state.cvv,
              bankName: state.bankName.trim().isEmpty
                  ? null
                  : state.bankName.trim(),
              accountNumber: state.accountNumber.trim().isEmpty
                  ? null
                  : state.accountNumber.trim(),
              routingNumber: state.routingNumber.trim().isEmpty
                  ? null
                  : state.routingNumber.trim(),
              cardType: state.cardType != null
                  ? CardType.values.byName(state.cardType!)
                  : null,
              cardNetwork: state.cardNetwork != null
                  ? CardNetwork.values.byName(state.cardNetwork!)
                  : null,
            ),
          ),
        );

        // TODO: handle tags for create
        // TODO: handle icon ref

        await saveCustomFields(ref, id, state.customFields);

        logInfo('Bank card created: $id', tag: _logTag);
        state = state.copyWith(isSaving: false, isSaved: true);

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityAdd(EntityType.bankCard, entityId: id);

        return true;
      }
    } catch (e, stack) {
      logError(
        'Failed to save bank card',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  void resetSaved() {
    state = state.copyWith(isSaved: false);
  }
}
