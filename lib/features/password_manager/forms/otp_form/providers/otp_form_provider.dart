import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/smart_converter_base.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/forms/otp_form/utils/otp_uri_parser.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/providers/repository_providers.dart';
import 'package:hoplixi/main_db/core/tables/otp/otp_items.dart';

import '../models/otp_form_state.dart';

const _logTag = 'OtpFormProvider';

final otpFormProvider =
    NotifierProvider.autoDispose<OtpFormNotifier, OtpFormState>(
      OtpFormNotifier.new,
    );

class OtpFormNotifier extends Notifier<OtpFormState> {
  final _smartConverter = SmartConverter();

  @override
  OtpFormState build() {
    return const OtpFormState(isEditMode: false);
  }

  void initForCreate() {
    state = const OtpFormState(isEditMode: false);
  }

  Future<void> initForEdit(String otpId) async {
    state = state.copyWith(isLoading: true);

    try {
      final repository = await ref.read(otpRepositoryProvider.future);
      final view = await repository.getViewById(otpId);

      if (view == null) {
        logWarning('OTP not found: $otpId', tag: _logTag);
        state = state.copyWith(isLoading: false);
        return;
      }

      final item = view.item;
      final details = view.otp;

      // TODO: handle tags properly
      final tagIds = <String>[];
      final tagNames = <String>[];

      final secretBase32 =
          _smartConverter.toBase32(
            String.fromCharCodes(details.secret),
          )['base32'] ??
          '';

      state = OtpFormState(
        isEditMode: true,
        editingOtpId: otpId,
        otpType: details.type,
        issuer: details.issuer ?? '',
        accountName: details.accountName ?? '',
        secret: secretBase32,
        algorithm: details.algorithm,
        digits: details.digits,
        period: details.period ?? 30,
        counter: details.counter,
        categoryId: item.categoryId,
        tagIds: tagIds,
        tagNames: tagNames,
        customFields: await loadCustomFields(ref, otpId),
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

  void applyFromQrCode(String qrData) {
    final parseResult = OtpUriParser.parse(qrData);

    if (parseResult == null) {
      logWarning('Failed to parse OTP URI from scanned data', tag: _logTag);
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
      secretError: null,
      issuerError: null,
      accountNameError: null,
    );

    logInfo('OTP data loaded from QR code', tag: _logTag);
  }

  void setOtpType(OtpType type) {
    state = state.copyWith(otpType: type);
  }

  void setIssuer(String value) {
    state = state.copyWith(issuer: value);
  }

  void setAccountName(String value) {
    state = state.copyWith(accountName: value);
  }

  void setSecret(String value) {
    state = state.copyWith(secret: value, secretError: _validateSecret(value));
  }

  void setNoteId(String? value) {
    state = state.copyWith(noteId: value);
  }

  void setAlgorithm(OtpHashAlgorithm algorithm) {
    state = state.copyWith(algorithm: algorithm);
  }

  void setDigits(int digits) {
    state = state.copyWith(
      digits: digits,
      digitsError: _validateDigits(digits),
    );
  }

  void setPeriod(int period) {
    state = state.copyWith(
      period: period,
      periodError: _validatePeriod(period),
    );
  }

  void setCounter(int? counter) {
    state = state.copyWith(counter: counter);
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

  void setPasswordId(String? passwordId) {
    state = state.copyWith(passwordId: passwordId);
  }

  String? _validateSecret(String value) {
    if (value.trim().isEmpty) {
      return 'Секретный ключ обязателен';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    final base32Regex = RegExp(r'^[A-Z2-7]+=*$');
    if (!base32Regex.hasMatch(cleaned)) {
      return 'Неверный формат Base32';
    }
    return null;
  }

  String? _validateDigits(int digits) {
    if (digits < 6 || digits > 8) {
      return 'Количество цифр должно быть от 6 до 8';
    }
    return null;
  }

  String? _validatePeriod(int period) {
    if (period < 1 || period > 120) {
      return 'Период должен быть от 1 до 120 секунд';
    }
    return null;
  }

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

  String _normalizeSecretToBase32(String secret) {
    final result = _smartConverter.toBase32(secret.trim());
    return result['base32'] ?? secret.toUpperCase();
  }

  Future<bool> save() async {
    if (!validateAll()) {
      logWarning('Form validation failed', tag: _logTag);
      return false;
    }

    state = state.copyWith(isSaving: true);

    try {
      final repository = await ref.read(otpRepositoryProvider.future);
      final normalizedSecret = _normalizeSecretToBase32(state.secret);

      if (state.isEditMode && state.editingOtpId != null) {
        await repository.update(
          PatchOtpDto(
            item: VaultItemPatchDto(
              itemId: state.editingOtpId!,
              name: FieldUpdate.set(state.issuer.isNotEmpty ? state.issuer : state.accountName),
              description: FieldUpdate.set(state.description.isEmpty ? null : state.description),
              categoryId: FieldUpdate.set(state.categoryId),
            ),
            otp: PatchOtpDataDto(
              type: FieldUpdate.set(state.otpType),
              issuer: FieldUpdate.set(state.issuer.trim().isEmpty ? null : state.issuer.trim()),
              accountName: FieldUpdate.set(state.accountName.trim().isEmpty ? null : state.accountName.trim()),
              secret: FieldUpdate.set(Uint8List.fromList(normalizedSecret.codeUnits)),
              algorithm: FieldUpdate.set(state.algorithm),
              digits: FieldUpdate.set(state.digits),
              period: FieldUpdate.set(state.otpType == OtpType.otp ? state.period : null),
              counter: FieldUpdate.set(state.otpType == OtpType.hotp ? state.counter : null),
            ),
            tags: FieldUpdate.set(state.tagIds),
          ),
        );

        await saveCustomFields(ref, state.editingOtpId!, state.customFields);
        // TODO: handle icon ref and password link

        logInfo('OTP updated: ${state.editingOtpId}', tag: _logTag);
        state = state.copyWith(isSaving: false, isSaved: true);

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.otp,
              entityId: state.editingOtpId,
            );

        return true;
      } else {
        final id = await repository.create(
          CreateOtpDto(
            item: VaultItemCreateDto(
              name: state.issuer.isNotEmpty ? state.issuer : state.accountName,
              description: state.description.isEmpty ? null : state.description,
              categoryId: state.categoryId,
            ),
            otp: OtpDataDto(
              type: state.otpType,
              issuer: state.issuer.trim().isEmpty ? null : state.issuer.trim(),
              accountName: state.accountName.trim().isEmpty ? null : state.accountName.trim(),
              secret: Uint8List.fromList(normalizedSecret.codeUnits),
              algorithm: state.algorithm,
              digits: state.digits,
              period: state.otpType == OtpType.otp ? state.period : null,
              counter: state.otpType == OtpType.hotp ? (state.counter ?? 0) : null,
            ),
          ),
        );

        await saveCustomFields(ref, id, state.customFields);
        // TODO: handle tags, icon ref, password link

        logInfo('OTP created: $id', tag: _logTag);
        state = state.copyWith(isSaving: false, isSaved: true);

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityAdd(EntityType.otp, entityId: id);

        return true;
      }
    } catch (e, stack) {
      logError('Failed to save OTP', error: e, stackTrace: stack, tag: _logTag);
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  void resetSaved() {
    state = state.copyWith(isSaved: false);
  }

  void reset() {
    state = const OtpFormState(isEditMode: false);
  }
}
