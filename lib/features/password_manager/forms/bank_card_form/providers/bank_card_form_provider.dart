import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/main_store/models/dto/bank_card_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

import '../models/bank_card_form_state.dart';

const _logTag = 'BankCardFormProvider';

/// Провайдер состояния формы банковской карты
final bankCardFormProvider =
    NotifierProvider.autoDispose<BankCardFormNotifier, BankCardFormState>(
      BankCardFormNotifier.new,
    );

/// Notifier для управления формой банковской карты
class BankCardFormNotifier extends Notifier<BankCardFormState> {
  @override
  BankCardFormState build() {
    return const BankCardFormState(isEditMode: false);
  }

  /// Инициализировать форму для создания новой карты
  void initForCreate() {
    state = const BankCardFormState(isEditMode: false);
  }

  /// Инициализировать форму для редактирования карты
  Future<void> initForEdit(String bankCardId) async {
    state = state.copyWith(isLoading: true);

    try {
      final dao = await ref.read(bankCardDaoProvider.future);
      final record = await dao.getById(bankCardId);

      if (record == null) {
        logWarning('Bank card not found: $bankCardId', tag: _logTag);
        state = state.copyWith(isLoading: false);
        return;
      }

      final (vault, cardItem) = record;
      final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
      final tagIds = await vaultItemDao.getTagIds(bankCardId);
      final tagDao = await ref.read(tagDaoProvider.future);
      final tagRecords = await tagDao.getTagsByIds(tagIds);

      state = BankCardFormState(
        isEditMode: true,
        editingBankCardId: bankCardId,
        name: vault.name,
        cardholderName: cardItem.cardholderName,
        cardNumber: cardItem.cardNumber,
        expiryMonth: cardItem.expiryMonth,
        expiryYear: cardItem.expiryYear,
        cvv: cardItem.cvv ?? '',
        bankName: cardItem.bankName ?? '',
        accountNumber: cardItem.accountNumber ?? '',
        routingNumber: cardItem.routingNumber ?? '',
        description: vault.description ?? '',
        noteId: vault.noteId,
        cardType: cardItem.cardType?.value,
        cardNetwork: cardItem.cardNetwork?.value,
        categoryId: vault.categoryId,
        tagIds: tagIds,
        tagNames: tagRecords.map((tag) => tag.name).toList(),
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

  /// Обновить поле name
  void setName(String value) {
    state = state.copyWith(name: value, nameError: _validateName(value));
  }

  /// Обновить поле cardholderName
  void setCardholderName(String value) {
    state = state.copyWith(
      cardholderName: value,
      cardholderNameError: _validateCardholderName(value),
    );
  }

  /// Обновить поле cardNumber
  void setCardNumber(String value) {
    state = state.copyWith(
      cardNumber: value,
      cardNumberError: _validateCardNumber(value),
    );
  }

  /// Обновить поле expiryMonth
  void setExpiryMonth(String value) {
    state = state.copyWith(
      expiryMonth: value,
      expiryMonthError: _validateExpiryMonth(value),
    );
  }

  /// Обновить поле expiryYear
  void setExpiryYear(String value) {
    state = state.copyWith(
      expiryYear: value,
      expiryYearError: _validateExpiryYear(value),
    );
  }

  /// Обновить поле cvv
  void setCvv(String value) {
    state = state.copyWith(cvv: value, cvvError: _validateCvv(value));
  }

  /// Обновить поле bankName
  void setBankName(String value) {
    state = state.copyWith(bankName: value);
  }

  /// Обновить поле accountNumber
  void setAccountNumber(String value) {
    state = state.copyWith(accountNumber: value);
  }

  /// Обновить поле routingNumber
  void setRoutingNumber(String value) {
    state = state.copyWith(routingNumber: value);
  }

  /// Обновить поле description
  void setDescription(String value) {
    state = state.copyWith(description: value);
  }

  /// Обновить поле noteId
  void setNoteId(String? value) {
    state = state.copyWith(noteId: value);
  }

  /// Обновить тип карты
  void setCardType(String? value) {
    state = state.copyWith(cardType: value);
  }

  /// Обновить сеть карты
  void setCardNetwork(String? value) {
    state = state.copyWith(cardNetwork: value);
  }

  /// Обновить категорию
  void setCategory(String? categoryId, String? categoryName) {
    state = state.copyWith(categoryId: categoryId, categoryName: categoryName);
  }

  /// Обновить теги
  void setTags(List<String> tagIds, List<String> tagNames) {
    state = state.copyWith(tagIds: tagIds, tagNames: tagNames);
  }

  /// Установить фокус на CVV
  void setCvvFocused(bool isFocused) {
    state = state.copyWith(isCvvFocused: isFocused);
  }

  /// Валидация имени
  String? _validateName(String value) {
    if (value.trim().isEmpty) {
      return 'Название обязательно';
    }
    if (value.trim().length > 255) {
      return 'Название не должно превышать 255 символов';
    }
    return null;
  }

  /// Валидация имени владельца
  String? _validateCardholderName(String value) {
    if (value.trim().isEmpty) {
      return 'Имя владельца обязательно';
    }
    if (value.trim().length > 255) {
      return 'Имя владельца не должно превышать 255 символов';
    }
    return null;
  }

  /// Валидация номера карты
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

  /// Валидация месяца истечения
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

  /// Валидация года истечения
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

  /// Валидация CVV
  String? _validateCvv(String value) {
    if (value.isEmpty) {
      return null; // CVV опционален
    }
    final cleanCvv = value.replaceAll(RegExp(r'\D'), '');
    if (cleanCvv.length < 3 || cleanCvv.length > 4) {
      return 'CVV должен содержать 3-4 цифры';
    }
    return null;
  }

  /// Валидировать все поля формы
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

  /// Сохранить форму
  Future<bool> save() async {
    // Валидация
    if (!validateAll()) {
      logWarning('Form validation failed', tag: _logTag);
      return false;
    }

    state = state.copyWith(isSaving: true);

    try {
      final dao = await ref.read(bankCardDaoProvider.future);

      if (state.isEditMode && state.editingBankCardId != null) {
        // Режим редактирования
        final dto = UpdateBankCardDto(
          name: state.name.trim(),
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
          description: state.description.trim().isEmpty
              ? null
              : state.description.trim(),
          noteId: state.noteId,
          cardType: state.cardType,
          cardNetwork: state.cardNetwork,
          categoryId: state.categoryId,
        );

        final success = await dao.updateBankCard(state.editingBankCardId!, dto);

        if (success) {
          final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
          await vaultItemDao.syncTags(state.editingBankCardId!, state.tagIds);

          logInfo(
            'Bank card updated: ${state.editingBankCardId}',
            tag: _logTag,
          );
          state = state.copyWith(isSaving: false, isSaved: true);

          // Триггерим обновление списка
          ref
              .read(dataRefreshTriggerProvider.notifier)
              .triggerEntityUpdate(
                EntityType.bankCard,
                entityId: state.editingBankCardId,
              );

          return true;
        } else {
          logWarning(
            'Failed to update bank card: ${state.editingBankCardId}',
            tag: _logTag,
          );
          state = state.copyWith(isSaving: false);
          return false;
        }
      } else {
        // Режим создания
        final dto = CreateBankCardDto(
          name: state.name.trim(),
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
          description: state.description.trim().isEmpty
              ? null
              : state.description.trim(),
          noteId: state.noteId,
          cardType: state.cardType,
          cardNetwork: state.cardNetwork,
          categoryId: state.categoryId,
          tagsIds: state.tagIds,
        );

        final bankCardId = await dao.createBankCard(dto);

        // Синхронизация тегов для новой карты
        if (state.tagIds.isNotEmpty) {
          final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
          await vaultItemDao.syncTags(bankCardId, state.tagIds);
        }

        logInfo('Bank card created: $bankCardId', tag: _logTag);
        state = state.copyWith(isSaving: false, isSaved: true);

        // Триггерим обновление списка
        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityAdd(EntityType.bankCard, entityId: bankCardId);

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

  /// Сбросить флаг сохранения
  void resetSaved() {
    state = state.copyWith(isSaved: false);
  }
}
