import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/pickers/otp_picker/models/otp_picker_models.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/services/entities/vault_card_filter_service.dart';
import 'package:hoplixi/vault_db/providers/service_providers.dart';
import 'package:result_dart/result_dart.dart';

const int pageSize = 20;

/// Provider для фильтра OTP
final otpPickerFilterProvider =
    NotifierProvider<OtpPickerFilterNotifier, OtpFilter>(
      OtpPickerFilterNotifier.new,
    );

class OtpPickerFilterNotifier extends Notifier<OtpFilter> {
  @override
  OtpFilter build() {
    return OtpFilter.create(
      base: BaseFilter.create(
        query: '',
        limit: pageSize,
        offset: 0,
        sortDirection: SortDirection.desc,
      ),
      sortField: OtpSortField.modifiedAt,
    );
  }

  /// Обновить поисковый запрос
  void updateQuery(String query) {
    state = state.copyWith(
      base: state.base.copyWith(query: query.trim(), offset: 0),
    );
  }

  /// Увеличить offset для пагинации
  void incrementOffset() {
    state = state.copyWith(
      base: state.base.copyWith(offset: state.base.offset + pageSize),
    );
  }

  /// Сбросить фильтр
  void reset() {
    state = OtpFilter.create(
      base: BaseFilter.create(
        query: '',
        limit: pageSize,
        offset: 0,
        sortDirection: SortDirection.desc,
      ),
      sortField: OtpSortField.modifiedAt,
    );
  }
}

/// Provider для загруженных данных OTP
final otpPickerDataProvider =
    NotifierProvider<OtpPickerDataNotifier, OtpPickerData>(
      OtpPickerDataNotifier.new,
    );

class OtpPickerDataNotifier extends Notifier<OtpPickerData> {
  @override
  OtpPickerData build() {
    return const OtpPickerData();
  }

  /// Загрузить первую страницу OTP
  Future<void> loadInitial(String? excludeOtpId) async {
    final filter = ref.read(otpPickerFilterProvider);
    final service = await _getService();
    if (service == null) return;

    try {
      final otps = (await service.getOtps(filter)).getOrThrow();
      final total = (await service.countOtps(filter)).getOrThrow();

      // Исключаем текущий OTP из списка
      final filteredOtps = excludeOtpId != null
          ? otps.where((otp) => otp.card.item.itemId != excludeOtpId).toList()
          : otps;

      state = OtpPickerData(
        otps: filteredOtps,
        hasMore: filteredOtps.length < total,
        isLoadingMore: false,
        excludeOtpId: excludeOtpId,
      );
    } catch (e, stack) {
      Toaster.error(title: 'Ошибка', description: 'Не удалось загрузить OTP');
      logError('Error loading OTPs', error: e, stackTrace: stack);
    }
  }

  /// Загрузить следующую страницу
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      ref.read(otpPickerFilterProvider.notifier).incrementOffset();
      final filter = ref.read(otpPickerFilterProvider);

      final service = await _getService();
      if (service == null) return;

      final newOtps = (await service.getOtps(filter)).getOrThrow();
      final total = (await service.countOtps(filter)).getOrThrow();

      final currentOtps = List.of(state.otps);

      // Исключаем если попался в "новых" (хотя пагинация должна работать)
      final excludeId = state.excludeOtpId;
      if (excludeId != null) {
        currentOtps.addAll(
          newOtps.where((otp) => otp.card.item.itemId != excludeId),
        );
      } else {
        currentOtps.addAll(newOtps);
      }

      state = state.copyWith(
        otps: currentOtps,
        hasMore: currentOtps.length < total,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
      Toaster.error(
        title: 'Ошибка',
        description: 'Не удалось загрузить больше OTP',
      );
    }
  }

  Future<VaultCardFilterService?> _getService() async {
    try {
      return await ref.read(vaultCardFilterServiceProvider.future);
    } catch (_) {
      Toaster.error(title: 'Ошибка', description: 'База данных недоступна');
      return null;
    }
  }
}
