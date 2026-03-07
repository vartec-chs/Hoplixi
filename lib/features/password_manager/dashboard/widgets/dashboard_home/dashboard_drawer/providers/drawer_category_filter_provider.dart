import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/base_filter_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer/models/drawer_category_filter_state.dart';
import 'package:hoplixi/features/password_manager/managers/providers/manager_refresh_trigger_provider.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

const int _kCategoryPageSize = 20;
const Duration _kCategorySearchDebounce = Duration(milliseconds: 300);

/// Провайдер для загрузки и фильтрации категорий в drawer
/// Family по EntityType — отдельный экземпляр для каждого типа сущности
final drawerCategoryFilterProvider =
    AsyncNotifierProvider.family<
      DrawerCategoryFilterNotifier,
      DrawerCategoryFilterState,
      EntityType
    >(DrawerCategoryFilterNotifier.new);

class DrawerCategoryFilterNotifier
    extends AsyncNotifier<DrawerCategoryFilterState> {
  static const String _logTag = 'DrawerCategoryFilterNotifier';
  Timer? _searchDebounce;

  DrawerCategoryFilterNotifier(this._entityType);

  final EntityType _entityType;

  @override
  Future<DrawerCategoryFilterState> build() async {
    ref.onDispose(() => _searchDebounce?.cancel());

    ref.listen<ManagerRefreshState>(managerRefreshTriggerProvider, (
      previous,
      next,
    ) {
      if (next.resourceType == ManagerResourceType.category) {
        logDebug(
          '$_logTag Обнаружено изменение категорий, перезагружаем...',
          tag: _logTag,
        );
        _reload();
      }
    });

    try {
      final categoryDao = await ref.read(categoryDaoProvider.future);
      final filter = CategoriesFilter.create(
        query: '',
        types: [_entityType.toCategoryType(), CategoryType.mixed],
        limit: _kCategoryPageSize,
        offset: 0,
      );
      final categories = await categoryDao.getCategoryCardsFiltered(filter);
      return DrawerCategoryFilterState(
        categories: categories,
        offset: _kCategoryPageSize,
        hasMore: categories.length >= _kCategoryPageSize,
      );
    } catch (e, s) {
      logError(
        '$_logTag Ошибка загрузки начальных данных',
        error: e,
        stackTrace: s,
      );
      return const DrawerCategoryFilterState();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Загрузка данных
  // ─────────────────────────────────────────────────────────────────────────

  void _reload() {
    state.whenData((s) {
      state = AsyncValue.data(s.copyWith(searchQuery: '', offset: 0));
      _load(reset: true);
    });
  }

  void reload() => _reload();

  Future<void> _load({bool reset = false}) async {
    final s = state.value;
    if (s == null || s.isLoading) return;

    state = AsyncValue.data(s.copyWith(isLoading: true));

    try {
      final categoryDao = await ref.read(categoryDaoProvider.future);
      final offset = reset ? 0 : s.offset;
      final filter = CategoriesFilter.create(
        query: s.searchQuery,
        types: [_entityType.toCategoryType(), CategoryType.mixed],
        limit: _kCategoryPageSize,
        offset: offset,
      );
      final categories = await categoryDao.getCategoryCardsFiltered(filter);

      logDebug(
        '$_logTag Загружено категорий: ${categories.length}, reset: $reset',
      );

      if (reset) {
        state = AsyncValue.data(
          s.copyWith(
            categories: categories,
            offset: _kCategoryPageSize,
            hasMore: categories.length >= _kCategoryPageSize,
            isLoading: false,
          ),
        );
      } else {
        state = AsyncValue.data(
          s.copyWith(
            categories: [...s.categories, ...categories],
            offset: offset + _kCategoryPageSize,
            hasMore: categories.length >= _kCategoryPageSize,
            isLoading: false,
          ),
        );
      }
    } catch (e, st) {
      logError('$_logTag Ошибка загрузки категорий', error: e, stackTrace: st);
      state = AsyncValue.data(s.copyWith(isLoading: false));
    }
  }

  Future<void> loadMore() async {
    final s = state.value;
    if (s == null || !s.hasMore || s.isLoading) return;
    await _load(reset: false);
  }

  void search(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_kCategorySearchDebounce, () {
      state.whenData((s) {
        state = AsyncValue.data(s.copyWith(searchQuery: query));
        _load(reset: true);
      });
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Выбор категорий
  // ─────────────────────────────────────────────────────────────────────────

  void toggle(String id) {
    state.whenData((s) {
      final selected = s.selectedIds;
      final updated = selected.contains(id)
          ? selected.where((e) => e != id).toList()
          : [...selected, id];
      state = AsyncValue.data(s.copyWith(selectedIds: updated));
      _applyToBase();
    });
  }

  void clearSelection() {
    state.whenData((s) {
      state = AsyncValue.data(s.copyWith(selectedIds: []));
      _applyToBase();
    });
  }

  void _applyToBase() {
    state.whenData((s) {
      ref.read(baseFilterProvider.notifier).setCategoryIds(s.selectedIds);
    });
  }
}
