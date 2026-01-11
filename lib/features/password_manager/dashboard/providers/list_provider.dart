import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/data_refresh_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/list_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/index.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_tab_provider.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
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
  ProviderSubscription<DataRefreshState>? _passwordRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _noteRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _bankCardRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _fileRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _otpRefreshSubscription;

  int get pageSize {
    // можно иметь разный pageSize для разных типов, если нужно
    return kDefaultPageSize;
  }

  final String _logTag = 'DashboardListProvider: ';

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
    }
  }

  /// Выбор CRUD DAO по type для обновлений
  Future<BaseMainEntityDao> _crudDaoForType() {
    switch (entityType) {
      case EntityType.password:
        return ref.read(passwordDaoProvider.future);
      case EntityType.note:
        return ref.read(noteDaoProvider.future);
      case EntityType.bankCard:
        return ref.read(bankCardDaoProvider.future);
      case EntityType.file:
        return ref.read(fileDaoProvider.future);
      case EntityType.otp:
        return ref.read(otpDaoProvider.future);
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
      final dao = await _crudDaoForType();
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
      final dao = await _crudDaoForType();
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
    final cur = state.value;
    if (cur == null) return;

    final index = cur.items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final item = cur.items[index];

    logDebug(
      'Toggling archive for item $id, current isArchived: ${item}',
      tag: '${_logTag} toggleArchive',
    );
    final newArchive = !item.isArchived;

    final updated = [...cur.items];
    updated[index] = item.copyWithBase(isArchived: newArchive);

    state = AsyncValue.data(cur.copyWith(items: updated));

    logInfo(
      'Toggling archive for item $id to $newArchive',
      tag: '${_logTag} toggleArchive',
    );

    try {
      final dao = await _crudDaoForType();
      bool success = false;
      success = await dao.toggleArchive(id, newArchive);

      logInfo(
        'Toggle archive result for item $id: $success',
        tag: '${_logTag} toggleArchive',
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
        tag: '${_logTag} toggleArchive',
        error: e,
      );
      updated[index] = item;
      state = AsyncValue.data(cur.copyWith(items: updated));
    }
  }

  Future<void> delete(String id) async {
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
      final dao = await _crudDaoForType();
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
      final dao = await _crudDaoForType();
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
      final dao = await _crudDaoForType();
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
        for (final record in historyRecords) {
          await fileService.deleteHistoryFileFromDisk(record.filePath);
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

        // Удаляем запись из БД
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
