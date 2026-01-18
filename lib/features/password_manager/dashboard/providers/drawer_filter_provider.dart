import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/drawer_filter_selection_storage.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/drawer_filter_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/base_filter_provider.dart';
import 'package:hoplixi/main_store/models/filter/categories_filter.dart';
import 'package:hoplixi/main_store/models/filter/tags_filter.dart';
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

    // Загружаем сохранённый выбор для этой сущности
    final storage = ref.read(drawerFilterSelectionStorageProvider.notifier);
    final savedSelection = storage.getSelection(_entityType);

    // Начальное состояние с сохранённым выбором
    var currentState = DrawerFilterState(
      selectedCategoryIds: savedSelection.selectedCategoryIds,
      selectedTagIds: savedSelection.selectedTagIds,
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

      // Сохраняем выбор в хранилище
      ref
          .read(drawerFilterSelectionStorageProvider.notifier)
          .setCategoryIds(_entityType, newSelected);

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

      // Сохраняем выбор в хранилище
      ref
          .read(drawerFilterSelectionStorageProvider.notifier)
          .setTagIds(_entityType, newSelected);

      _applyFilterToBase();
    });
  }

  /// Очистить выбранные категории
  void clearCategories() {
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(selectedCategoryIds: []));

      // Сохраняем очистку в хранилище
      ref
          .read(drawerFilterSelectionStorageProvider.notifier)
          .setCategoryIds(_entityType, []);

      _applyFilterToBase();
    });
  }

  /// Очистить выбранные теги
  void clearTags() {
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(selectedTagIds: []));

      // Сохраняем очистку в хранилище
      ref
          .read(drawerFilterSelectionStorageProvider.notifier)
          .setTagIds(_entityType, []);

      _applyFilterToBase();
    });
  }

  /// Очистить все фильтры
  void clearAll() {
    state.whenData((currentState) {
      state = AsyncValue.data(
        currentState.copyWith(selectedCategoryIds: [], selectedTagIds: []),
      );

      // Сохраняем полную очистку в хранилище
      ref
          .read(drawerFilterSelectionStorageProvider.notifier)
          .clearSelection(_entityType);

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
      // Очищаем старые фильтры перед установкой новых
      baseFilter.clearCategories();
      baseFilter.clearTags();
      // Устанавливаем новые фильтры для текущей сущности
      baseFilter.setCategoryIds(currentState.selectedCategoryIds);
      baseFilter.setTagIds(currentState.selectedTagIds);
    });
  }
}
