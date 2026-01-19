import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/data_refresh_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/drawer_filter_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/base_filter_provider.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

const int _kPageSize = 20;
const Duration _kSearchDebounce = Duration(milliseconds: 300);

/// Провайдер для управления состоянием фильтра в drawer
/// Family по EntityType для правильной фильтрации по типу
final drawerFilterProvider =
    AsyncNotifierProvider.family<
      DrawerFilterNotifier,
      DrawerFilterState,
      EntityType
    >(DrawerFilterNotifier.new);

class DrawerFilterNotifier extends AsyncNotifier<DrawerFilterState> {
  static const String _logTag = 'DrawerFilterNotifier';
  Timer? _categorySearchDebounce;
  Timer? _tagSearchDebounce;

  DrawerFilterNotifier(this._entityType);

  final EntityType _entityType;

  @override
  Future<DrawerFilterState> build() async {
    // Настраиваем очистку ресурсов
    ref.onDispose(() {
      _categorySearchDebounce?.cancel();
      _tagSearchDebounce?.cancel();
    });

    // Прослушиваем изменения в категориях и тегах СИНХРОННО до любых await
    ref.listen<DataRefreshState>(dataRefreshTriggerProvider, (previous, next) {
      logTrace(
        '$_logTag dataRefreshTriggerProvider изменился: '
        'previous=${previous?.toString() ?? 'null'}, next=${next.toString()}',
        tag: _logTag,
      );
      // Проверяем, что это изменение категорий или тегов
      final resourceType = next.data?['resourceType'];
      if (resourceType == 'category') {
        logDebug(
          '$_logTag Обнаружено изменение категорий (${next.type}), перезагружаем...',
          tag: _logTag,
        );
        _reloadCategories();
      } else if (resourceType == 'tag') {
        logDebug(
          '$_logTag Обнаружено изменение тегов (${next.type}), перезагружаем...',
          tag: _logTag,
        );
        _reloadTags();
      }
    });

    // Начальное состояние без сохранённого выбора
    var currentState = DrawerFilterState(
      selectedCategoryIds: [],
      selectedTagIds: [],
    );

    try {
      // Загружаем категории
      final categoryDao = await ref.read(categoryDaoProvider.future);
      final categoryFilter = CategoriesFilter.create(
        query: '',
        types: [_entityType.toCategoryType()],
        limit: _kPageSize,
        offset: 0,
      );
      final categories = await categoryDao.getCategoryCardsFiltered(
        categoryFilter,
      );

      currentState = currentState.copyWith(
        categories: categories,
        categoriesOffset: _kPageSize,
        hasMoreCategories: categories.length >= _kPageSize,
      );

      // Загружаем теги
      final tagDao = await ref.read(tagDaoProvider.future);
      final tagFilter = TagsFilter.create(
        query: '',
        types: [_entityType.toTagType()],
        limit: _kPageSize,
        offset: 0,
      );
      final tags = await tagDao.getTagCardsFiltered(tagFilter);

      currentState = currentState.copyWith(
        tags: tags,
        tagsOffset: _kPageSize,
        hasMoreTags: tags.length >= _kPageSize,
      );
    } catch (e, s) {
      logError(
        '$_logTag Ошибка загрузки начальных данных',
        error: e,
        stackTrace: s,
      );
    }

    return currentState;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Загрузка категорий
  // ─────────────────────────────────────────────────────────────────────────

  /// Перезагрузить категории (вызывается из listener)
  void _reloadCategories() {
    logDebug(
      '$_logTag _reloadCategories вызван, state.hasValue: ${state.hasValue}',
    );
    state.whenData((currentState) {
      logDebug(
        '$_logTag Перезагрузка категорий, текущее количество: ${currentState.categories.length}',
      );
      // Сбрасываем состояние и перезагружаем
      state = AsyncValue.data(
        currentState.copyWith(categorySearchQuery: '', categoriesOffset: 0),
      );
      _loadCategories(reset: true);
    });
  }

  Future<void> _loadCategories({bool reset = false}) async {
    final currentState = state.value;
    if (currentState == null || currentState.isCategoriesLoading) return;

    state = AsyncValue.data(currentState.copyWith(isCategoriesLoading: true));

    try {
      final categoryDao = await ref.read(categoryDaoProvider.future);
      final offset = reset ? 0 : currentState.categoriesOffset;

      final filter = CategoriesFilter.create(
        query: currentState.categorySearchQuery,
        types: [_entityType.toCategoryType()],
        limit: _kPageSize,
        offset: offset,
      );

      final categories = await categoryDao.getCategoryCardsFiltered(filter);

      logDebug(
        '$_logTag Загружено категорий: ${categories.length}, reset: $reset',
      );

      if (reset) {
        state = AsyncValue.data(
          currentState.copyWith(
            categories: categories,
            categoriesOffset: _kPageSize,
            hasMoreCategories: categories.length >= _kPageSize,
            isCategoriesLoading: false,
          ),
        );
      } else {
        state = AsyncValue.data(
          currentState.copyWith(
            categories: [...currentState.categories, ...categories],
            categoriesOffset: offset + _kPageSize,
            hasMoreCategories: categories.length >= _kPageSize,
            isCategoriesLoading: false,
          ),
        );
      }
    } catch (e, s) {
      logError('$_logTag Ошибка загрузки категорий', error: e, stackTrace: s);
      state = AsyncValue.data(
        currentState.copyWith(isCategoriesLoading: false),
      );
    }
  }

  /// Загрузить следующую страницу категорий
  Future<void> loadMoreCategories() async {
    final currentState = state.value;
    if (currentState == null ||
        !currentState.hasMoreCategories ||
        currentState.isCategoriesLoading)
      return;
    await _loadCategories(reset: false);
  }

  /// Поиск категорий с дебаунсингом
  void searchCategories(String query) {
    _categorySearchDebounce?.cancel();
    _categorySearchDebounce = Timer(_kSearchDebounce, () {
      state.whenData((currentState) {
        state = AsyncValue.data(
          currentState.copyWith(categorySearchQuery: query),
        );
        _loadCategories(reset: true);
      });
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Загрузка тегов
  // ─────────────────────────────────────────────────────────────────────────

  /// Перезагрузить теги (вызывается из listener)
  void _reloadTags() {
    logDebug('$_logTag _reloadTags вызван, state.hasValue: ${state.hasValue}');
    state.whenData((currentState) {
      logDebug(
        '$_logTag Перезагрузка тегов, текущее количество: ${currentState.tags.length}',
      );
      // Сбрасываем состояние и перезагружаем
      state = AsyncValue.data(
        currentState.copyWith(tagSearchQuery: '', tagsOffset: 0),
      );
      _loadTags(reset: true);
    });
  }

  Future<void> _loadTags({bool reset = false}) async {
    final currentState = state.value;
    if (currentState == null || currentState.isTagsLoading) return;

    state = AsyncValue.data(currentState.copyWith(isTagsLoading: true));

    try {
      final tagDao = await ref.read(tagDaoProvider.future);
      final offset = reset ? 0 : currentState.tagsOffset;

      final filter = TagsFilter.create(
        query: currentState.tagSearchQuery,
        types: [_entityType.toTagType()],
        limit: _kPageSize,
        offset: offset,
      );

      final tags = await tagDao.getTagCardsFiltered(filter);

      logDebug('$_logTag Загружено тегов: ${tags.length}, reset: $reset');

      if (reset) {
        state = AsyncValue.data(
          currentState.copyWith(
            tags: tags,
            tagsOffset: _kPageSize,
            hasMoreTags: tags.length >= _kPageSize,
            isTagsLoading: false,
          ),
        );
      } else {
        state = AsyncValue.data(
          currentState.copyWith(
            tags: [...currentState.tags, ...tags],
            tagsOffset: offset + _kPageSize,
            hasMoreTags: tags.length >= _kPageSize,
            isTagsLoading: false,
          ),
        );
      }
    } catch (e, s) {
      logError('$_logTag Ошибка загрузки тегов', error: e, stackTrace: s);
      state = AsyncValue.data(currentState.copyWith(isTagsLoading: false));
    }
  }

  /// Загрузить следующую страницу тегов
  Future<void> loadMoreTags() async {
    final currentState = state.value;
    if (currentState == null ||
        !currentState.hasMoreTags ||
        currentState.isTagsLoading)
      return;
    await _loadTags(reset: false);
  }

  /// Поиск тегов с дебаунсингом
  void searchTags(String query) {
    _tagSearchDebounce?.cancel();
    _tagSearchDebounce = Timer(_kSearchDebounce, () {
      state.whenData((currentState) {
        state = AsyncValue.data(currentState.copyWith(tagSearchQuery: query));
        _loadTags(reset: true);
      });
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Выбор категорий и тегов
  // ─────────────────────────────────────────────────────────────────────────

  /// Переключить выбор категории
  void toggleCategory(String categoryId) {
    state.whenData((currentState) {
      final selected = currentState.selectedCategoryIds;
      final newSelected = selected.contains(categoryId)
          ? selected.where((id) => id != categoryId).toList()
          : [...selected, categoryId];

      state = AsyncValue.data(
        currentState.copyWith(selectedCategoryIds: newSelected),
      );

      _applyFilterToBase();
    });
  }

  /// Переключить выбор тега
  void toggleTag(String tagId) {
    state.whenData((currentState) {
      final selected = currentState.selectedTagIds;
      final newSelected = selected.contains(tagId)
          ? selected.where((id) => id != tagId).toList()
          : [...selected, tagId];

      state = AsyncValue.data(
        currentState.copyWith(selectedTagIds: newSelected),
      );

      _applyFilterToBase();
    });
  }

  /// Очистить выбранные категории
  void clearCategories() {
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(selectedCategoryIds: []));

      _applyFilterToBase();
    });
  }

  /// Очистить выбранные теги
  void clearTags() {
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(selectedTagIds: []));

      _applyFilterToBase();
    });
  }

  /// Очистить все фильтры
  void clearAll() {
    state.whenData((currentState) {
      state = AsyncValue.data(
        currentState.copyWith(selectedCategoryIds: [], selectedTagIds: []),
      );

      _applyFilterToBase();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Применение фильтра
  // ─────────────────────────────────────────────────────────────────────────

  /// Применить выбранные фильтры к baseFilterProvider
  void _applyFilterToBase() {
    state.whenData((currentState) {
      final baseFilter = ref.read(baseFilterProvider.notifier);
      // Устанавливаем фильтры для текущей сущности
      // (очистка происходит автоматически в setEntityType при смене сущности)
      baseFilter.setCategoryIds(currentState.selectedCategoryIds);
      baseFilter.setTagIds(currentState.selectedTagIds);
    });
  }
}
