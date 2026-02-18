import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/smart_converter_base.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/forms/otp_form/utils/otp_uri_parser.dart';
import 'package:hoplixi/main_store/models/dto/otp_dto.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

import '../models/otp_form_state.dart';

const _logTag = 'OtpFormProvider';

/// Провайдер состояния формы OTP
final otpFormProvider =
    NotifierProvider.autoDispose<OtpFormNotifier, OtpFormState>(
      OtpFormNotifier.new,
    );

/// Notifier для управления формой OTP
class OtpFormNotifier extends Notifier<OtpFormState> {
  final _smartConverter = SmartConverter();

  @override
  OtpFormState build() {
    return const OtpFormState(isEditMode: false);
  }

  /// Инициализировать форму для создания нового OTP
  void initForCreate() {
    state = const OtpFormState(isEditMode: false);
  }

  /// Инициализировать форму для редактирования OTP
  Future<void> initForEdit(String otpId) async {
    state = state.copyWith(isLoading: true);

    try {
      final dao = await ref.read(otpDaoProvider.future);
      final record = await dao.getById(otpId);

      if (record == null) {
        logWarning('OTP not found: $otpId', tag: _logTag);
        state = state.copyWith(isLoading: false);
        return;
      }

      final (vault, otpItem) = record;
      final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
      final tagIds = await vaultItemDao.getTagIds(otpId);
      final tagDao = await ref.read(tagDaoProvider.future);
      final tagRecords = await tagDao.getTagsByIds(tagIds);

      // Декодируем секрет из bytes обратно в base32 для отображения
      final secretBytes = otpItem.secret;
      final secretBase32 =
          _smartConverter.toBase32(
            String.fromCharCodes(secretBytes),
          )['base32'] ??
          '';

      state = OtpFormState(
        isEditMode: true,
        editingOtpId: otpId,
        otpType: OtpTypeX.fromString(otpItem.type.name),
        issuer: otpItem.issuer ?? '',
        accountName: otpItem.accountName ?? '',
        secret: secretBase32,
        noteId: vault.noteId,
        algorithm: AlgorithmOtpX.fromString(otpItem.algorithm.name),
        digits: otpItem.digits,
        period: otpItem.period,
        counter: otpItem.counter,
        categoryId: vault.categoryId,
        passwordId: otpItem.passwordItemId,
        tagIds: tagIds,
        tagNames: tagRecords.map((tag) => tag.name).toList(),
        isLoading: false,
      );
    } catch (e, stack) {
      logError(
        'Failed to load OTP for editing',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
      state = state.copyWith(isLoading: false);
    }
  }

  /// Применить данные из отсканированного QR-кода
  void applyFromQrCode(String qrData) {
    final parseResult = OtpUriParser.parse(qrData);

    if (parseResult == null) {
      logWarning('Failed to parse OTP URI: $qrData', tag: _logTag);
      return;
    }

    state = state.copyWith(
      otpType: parseResult.type,
      issuer: parseResult.issuer ?? '',
      accountName: parseResult.accountName ?? '',
      secret: parseResult.secret,
      algorithm: parseResult.algorithm,
      digits: parseResult.digits,
      period: parseResult.period,
      counter: parseResult.counter,
      isFromQrCode: true,
      // Очищаем ошибки после загрузки из QR
      secretError: null,
      issuerError: null,
      accountNameError: null,
    );

    logInfo(
      'OTP data loaded from QR code: ${parseResult.issuer}',
      tag: _logTag,
    );
  }

  /// Обновить тип OTP
  void setOtpType(OtpType type) {
    state = state.copyWith(otpType: type);
  }

  /// Обновить поле issuer
  void setIssuer(String value) {
    state = state.copyWith(issuer: value);
  }

  /// Обновить поле accountName
  void setAccountName(String value) {
    state = state.copyWith(accountName: value);
  }

  /// Обновить поле secret
  void setSecret(String value) {
    state = state.copyWith(secret: value, secretError: _validateSecret(value));
  }

  /// Обновить поле noteId
  void setNoteId(String? value) {
    state = state.copyWith(noteId: value);
  }

  /// Обновить алгоритм
  void setAlgorithm(AlgorithmOtp algorithm) {
    state = state.copyWith(algorithm: algorithm);
  }

  /// Обновить количество цифр
  void setDigits(int digits) {
    state = state.copyWith(
      digits: digits,
      digitsError: _validateDigits(digits),
    );
  }

  /// Обновить период
  void setPeriod(int period) {
    state = state.copyWith(
      period: period,
      periodError: _validatePeriod(period),
    );
  }

  /// Обновить счётчик (для HOTP)
  void setCounter(int? counter) {
    state = state.copyWith(counter: counter);
  }

  /// Обновить категорию
  void setCategory(String? categoryId, String? categoryName) {
    state = state.copyWith(categoryId: categoryId, categoryName: categoryName);
  }

  /// Обновить теги
  void setTags(List<String> tagIds, List<String> tagNames) {
    state = state.copyWith(tagIds: tagIds, tagNames: tagNames);
  }

  /// Обновить связь с паролем
  void setPasswordId(String? passwordId) {
    state = state.copyWith(passwordId: passwordId);
  }

  /// Валидация секрета
  String? _validateSecret(String value) {
    if (value.trim().isEmpty) {
      return 'Секретный ключ обязателен';
    }

    // Проверка, что это валидный Base32
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    final base32Regex = RegExp(r'^[A-Z2-7]+=*$');
    if (!base32Regex.hasMatch(cleaned)) {
      return 'Неверный формат Base32';
    }

    return null;
  }

  /// Валидация количества цифр
  String? _validateDigits(int digits) {
    if (digits < 6 || digits > 8) {
      return 'Количество цифр должно быть от 6 до 8';
    }
    return null;
  }

  /// Валидация периода
  String? _validatePeriod(int period) {
    if (period < 1 || period > 120) {
      return 'Период должен быть от 1 до 120 секунд';
    }
    return null;
  }

  /// Валидировать все поля формы
  bool validateAll() {
    final secretError = _validateSecret(state.secret);
    final digitsError = _validateDigits(state.digits);
    final periodError = _validatePeriod(state.period);

    String? counterError;
    if (state.otpType == OtpType.hotp && state.counter == null) {
      counterError = 'Счётчик обязателен для HOTP';
    }

    state = state.copyWith(
      secretError: secretError,
      digitsError: digitsError,
      periodError: periodError,
      counterError: counterError,
    );

    return !state.hasErrors;
  }

  /// Конвертировать секрет в Base32 (используя SmartConverter)
  String _normalizeSecretToBase32(String secret) {
    final result = _smartConverter.toBase32(secret.trim());
    return result['base32'] ?? secret.toUpperCase();
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
      final dao = await ref.read(otpDaoProvider.future);

      // Нормализуем секрет в Base32
      final normalizedSecret = _normalizeSecretToBase32(state.secret);

      if (state.isEditMode && state.editingOtpId != null) {
        // Режим редактирования
        final dto = UpdateOtpDto(
          issuer: state.issuer.trim().isEmpty ? null : state.issuer.trim(),
          accountName: state.accountName.trim().isEmpty
              ? null
              : state.accountName.trim(),
          noteId: state.noteId,
          algorithm: state.algorithm.name,
          digits: state.digits,
          period: state.period,
          counter: state.counter,
          categoryId: state.categoryId,
          passwordId: state.passwordId,
        );

        final success = await dao.updateOtp(state.editingOtpId!, dto);

        if (success) {
          final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
          await vaultItemDao.syncTags(state.editingOtpId!, state.tagIds);

          logInfo('OTP updated: ${state.editingOtpId}', tag: _logTag);
          state = state.copyWith(isSaving: false, isSaved: true);

          // Триггерим обновление списка
          ref
              .read(dataRefreshTriggerProvider.notifier)
              .triggerEntityUpdate(
                EntityType.otp,
                entityId: state.editingOtpId,
              );

          return true;
        } else {
          logWarning(
            'Failed to update OTP: ${state.editingOtpId}',
            tag: _logTag,
          );
          state = state.copyWith(isSaving: false);
          return false;
        }
      } else {
        // Режим создания
        final dto = CreateOtpDto(
          type: state.otpType.name,
          secret: normalizedSecret.codeUnits,
          secretEncoding: SecretEncoding.BASE32.name,
          issuer: state.issuer.trim().isEmpty ? null : state.issuer.trim(),
          accountName: state.accountName.trim().isEmpty
              ? null
              : state.accountName.trim(),
          noteId: state.noteId,
          algorithm: state.algorithm.name,
          digits: state.digits,
          period: state.period,
          counter: state.otpType == OtpType.hotp ? (state.counter ?? 0) : null,
          categoryId: state.categoryId,
          tagsIds: state.tagIds.isEmpty ? null : state.tagIds,
          passwordId: state.passwordId,
        );

        final otpId = await dao.createOtp(dto);

        logInfo('OTP created: $otpId', tag: _logTag);
        state = state.copyWith(isSaving: false, isSaved: true);

        // Триггерим обновление списка
        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityAdd(EntityType.otp, entityId: otpId);

        return true;
      }
    } catch (e, stack) {
      logError('Failed to save OTP', error: e, stackTrace: stack, tag: _logTag);
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  /// Сбросить флаг сохранения
  void resetSaved() {
    state = state.copyWith(isSaved: false);
  }

  /// Сбросить форму
  void reset() {
    state = const OtpFormState(isEditMode: false);
  }
}
