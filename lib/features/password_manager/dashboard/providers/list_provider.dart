import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/data_refresh_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/list_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/index.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_tab_provider.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/main_store/provider/index.dart';

import '../models/filter_tab.dart';
import 'data_refresh_trigger_provider.dart';

// Константа размера страницы можно переиспользовать или сделать мапу по типу
const int kDefaultPageSize = 20;

/// Провайдер family: для каждого EntityType — свой экземпляр Notifier
final paginatedListProvider =
    AsyncNotifierProvider.family<
      PaginatedListNotifier,
      DashboardListState<BaseCardDto>,
      EntityType
    >(PaginatedListNotifier.new);

class PaginatedListNotifier
    extends AsyncNotifier<DashboardListState<BaseCardDto>> {
  PaginatedListNotifier(this.entityType);

  final EntityType entityType;

  ProviderSubscription<PasswordsFilter>? _passwordFilterSubscription;
  ProviderSubscription<NotesFilter>? _noteFilterSubscription;
  ProviderSubscription<BankCardsFilter>? _bankCardFilterSubscription;
  ProviderSubscription<FilesFilter>? _fileFilterSubscription;
  ProviderSubscription<OtpsFilter>? _otpFilterSubscription;
  ProviderSubscription<ApiKeysFilter>? _apiKeyFilterSubscription;
  ProviderSubscription<SshKeysFilter>? _sshKeyFilterSubscription;
  ProviderSubscription<CertificatesFilter>? _certificateFilterSubscription;
  ProviderSubscription<CryptoWalletsFilter>? _cryptoWalletFilterSubscription;
  ProviderSubscription<WifisFilter>? _wifiFilterSubscription;
  ProviderSubscription<IdentitiesFilter>? _identityFilterSubscription;
  ProviderSubscription<LicenseKeysFilter>? _licenseKeyFilterSubscription;
  ProviderSubscription<RecoveryCodesFilter>? _recoveryCodesFilterSubscription;
  ProviderSubscription<DataRefreshState>? _passwordRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _noteRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _bankCardRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _fileRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _otpRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _apiKeyRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _sshKeyRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _certificateRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _cryptoWalletRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _wifiRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _identityRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _licenseKeyRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _recoveryCodesRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _documentRefreshSubscription;

  int get pageSize {
    // можно иметь разный pageSize для разных типов, если нужно
    return kDefaultPageSize;
  }

  final String _logTag = 'DashboardListProvider: ';

  bool get _isUnsupportedEntity => false;

  @override
  Future<DashboardListState<BaseCardDto>> build() async {
    ref.listen(filterTabProvider, (prev, next) {
      if (prev != next) {
        _resetAndLoad();
      }
    });

    _subscribeToTypeSpecificProviders();

    return _loadInitialData();
  }

  void _subscribeToTypeSpecificProviders() {
    _unsubscribeTypeSpecificProviders();
    switch (entityType) {
      case EntityType.password:
        _passwordFilterSubscription = ref.listen(passwordsFilterProvider, (
          prev,
          next,
        ) {
          if (prev != next) {
            _resetAndLoad();
          }
        });
        _passwordRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.password)) {
              logDebug(
                'PaginatedListNotifier: Триггер обновления данных паролей',
              );
              _resetAndLoad();
            }
          },
        );

        break;
      case EntityType.document:
        _documentRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.document)) {
              logDebug(
                'PaginatedListNotifier: Триггер обновления данных документов',
              );
              _resetAndLoad();
            }
          },
        );
        break;
      case EntityType.note:
        _noteFilterSubscription = ref.listen(notesFilterProvider, (prev, next) {
          if (prev != next) {
            _resetAndLoad();
          }
        });
        _noteRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.note)) {
              logDebug(
                'PaginatedListNotifier: Триггер обновления данных заметок',
              );
              _resetAndLoad();
            }
          },
        );
        break;
      case EntityType.bankCard:
        _bankCardFilterSubscription = ref.listen(bankCardsFilterProvider, (
          prev,
          next,
        ) {
          if (prev != next) {
            _resetAndLoad();
          }
        });
        _bankCardRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.bankCard)) {
              logDebug(
                'PaginatedListNotifier: Триггер обновления данных карточек',
              );
              _resetAndLoad();
            }
          },
        );
        break;
      case EntityType.file:
        _fileFilterSubscription = ref.listen(filesFilterProvider, (prev, next) {
          if (prev != next) {
            _resetAndLoad();
          }
        });
        _fileRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.file)) {
              logDebug(
                'PaginatedListNotifier: Триггер обновления данных файлов',
              );
              _resetAndLoad();
            }
          },
        );
        break;
      case EntityType.otp:
        _otpFilterSubscription = ref.listen(otpsFilterProvider, (prev, next) {
          if (prev != next) {
            _resetAndLoad();
          }
        });
        _otpRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.otp)) {
              logDebug('PaginatedListNotifier: Триггер обновления данных OTP');
              _resetAndLoad();
            }
          },
        );
        break;
      case EntityType.apiKey:
        _apiKeyFilterSubscription = ref.listen(apiKeysFilterProvider, (
          prev,
          next,
        ) {
          if (prev != next) {
            _resetAndLoad();
          }
        });
        _apiKeyRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.apiKey)) {
              _resetAndLoad();
            }
          },
        );
        break;
      case EntityType.sshKey:
        _sshKeyFilterSubscription = ref.listen(sshKeysFilterProvider, (
          prev,
          next,
        ) {
          if (prev != next) {
            _resetAndLoad();
          }
        });
        _sshKeyRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.sshKey)) {
              _resetAndLoad();
            }
          },
        );
        break;
      case EntityType.certificate:
        _certificateFilterSubscription = ref.listen(
          certificatesFilterProvider,
          (prev, next) {
            if (prev != next) {
              _resetAndLoad();
            }
          },
        );
        _certificateRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.certificate)) {
              _resetAndLoad();
            }
          },
        );
        break;
      case EntityType.cryptoWallet:
        _cryptoWalletFilterSubscription = ref.listen(
          cryptoWalletsFilterProvider,
          (prev, next) {
            if (prev != next) {
              _resetAndLoad();
            }
          },
        );
        _cryptoWalletRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.cryptoWallet)) {
              _resetAndLoad();
            }
          },
        );
        break;
      case EntityType.wifi:
        _wifiFilterSubscription = ref.listen(wifisFilterProvider, (prev, next) {
          if (prev != next) {
            _resetAndLoad();
          }
        });
        _wifiRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.wifi)) {
              _resetAndLoad();
            }
          },
        );
        break;
      case EntityType.identity:
        _identityFilterSubscription = ref.listen(identitiesFilterProvider, (
          prev,
          next,
        ) {
          if (prev != next) {
            _resetAndLoad();
          }
        });
        _identityRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.identity)) {
              _resetAndLoad();
            }
          },
        );
        break;
      case EntityType.licenseKey:
        _licenseKeyFilterSubscription = ref.listen(licenseKeysFilterProvider, (
          prev,
          next,
        ) {
          if (prev != next) {
            _resetAndLoad();
          }
        });
        _licenseKeyRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.licenseKey)) {
              _resetAndLoad();
            }
          },
        );
        break;
      case EntityType.recoveryCodes:
        _recoveryCodesFilterSubscription = ref.listen(
          recoveryCodesFilterProvider,
          (prev, next) {
            if (prev != next) {
              _resetAndLoad();
            }
          },
        );
        _recoveryCodesRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.recoveryCodes)) {
              _resetAndLoad();
            }
          },
        );
        break;
    }
  }

  bool _shouldHandleRefresh(DataRefreshState state, EntityType type) {
    return state.entityType == null || state.entityType == type;
  }

  void _unsubscribeTypeSpecificProviders() {
    _passwordFilterSubscription?.close();
    _passwordFilterSubscription = null;
    _noteFilterSubscription?.close();
    _noteFilterSubscription = null;
    _bankCardFilterSubscription?.close();
    _bankCardFilterSubscription = null;
    _fileFilterSubscription?.close();
    _fileFilterSubscription = null;
    _otpFilterSubscription?.close();
    _otpFilterSubscription = null;
    _apiKeyFilterSubscription?.close();
    _apiKeyFilterSubscription = null;
    _sshKeyFilterSubscription?.close();
    _sshKeyFilterSubscription = null;
    _certificateFilterSubscription?.close();
    _certificateFilterSubscription = null;
    _cryptoWalletFilterSubscription?.close();
    _cryptoWalletFilterSubscription = null;
    _wifiFilterSubscription?.close();
    _wifiFilterSubscription = null;
    _identityFilterSubscription?.close();
    _identityFilterSubscription = null;
    _licenseKeyFilterSubscription?.close();
    _licenseKeyFilterSubscription = null;
    _recoveryCodesFilterSubscription?.close();
    _recoveryCodesFilterSubscription = null;
    _passwordRefreshSubscription?.close();
    _passwordRefreshSubscription = null;
    _noteRefreshSubscription?.close();
    _noteRefreshSubscription = null;
    _bankCardRefreshSubscription?.close();
    _bankCardRefreshSubscription = null;
    _fileRefreshSubscription?.close();
    _fileRefreshSubscription = null;
    _otpRefreshSubscription?.close();
    _otpRefreshSubscription = null;
    _apiKeyRefreshSubscription?.close();
    _apiKeyRefreshSubscription = null;
    _sshKeyRefreshSubscription?.close();
    _sshKeyRefreshSubscription = null;
    _certificateRefreshSubscription?.close();
    _certificateRefreshSubscription = null;
    _cryptoWalletRefreshSubscription?.close();
    _cryptoWalletRefreshSubscription = null;
    _wifiRefreshSubscription?.close();
    _wifiRefreshSubscription = null;
    _identityRefreshSubscription?.close();
    _identityRefreshSubscription = null;
    _licenseKeyRefreshSubscription?.close();
    _licenseKeyRefreshSubscription = null;
    _recoveryCodesRefreshSubscription?.close();
    _recoveryCodesRefreshSubscription = null;
    _documentRefreshSubscription?.close();
    _documentRefreshSubscription = null;
  }

  /// Выбор DAO по type — вынеси в отдельную функцию/мапу
  Future<FilterDao<dynamic, BaseCardDto>> _daoForType() {
    switch (entityType) {
      case EntityType.password:
        return ref.read(passwordFilterDaoProvider.future);
      case EntityType.note:
        return ref.read(noteFilterDaoProvider.future);
      case EntityType.bankCard:
        return ref.read(bankCardFilterDaoProvider.future);
      case EntityType.file:
        return ref.read(fileFilterDaoProvider.future);
      case EntityType.otp:
        return ref.read(otpFilterDaoProvider.future);
      case EntityType.document:
        return ref.read(documentFilterDaoProvider.future);
      case EntityType.apiKey:
        return ref.read(apiKeyFilterDaoProvider.future);
      case EntityType.sshKey:
        return ref.read(sshKeyFilterDaoProvider.future);
      case EntityType.certificate:
        return ref.read(certificateFilterDaoProvider.future);
      case EntityType.cryptoWallet:
        return ref.read(cryptoWalletFilterDaoProvider.future);
      case EntityType.wifi:
        return ref.read(wifiFilterDaoProvider.future);
      case EntityType.identity:
        return ref.read(identityFilterDaoProvider.future);
      case EntityType.licenseKey:
        return ref.read(licenseKeyFilterDaoProvider.future);
      case EntityType.recoveryCodes:
        return ref.read(recoveryCodesFilterDaoProvider.future);
    }
  }

  /// Если нужен специфичный фильтр (например PasswordFilter) — строим его условно.
  /// Возвращаем общий BaseFilter или конкретный фильтр для DAO.getFilteredX
  dynamic _buildFilter({int page = 1}) {
    final limit = pageSize;
    final offset = (page - 1) * limit;
    final currentTab = ref.read(filterTabProvider);
    final tabFilter = _getTabFilter(currentTab);

    switch (entityType) {
      case EntityType.password:
        final passwordFilter = ref.read(passwordsFilterProvider);
        final base = passwordFilter.base.copyWith(
          isFavorite: passwordFilter.base.isFavorite ?? tabFilter.isFavorite,
          isArchived: passwordFilter.base.isArchived ?? tabFilter.isArchived,
          isDeleted: passwordFilter.base.isDeleted ?? tabFilter.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ??
              passwordFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return passwordFilter.copyWith(base: base);
      case EntityType.note:
        final notesFilter = ref.read(notesFilterProvider);
        final base = notesFilter.base.copyWith(
          isFavorite: notesFilter.base.isFavorite ?? tabFilter.isFavorite,
          isArchived: notesFilter.base.isArchived ?? tabFilter.isArchived,
          isDeleted: notesFilter.base.isDeleted ?? tabFilter.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ?? notesFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return notesFilter.copyWith(base: base);
      case EntityType.bankCard:
        final bankCardsFilter = ref.read(bankCardsFilterProvider);
        final base = bankCardsFilter.base.copyWith(
          isFavorite: bankCardsFilter.base.isFavorite ?? tabFilter.isFavorite,
          isArchived: bankCardsFilter.base.isArchived ?? tabFilter.isArchived,
          isDeleted: bankCardsFilter.base.isDeleted ?? tabFilter.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ??
              bankCardsFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return bankCardsFilter.copyWith(base: base);
      case EntityType.file:
        final filesFilter = ref.read(filesFilterProvider);
        final base = filesFilter.base.copyWith(
          isFavorite: filesFilter.base.isFavorite ?? tabFilter.isFavorite,
          isArchived: filesFilter.base.isArchived ?? tabFilter.isArchived,
          isDeleted: filesFilter.base.isDeleted ?? tabFilter.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ?? filesFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return filesFilter.copyWith(base: base);
      case EntityType.otp:
        final otpsFilter = ref.read(otpsFilterProvider);
        final base = otpsFilter.base.copyWith(
          isFavorite: otpsFilter.base.isFavorite ?? tabFilter.isFavorite,
          isArchived: otpsFilter.base.isArchived ?? tabFilter.isArchived,
          isDeleted: otpsFilter.base.isDeleted ?? tabFilter.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ?? otpsFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return otpsFilter.copyWith(base: base);
      case EntityType.document:
        final documentsFilter = ref.read(documentsFilterProvider);
        final base = documentsFilter.base.copyWith(
          isFavorite: documentsFilter.base.isFavorite ?? tabFilter.isFavorite,
          isArchived: documentsFilter.base.isArchived ?? tabFilter.isArchived,
          isDeleted: documentsFilter.base.isDeleted ?? tabFilter.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ??
              documentsFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return documentsFilter.copyWith(base: base);
      case EntityType.apiKey:
        final apiKeysFilter = ref.read(apiKeysFilterProvider);
        final base = apiKeysFilter.base.copyWith(
          isFavorite: apiKeysFilter.base.isFavorite ?? tabFilter.isFavorite,
          isArchived: apiKeysFilter.base.isArchived ?? tabFilter.isArchived,
          isDeleted: apiKeysFilter.base.isDeleted ?? tabFilter.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ?? apiKeysFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return apiKeysFilter.copyWith(base: base);
      case EntityType.sshKey:
        final sshKeysFilter = ref.read(sshKeysFilterProvider);
        final base = sshKeysFilter.base.copyWith(
          isFavorite: sshKeysFilter.base.isFavorite ?? tabFilter.isFavorite,
          isArchived: sshKeysFilter.base.isArchived ?? tabFilter.isArchived,
          isDeleted: sshKeysFilter.base.isDeleted ?? tabFilter.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ?? sshKeysFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return sshKeysFilter.copyWith(base: base);
      case EntityType.certificate:
        final certificatesFilter = ref.read(certificatesFilterProvider);
        final base = certificatesFilter.base.copyWith(
          isFavorite:
              certificatesFilter.base.isFavorite ?? tabFilter.isFavorite,
          isArchived:
              certificatesFilter.base.isArchived ?? tabFilter.isArchived,
          isDeleted: certificatesFilter.base.isDeleted ?? tabFilter.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ??
              certificatesFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return certificatesFilter.copyWith(base: base);
      case EntityType.cryptoWallet:
        final cryptoWalletsFilter = ref.read(cryptoWalletsFilterProvider);
        final base = cryptoWalletsFilter.base.copyWith(
          isFavorite:
              cryptoWalletsFilter.base.isFavorite ?? tabFilter.isFavorite,
          isArchived:
              cryptoWalletsFilter.base.isArchived ?? tabFilter.isArchived,
          isDeleted: cryptoWalletsFilter.base.isDeleted ?? tabFilter.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ??
              cryptoWalletsFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return cryptoWalletsFilter.copyWith(base: base);
      case EntityType.wifi:
        final wifisFilter = ref.read(wifisFilterProvider);
        final base = wifisFilter.base.copyWith(
          isFavorite: wifisFilter.base.isFavorite ?? tabFilter.isFavorite,
          isArchived: wifisFilter.base.isArchived ?? tabFilter.isArchived,
          isDeleted: wifisFilter.base.isDeleted ?? tabFilter.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ?? wifisFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return wifisFilter.copyWith(base: base);
      case EntityType.identity:
        final identitiesFilter = ref.read(identitiesFilterProvider);
        final base = identitiesFilter.base.copyWith(
          isFavorite: identitiesFilter.base.isFavorite ?? tabFilter.isFavorite,
          isArchived: identitiesFilter.base.isArchived ?? tabFilter.isArchived,
          isDeleted: identitiesFilter.base.isDeleted ?? tabFilter.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ??
              identitiesFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return identitiesFilter.copyWith(base: base);
      case EntityType.licenseKey:
        final licenseKeysFilter = ref.read(licenseKeysFilterProvider);
        final base = licenseKeysFilter.base.copyWith(
          isFavorite: licenseKeysFilter.base.isFavorite ?? tabFilter.isFavorite,
          isArchived: licenseKeysFilter.base.isArchived ?? tabFilter.isArchived,
          isDeleted: licenseKeysFilter.base.isDeleted ?? tabFilter.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ??
              licenseKeysFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return licenseKeysFilter.copyWith(base: base);
      case EntityType.recoveryCodes:
        final recoveryCodesFilter = ref.read(recoveryCodesFilterProvider);
        final base = recoveryCodesFilter.base.copyWith(
          isFavorite:
              recoveryCodesFilter.base.isFavorite ?? tabFilter.isFavorite,
          isArchived:
              recoveryCodesFilter.base.isArchived ?? tabFilter.isArchived,
          isDeleted: recoveryCodesFilter.base.isDeleted ?? tabFilter.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ??
              recoveryCodesFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return recoveryCodesFilter.copyWith(base: base);
    }
  }

  BaseFilter _getTabFilter(FilterTab tab) {
    switch (tab) {
      case FilterTab.all:
        return BaseFilter.create();
      case FilterTab.favorites:
        return BaseFilter.create(isFavorite: true);
      case FilterTab.frequent:
        return BaseFilter.create(isFrequentlyUsed: true);
      case FilterTab.archived:
        return BaseFilter.create(isArchived: true);
      case FilterTab.delete:
        return BaseFilter.create(isDeleted: true);
    }
  }

  Future<DashboardListState<BaseCardDto>> _loadInitialData() async {
    try {
      // Получаем DAO и делаем тестовую проверку (по аналогии с твоим кодом)
      final dao = await _daoForType();

      // Строим фильтр и подгружаем первую страницу
      final filter = _buildFilter(page: 1);

      // Предполагаю, что у DAO есть getFiltered<type> и countFiltered<type>.
      // Для унификации можно в DAO сделать общий метод getFiltered(filter) возвращающий List<dynamic>.
      final items = await dao.getFiltered(filter);
      final totalCount = await dao.countFiltered(filter);

      return DashboardListState<BaseCardDto>(
        items: items,
        isLoading: false,
        hasMore: items.length >= pageSize && items.length < totalCount,
        currentPage: 1,
        totalCount: totalCount,
      );
    } catch (e) {
      return DashboardListState(error: e.toString());
    }
  }

  /// loadMore аналогично твоему
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    try {
      state = AsyncValue.data(current.copyWith(isLoadingMore: true));
      final nextPage = current.currentPage + 1;
      final filter = _buildFilter(page: nextPage);
      final dao = await _daoForType();
      final newItems = await dao.getFiltered(filter);

      final all = [...current.items, ...newItems];
      final hasMore =
          newItems.length >= pageSize && all.length < current.totalCount;

      state = AsyncValue.data(
        current.copyWith(
          items: all,
          isLoadingMore: false,
          hasMore: hasMore,
          currentPage: nextPage,
        ),
      );
    } catch (e, st) {
      logError(
        'Error loading more items',
        tag: '${_logTag}PaginatedListNotifier',
        error: e,
        stackTrace: st,
      );
      state = AsyncValue.data(
        current.copyWith(isLoadingMore: false, error: e.toString()),
      );
    }
  }

  /// refresh
  Future<void> refresh() async {
    final cur = state.value;
    if (cur != null) {
      state = AsyncValue.data(cur.copyWith(isLoading: true));
      try {
        final newState = await _loadInitialData();
        state = AsyncValue.data(newState);
      } catch (e) {
        state = AsyncValue.data(
          cur.copyWith(isLoading: false, error: e.toString()),
        );
      }
    } else {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(_loadInitialData);
    }
  }

  /// Примеры операций (toggleFavorite / delete) — делаем через _serviceForType и адаптацию DTO
  Future<void> toggleFavorite(String id) async {
    if (_isUnsupportedEntity) return;
    final cur = state.value;
    if (cur == null) return;

    final index = cur.items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final item = cur.items[index];
    final newFav = !item.isFavorite;

    final updated = [...cur.items];
    updated[index] = item.copyWithBase(isFavorite: newFav);

    state = AsyncValue.data(cur.copyWith(items: updated));

    try {
      final dao = await ref.read(vaultItemDaoProvider.future);
      bool success = false;
      success = await dao.toggleFavorite(id, newFav);

      if (!success) {
        // откат
        updated[index] = item;
        state = AsyncValue.data(cur.copyWith(items: updated));
      } else {
        if (ref.read(filterTabProvider) == FilterTab.favorites && !newFav) {
          // Если мы на вкладке "Избранное" и элемент снят с избранного — удаляем его из списка
          updated.removeAt(index);
          state = AsyncValue.data(
            cur.copyWith(items: updated, totalCount: cur.totalCount - 1),
          );
        }
      }
    } catch (e) {
      // откат
      updated[index] = item;
      state = AsyncValue.data(cur.copyWith(items: updated));
    }
  }

  Future<void> togglePin(String id) async {
    if (_isUnsupportedEntity) return;
    final cur = state.value;
    if (cur == null) return;

    final index = cur.items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final item = cur.items[index];
    final newPin = !item.isPinned;

    final updated = [...cur.items];
    updated[index] = item.copyWithBase(isPinned: newPin);

    state = AsyncValue.data(cur.copyWith(items: updated));

    try {
      final dao = await ref.read(vaultItemDaoProvider.future);
      bool success = false;
      success = await dao.togglePin(id, newPin);

      if (!success) {
        // откат
        updated[index] = item;
        state = AsyncValue.data(cur.copyWith(items: updated));
      } else {
        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(entityType, entityId: id);
      }
    } catch (e) {
      // откат
      updated[index] = item;
      state = AsyncValue.data(cur.copyWith(items: updated));
    }
  }

  Future<void> toggleArchive(String id) async {
    if (_isUnsupportedEntity) return;
    final cur = state.value;
    if (cur == null) return;

    final index = cur.items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final item = cur.items[index];

    logDebug(
      'Toggling archive for item $id, current isArchived: $item',
      tag: '$_logTag toggleArchive',
    );
    final newArchive = !item.isArchived;

    final updated = [...cur.items];
    updated[index] = item.copyWithBase(isArchived: newArchive);

    state = AsyncValue.data(cur.copyWith(items: updated));

    logInfo(
      'Toggling archive for item $id to $newArchive',
      tag: '$_logTag toggleArchive',
    );

    try {
      final dao = await ref.read(vaultItemDaoProvider.future);
      bool success = false;
      success = await dao.toggleArchive(id, newArchive);

      logInfo(
        'Toggle archive result for item $id: $success',
        tag: '$_logTag toggleArchive',
      );

      if (!success) {
        // откат
        updated[index] = item;
        state = AsyncValue.data(cur.copyWith(items: updated));
      } else {
        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(entityType, entityId: id);
      }
    } catch (e) {
      // откат
      logError(
        'Error toggling archive',
        tag: '$_logTag toggleArchive',
        error: e,
      );
      updated[index] = item;
      state = AsyncValue.data(cur.copyWith(items: updated));
    }
  }

  Future<void> delete(String id) async {
    if (_isUnsupportedEntity) return;
    final cur = state.value;
    if (cur == null) return;

    final index = cur.items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final item = cur.items[index];
    final updated = [...cur.items];
    updated.removeAt(index);

    state = AsyncValue.data(
      cur.copyWith(items: updated, totalCount: cur.totalCount - 1),
    );

    try {
      final dao = await ref.read(vaultItemDaoProvider.future);
      bool success = false;
      success = await dao.softDelete(id);

      if (!success) {
        // откат
        updated.insert(index, item);
        state = AsyncValue.data(
          cur.copyWith(items: updated, totalCount: cur.totalCount + 1),
        );
      } else {
        // Триггерим обновление данных
        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(entityType, entityId: id);
      }
    } catch (e) {
      // откат
      updated.insert(index, item);
      state = AsyncValue.data(
        cur.copyWith(items: updated, totalCount: cur.totalCount + 1),
      );
    }
  }

  Future<void> restoreFromDeleted(String id) async {
    if (_isUnsupportedEntity) return;
    final cur = state.value;
    if (cur == null) return;

    final index = cur.items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final item = cur.items[index];
    final updated = [...cur.items];
    updated.removeAt(index);

    state = AsyncValue.data(
      cur.copyWith(items: updated, totalCount: cur.totalCount - 1),
    );

    try {
      final dao = await ref.read(vaultItemDaoProvider.future);
      bool success = false;
      success = await dao.restoreFromDeleted(id);

      if (!success) {
        // откат
        updated.insert(index, item);
        state = AsyncValue.data(
          cur.copyWith(items: updated, totalCount: cur.totalCount + 1),
        );
      } else {
        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(entityType, entityId: id);
      }
    } catch (e) {
      // откат
      updated.insert(index, item);
      state = AsyncValue.data(
        cur.copyWith(items: updated, totalCount: cur.totalCount + 1),
      );
    }
  }

  Future<void> permanentDelete(String id) async {
    if (_isUnsupportedEntity) return;
    final cur = state.value;
    if (cur == null) return;

    final index = cur.items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final item = cur.items[index];
    final updated = [...cur.items];
    updated.removeAt(index);

    state = AsyncValue.data(
      cur.copyWith(items: updated, totalCount: cur.totalCount - 1),
    );

    try {
      final dao = await ref.read(vaultItemDaoProvider.future);
      bool success = false;
      if (entityType == EntityType.file) {
        // Для файлов сначала удаляем все файлы истории, затем основной файл
        final fileService = await ref.read(fileStorageServiceProvider.future);
        final fileHistoryDao = await ref.read(fileHistoryDaoProvider.future);

        // Получаем все записи истории для файла
        final historyRecords = await fileHistoryDao.getFileHistoryByOriginalId(
          id,
        );

        // Удаляем файлы истории с диска
        for (final (_, fileRecord) in historyRecords) {
          // Получаем filePath из FileMetadata через metadataId
          if (fileRecord?.metadataId != null) {
            final fileDao = await ref.read(fileDaoProvider.future);
            final metadata =
                await (fileDao.attachedDatabase.select(
                      fileDao.attachedDatabase.fileMetadata,
                    )..where((m) => m.id.equals(fileRecord!.metadataId!)))
                    .getSingleOrNull();

            if (metadata != null && metadata.filePath != null) {
              await fileService.deleteHistoryFileFromDisk(metadata.filePath!);
            }
          }
        }

        // Удаляем записи истории из БД
        await fileHistoryDao.deleteFileHistoryByFileId(id);

        // Удаляем основной файл
        final fileDeleted = await fileService.deleteFileFromDisk(id);
        if (!fileDeleted) {
          logWarning(
            'Не удалось удалить основной файл с диска. Возможно файл уже был удалён ранее.',
            tag: '${_logTag}permanentDelete',
          );
        }

        // Удаляем запись из БД через общий DAO
        success = await dao.permanentDelete(id);
      } else {
        // Для остальных типов используем permanentDelete
        success = await dao.permanentDelete(id);
      }

      if (!success) {
        // откат
        updated.insert(index, item);
        state = AsyncValue.data(
          cur.copyWith(items: updated, totalCount: cur.totalCount),
        );
      } else {
        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityDelete(entityType, entityId: id);
      }
    } catch (e) {
      // откат
      updated.insert(index, item);
      state = AsyncValue.data(
        cur.copyWith(items: updated, totalCount: cur.totalCount + 1),
      );
    }
  }

  void _resetAndLoad() {
    state = const AsyncValue.loading();
    ref.invalidateSelf();
  }
}
