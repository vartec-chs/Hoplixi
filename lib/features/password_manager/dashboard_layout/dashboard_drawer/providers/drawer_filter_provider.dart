import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/filter_providers.dart';
import 'package:hoplixi/features/password_manager/dashboard_layout/dashboard_drawer/models/drawer_filter_state.dart';
import 'package:hoplixi/features/password_manager/managers/providers/manager_refresh_trigger_provider.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/category_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/tag_dto.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';

const int _kPageSize = 20;
const Duration _kSearchDebounce = Duration(milliseconds: 300);

final drawerFilterProvider = AsyncNotifierProvider.autoDispose
    .family<DrawerFilterNotifier, DrawerFilterState, EntityType>(
      DrawerFilterNotifier.new,
    );

class DrawerFilterNotifier extends AsyncNotifier<DrawerFilterState> {
  static const String _logTag = 'DrawerFilterNotifier';
  Timer? _categorySearchDebounce;
  Timer? _tagSearchDebounce;
  List<CategoryCardDto> _allCategories = const [];
  List<TagCardDto> _allTags = const [];

  DrawerFilterNotifier(EntityType _);

  @override
  Future<DrawerFilterState> build() async {
    ref.onDispose(() {
      _categorySearchDebounce?.cancel();
      _tagSearchDebounce?.cancel();
    });

    ref.listen<ManagerRefreshState>(managerRefreshTriggerProvider, (
      previous,
      next,
    ) {
      final resourceType = next.resourceType;
      if (resourceType == ManagerResourceType.category) {
        logDebug(
          '$_logTag Обнаружено изменение категорий, перезагружаем...',
          tag: _logTag,
        );
        _reloadCategories();
      } else if (resourceType == ManagerResourceType.tag) {
        logDebug(
          '$_logTag Обнаружено изменение тегов, перезагружаем...',
          tag: _logTag,
        );
        _reloadTags();
      }
    });

    var currentState = const DrawerFilterState(
      selectedCategoryIds: [],
      selectedTagIds: [],
    );

    try {
      await _refreshCategories();
      final categories = _sliceCategories(offset: 0, query: '');
      currentState = currentState.copyWith(
        categories: categories,
        categoriesOffset: categories.length,
        hasMoreCategories: categories.length < _filteredCategories('').length,
      );

      await _refreshTags();
      final tags = _sliceTags(offset: 0, query: '');
      currentState = currentState.copyWith(
        tags: tags,
        tagsOffset: tags.length,
        hasMoreTags: tags.length < _filteredTags('').length,
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

  Future<void> _refreshCategories() async {
    final repositories = await ref.read(vaultRepositories.future);
    final categories = (await repositories.category.getAllCategories())
        .getOrThrow()
      ..sort((a, b) => a.name.compareTo(b.name));
    _allCategories = categories;
  }

  Future<void> _refreshTags() async {
    final repositories = await ref.read(vaultRepositories.future);
    final tags = (await repositories.tag.getAllTags()).getOrThrow()
      ..sort((a, b) => a.name.compareTo(b.name));
    _allTags = tags;
  }

  List<CategoryCardDto> _filteredCategories(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return _allCategories;
    return _allCategories
        .where((category) => category.name.toLowerCase().contains(normalized))
        .toList(growable: false);
  }

  List<TagCardDto> _filteredTags(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return _allTags;
    return _allTags
        .where((tag) => tag.name.toLowerCase().contains(normalized))
        .toList(growable: false);
  }

  List<CategoryCardDto> _sliceCategories({
    required int offset,
    required String query,
  }) {
    final categories = _filteredCategories(query);
    final end = (offset + _kPageSize).clamp(0, categories.length);
    if (offset >= end) return const [];
    return categories.sublist(offset, end);
  }

  List<TagCardDto> _sliceTags({
    required int offset,
    required String query,
  }) {
    final tags = _filteredTags(query);
    final end = (offset + _kPageSize).clamp(0, tags.length);
    if (offset >= end) return const [];
    return tags.sublist(offset, end);
  }

  void _reloadCategories() {
    state.whenData((currentState) {
      state = AsyncValue.data(
        currentState.copyWith(categorySearchQuery: '', categoriesOffset: 0),
      );
      _loadCategories(reset: true);
    });
  }

  void reloadCategories() {
    _reloadCategories();
  }

  Future<void> _loadCategories({bool reset = false}) async {
    final currentState = state.value;
    if (currentState == null || currentState.isCategoriesLoading) return;

    state = AsyncValue.data(currentState.copyWith(isCategoriesLoading: true));

    try {
      if (reset) await _refreshCategories();

      final offset = reset ? 0 : currentState.categoriesOffset;
      final categories = _sliceCategories(
        offset: offset,
        query: currentState.categorySearchQuery,
      );
      final total = _filteredCategories(currentState.categorySearchQuery).length;

      logDebug(
        '$_logTag Загружено категорий: ${categories.length}, reset: $reset',
      );

      if (reset) {
        state = AsyncValue.data(
          currentState.copyWith(
            categories: categories,
            categoriesOffset: categories.length,
            hasMoreCategories: categories.length < total,
            isCategoriesLoading: false,
          ),
        );
      } else {
        state = AsyncValue.data(
          currentState.copyWith(
            categories: [...currentState.categories, ...categories],
            categoriesOffset: offset + categories.length,
            hasMoreCategories: offset + categories.length < total,
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

  Future<void> loadMoreCategories() async {
    final currentState = state.value;
    if (currentState == null ||
        !currentState.hasMoreCategories ||
        currentState.isCategoriesLoading) {
      return;
    }
    await _loadCategories(reset: false);
  }

  void searchCategories(String query) {
    _categorySearchDebounce?.cancel();
    _categorySearchDebounce = Timer(_kSearchDebounce, () {
      state.whenData((currentState) {
        state = AsyncValue.data(
          currentState.copyWith(
            categorySearchQuery: query.trim(),
            categoriesOffset: 0,
          ),
        );
        _loadCategories(reset: true);
      });
    });
  }

  void _reloadTags() {
    state.whenData((currentState) {
      state = AsyncValue.data(
        currentState.copyWith(tagSearchQuery: '', tagsOffset: 0),
      );
      _loadTags(reset: true);
    });
  }

  void reloadTags() {
    _reloadTags();
  }

  Future<void> _loadTags({bool reset = false}) async {
    final currentState = state.value;
    if (currentState == null || currentState.isTagsLoading) return;

    state = AsyncValue.data(currentState.copyWith(isTagsLoading: true));

    try {
      if (reset) await _refreshTags();

      final offset = reset ? 0 : currentState.tagsOffset;
      final tags = _sliceTags(offset: offset, query: currentState.tagSearchQuery);
      final total = _filteredTags(currentState.tagSearchQuery).length;

      logDebug('$_logTag Загружено тегов: ${tags.length}, reset: $reset');

      if (reset) {
        state = AsyncValue.data(
          currentState.copyWith(
            tags: tags,
            tagsOffset: tags.length,
            hasMoreTags: tags.length < total,
            isTagsLoading: false,
          ),
        );
      } else {
        state = AsyncValue.data(
          currentState.copyWith(
            tags: [...currentState.tags, ...tags],
            tagsOffset: offset + tags.length,
            hasMoreTags: offset + tags.length < total,
            isTagsLoading: false,
          ),
        );
      }
    } catch (e, s) {
      logError('$_logTag Ошибка загрузки тегов', error: e, stackTrace: s);
      state = AsyncValue.data(currentState.copyWith(isTagsLoading: false));
    }
  }

  Future<void> loadMoreTags() async {
    final currentState = state.value;
    if (currentState == null ||
        !currentState.hasMoreTags ||
        currentState.isTagsLoading) {
      return;
    }
    await _loadTags(reset: false);
  }

  void searchTags(String query) {
    _tagSearchDebounce?.cancel();
    _tagSearchDebounce = Timer(_kSearchDebounce, () {
      state.whenData((currentState) {
        state = AsyncValue.data(
          currentState.copyWith(tagSearchQuery: query.trim(), tagsOffset: 0),
        );
        _loadTags(reset: true);
      });
    });
  }

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

  void clearCategories() {
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(selectedCategoryIds: []));
      _applyFilterToBase();
    });
  }

  void clearTags() {
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(selectedTagIds: []));
      _applyFilterToBase();
    });
  }

  void clearAll() {
    state.whenData((currentState) {
      state = AsyncValue.data(
        currentState.copyWith(selectedCategoryIds: [], selectedTagIds: []),
      );
      _applyFilterToBase();
    });
  }

  void _applyFilterToBase() {
    state.whenData((currentState) {
      final baseFilter = ref.read(baseFilterProvider.notifier);
      baseFilter.setCategoryIds(currentState.selectedCategoryIds);
      baseFilter.setTagIds(currentState.selectedTagIds);
    });
  }
}
