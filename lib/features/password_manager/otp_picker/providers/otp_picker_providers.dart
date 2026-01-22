import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/otp_picker/models/otp_picker_models.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/otps_filter.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';

const int pageSize = 20;

/// Provider для фильтра OTP
final otpPickerFilterProvider =
    NotifierProvider<OtpPickerFilterNotifier, OtpsFilter>(
      OtpPickerFilterNotifier.new,
    );

class OtpPickerFilterNotifier extends Notifier<OtpsFilter> {
  @override
  OtpsFilter build() {
    return OtpsFilter.create(
      base: BaseFilter.create(
        query: '',
        limit: pageSize,
        offset: 0,
        sortDirection: SortDirection.desc,
      ),
      sortField: OtpsSortField.modifiedAt,
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
      base: state.base.copyWith(offset: (state.base.offset ?? 0) + pageSize),
    );
  }

  /// Сбросить фильтр
  void reset() {
    state = OtpsFilter.create(
      base: BaseFilter.create(
        query: '',
        limit: pageSize,
        offset: 0,
        sortDirection: SortDirection.desc,
      ),
      sortField: OtpsSortField.modifiedAt,
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
    final mainStoreAsync = ref.read(mainStoreProvider);

    final mainStore = mainStoreAsync.value;
    if (mainStore == null || !mainStore.isOpen) {
      Toaster.error(title: 'Ошибка', description: 'База данных не открыта');
      return;
    }

    try {
      final manager = await ref.read(mainStoreManagerProvider.future);
      if (manager == null || manager.currentStore == null) {
        Toaster.error(title: 'Ошибка', description: 'База данных недоступна');
        return;
      }

      final dao = manager.currentStore!.otpFilterDao;
      final otps = await dao.getFiltered(filter);
      final total = await dao.countFiltered(filter);

      // Исключаем текущий OTP из списка
      final filteredOtps = excludeOtpId != null
          ? otps.where((otp) => otp.id != excludeOtpId).toList()
          : otps;

      state = OtpPickerData(
        otps: filteredOtps,
        hasMore: filteredOtps.length < total,
        isLoadingMore: false,
        excludeOtpId: excludeOtpId,
      );
    } catch (e, stack) {
      Toaster.error(title: 'Ошибка', description: 'Не удалось загрузить OTP');
      // ignore: avoid_print
      print('Error loading OTPs: $e\n$stack');
    }
  }

  /// Загрузить следующую страницу
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      ref.read(otpPickerFilterProvider.notifier).incrementOffset();
      final filter = ref.read(otpPickerFilterProvider);

      final manager = await ref.read(mainStoreManagerProvider.future);
      if (manager == null || manager.currentStore == null) return;

      final dao = manager.currentStore!.otpFilterDao;
      final newOtps = await dao.getFiltered(filter);
      final total = await dao.countFiltered(filter);

      final currentOtps = List.of(state.otps);

      // Исключаем если попался в "новых" (хотя пагинация должна работать)
      final excludeId = state.excludeOtpId;
      if (excludeId != null) {
        currentOtps.addAll(newOtps.where((otp) => otp.id != excludeId));
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
}
