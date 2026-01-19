import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';

/// Провайдер для управления базовым фильтром
final baseFilterProvider = NotifierProvider<BaseFilterNotifier, BaseFilter>(
  BaseFilterNotifier.new,
);

class BaseFilterNotifier extends Notifier<BaseFilter> {
  static const String _logTag = 'BaseFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  /// Текущий тип сущности (для автоматического сброса фильтров)
  String? _currentEntityTypeId;

  @override
  BaseFilter build() {
    logDebug('Инициализация базового фильтра', tag: _logTag);

    // Очищаем таймер при dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return const BaseFilter();
  }

  /// Установить тип сущности и сбросить фильтры категорий/тегов при смене
  void setEntityType(String entityTypeId) {
    if (_currentEntityTypeId != entityTypeId) {
      logDebug(
        'Смена сущности: $_currentEntityTypeId -> $entityTypeId. Сброс фильтров категорий и тегов',
        tag: _logTag,
      );
      _currentEntityTypeId = entityTypeId;
      // Сбрасываем только фильтры категорий и тегов
      state = state.copyWith(categoryIds: [], tagIds: []);
    }
  }

  // set state
  void setState(BaseFilter newState) {
    state = newState;
  }

  // ============================================================================
  // Методы поиска и фильтрации
  // ============================================================================

  /// Обновить поисковый запрос с дебаунсингом
  void updateQuery(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление запроса: "$query"', tag: _logTag);
      state = state.copyWith(query: query);
    });
  }

  /// Обновить поисковый запрос без дебаунсинга
  void setQuery(String query) {
    _debounceTimer?.cancel();
    logDebug('Установка запроса: "$query"', tag: _logTag);
    state = state.copyWith(query: query);
  }

  /// Добавить ID категории в фильтр
  void addCategoryId(String categoryId) {
    if (state.categoryIds.contains(categoryId)) return;
    final updated = [...state.categoryIds, categoryId];
    logDebug('Добавлена категория: $categoryId', tag: _logTag);
    state = state.copyWith(categoryIds: updated);
  }

  /// Удалить ID категории из фильтра
  void removeCategoryId(String categoryId) {
    final updated = state.categoryIds.where((id) => id != categoryId).toList();
    logDebug('Удалена категория: $categoryId', tag: _logTag);
    state = state.copyWith(categoryIds: updated);
  }

  /// Установить категории (заменить все)
  void setCategoryIds(List<String> categoryIds) {
    logDebug('Установлены категории: $categoryIds', tag: _logTag);
    state = state.copyWith(categoryIds: categoryIds);
  }

  /// Очистить фильтр категорий
  void clearCategories() {
    logDebug('Очищены категории', tag: _logTag);
    state = state.copyWith(categoryIds: []);
  }

  /// Добавить ID тега в фильтр
  void addTagId(String tagId) {
    if (state.tagIds.contains(tagId)) return;
    final updated = [...state.tagIds, tagId];
    logDebug('Добавлен тег: $tagId', tag: _logTag);
    state = state.copyWith(tagIds: updated);
  }

  /// Удалить ID тега из фильтра
  void removeTagId(String tagId) {
    final updated = state.tagIds.where((id) => id != tagId).toList();
    logDebug('Удален тег: $tagId', tag: _logTag);
    state = state.copyWith(tagIds: updated);
  }

  /// Установить теги (заменить все)
  void setTagIds(List<String> tagIds) {
    logDebug('Установлены теги: $tagIds', tag: _logTag);
    state = state.copyWith(tagIds: tagIds);
  }

  /// Очистить фильтр тегов
  void clearTags() {
    logDebug('Очищены теги', tag: _logTag);
    state = state.copyWith(tagIds: []);
  }

  // ============================================================================
  // Методы фильтрации статуса
  // ============================================================================

  /// Установить фильтр избранного
  void setFavorite(bool? isFavorite) {
    logDebug('Фильтр избранного установлен: $isFavorite', tag: _logTag);
    state = state.copyWith(isFavorite: isFavorite);
  }

  /// Установить фильтр архива
  void setArchived(bool? isArchived) {
    logDebug('Фильтр архива установлен: $isArchived', tag: _logTag);
    state = state.copyWith(isArchived: isArchived);
  }

  /// Установить фильтр удаленных
  void setDeleted(bool? isDeleted) {
    logDebug('Фильтр удаленных установлен: $isDeleted', tag: _logTag);
    state = state.copyWith(isDeleted: isDeleted);
  }

  /// Установить фильтр закрепленных
  void setPinned(bool? isPinned) {
    logDebug('Фильтр закрепленных установлен: $isPinned', tag: _logTag);
    state = state.copyWith(isPinned: isPinned);
  }

  /// Установить фильтр наличия заметок
  void setHasNotes(bool? hasNotes) {
    logDebug('Фильтр заметок установлен: $hasNotes', tag: _logTag);
    state = state.copyWith(hasNotes: hasNotes);
  }

  // ============================================================================
  // Методы фильтрации по датам
  // ============================================================================

  /// Установить фильтр по дате создания (с)
  void setCreatedAfter(DateTime? date) {
    logDebug('Дата создания от: $date', tag: _logTag);
    state = state.copyWith(createdAfter: date);
  }

  /// Установить фильтр по дате создания (по)
  void setCreatedBefore(DateTime? date) {
    logDebug('Дата создания по: $date', tag: _logTag);
    state = state.copyWith(createdBefore: date);
  }

  /// Установить диапазон дат создания
  void setCreatedDateRange(DateTime? after, DateTime? before) {
    logDebug('Диапазон создания: $after - $before', tag: _logTag);
    state = state.copyWith(createdAfter: after, createdBefore: before);
  }

  /// Установить фильтр по дате изменения (с)
  void setModifiedAfter(DateTime? date) {
    logDebug('Дата изменения от: $date', tag: _logTag);
    state = state.copyWith(modifiedAfter: date);
  }

  /// Установить фильтр по дате изменения (по)
  void setModifiedBefore(DateTime? date) {
    logDebug('Дата изменения по: $date', tag: _logTag);
    state = state.copyWith(modifiedBefore: date);
  }

  /// Установить диапазон дат изменения
  void setModifiedDateRange(DateTime? after, DateTime? before) {
    logDebug('Диапазон изменения: $after - $before', tag: _logTag);
    state = state.copyWith(modifiedAfter: after, modifiedBefore: before);
  }

  /// Установить фильтр по дате последнего доступа (с)
  void setLastAccessedAfter(DateTime? date) {
    logDebug('Последний доступ от: $date', tag: _logTag);
    state = state.copyWith(lastUsedAfter: date);
  }

  /// Установить фильтр по дате последнего доступа (по)
  void setLastAccessedBefore(DateTime? date) {
    logDebug('Последний доступ по: $date', tag: _logTag);
    state = state.copyWith(lastUsedBefore: date);
  }

  /// Установить диапазон дат последнего доступа
  void setLastAccessedDateRange(DateTime? after, DateTime? before) {
    logDebug('Диапазон последнего доступа: $after - $before', tag: _logTag);
    state = state.copyWith(lastUsedAfter: after, lastUsedBefore: before);
  }

  // ============================================================================
  // Методы фильтрации по количеству использований
  // ============================================================================

  /// Установить минимальное количество использований
  void setMinUsedCount(int? count) {
    logDebug('Минимум использований: $count', tag: _logTag);
    state = state.copyWith(minUsedCount: count);
  }

  /// Установить максимальное количество использований
  void setMaxUsedCount(int? count) {
    logDebug('Максимум использований: $count', tag: _logTag);
    state = state.copyWith(maxUsedCount: count);
  }

  /// Установить диапазон использований
  void setUsedCountRange(int? minCount, int? maxCount) {
    logDebug('Диапазон использований: $minCount - $maxCount', tag: _logTag);
    state = state.copyWith(minUsedCount: minCount, maxUsedCount: maxCount);
  }

  // ============================================================================
  // Методы сортировки и пагинации
  // ============================================================================

  /// Установить направление сортировки
  void setSortDirection(SortDirection direction) {
    logDebug('Направление сортировки: $direction', tag: _logTag);
    state = state.copyWith(sortDirection: direction);
  }

  /// Переключить направление сортировки
  void toggleSortDirection() {
    final newDirection = state.sortDirection == SortDirection.asc
        ? SortDirection.desc
        : SortDirection.asc;
    logDebug('Переключение сортировки на: $newDirection', tag: _logTag);
    state = state.copyWith(sortDirection: newDirection);
  }

  /// Установить лимит и offset (пагинация)
  void setPagination(int limit, int offset) {
    logDebug(
      'Пагинация установлена: limit=$limit, offset=$offset',
      tag: _logTag,
    );
    state = state.copyWith(limit: limit, offset: offset);
  }

  /// Установить лимит
  void setLimit(int limit) {
    logDebug('Лимит установлен: $limit', tag: _logTag);
    state = state.copyWith(limit: limit);
  }

  /// Установить offset
  void setOffset(int offset) {
    logDebug('Offset установлен: $offset', tag: _logTag);
    state = state.copyWith(offset: offset);
  }

  // ============================================================================
  // Методы управления фильтром в целом
  // ============================================================================

  /// Проверить есть ли активные фильтры
  bool get hasActiveConstraints => state.hasActiveConstraints;

  /// Получить текущий фильтр
  BaseFilter get currentFilter => state;

  /// Получить копию фильтра с изменениями
  BaseFilter copyFilter({
    String? query,
    List<String>? categoryIds,
    List<String>? tagIds,
    bool? isFavorite,
    bool? isArchived,
    bool? isDeleted,
    bool? isPinned,
    bool? hasNotes,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    DateTime? lastUsedAfter,
    DateTime? lastUsedBefore,
    SortDirection? sortDirection,
    int? minUsedCount,
    int? maxUsedCount,
    int? limit,
    int? offset,
  }) {
    return state.copyWith(
      query: query ?? state.query,
      categoryIds: categoryIds ?? state.categoryIds,
      tagIds: tagIds ?? state.tagIds,
      isFavorite: isFavorite ?? state.isFavorite,
      isArchived: isArchived ?? state.isArchived,
      isDeleted: isDeleted ?? state.isDeleted,
      isPinned: isPinned ?? state.isPinned,
      hasNotes: hasNotes ?? state.hasNotes,
      createdAfter: createdAfter ?? state.createdAfter,
      createdBefore: createdBefore ?? state.createdBefore,
      modifiedAfter: modifiedAfter ?? state.modifiedAfter,
      modifiedBefore: modifiedBefore ?? state.modifiedBefore,
      lastUsedAfter: lastUsedAfter ?? state.lastUsedAfter,
      lastUsedBefore: lastUsedBefore ?? state.lastUsedBefore,
      sortDirection: sortDirection ?? state.sortDirection,
      minUsedCount: minUsedCount ?? state.minUsedCount,
      maxUsedCount: maxUsedCount ?? state.maxUsedCount,
      limit: limit ?? state.limit,
      offset: offset ?? state.offset,
    );
  }

  /// Обновить фильтр полностью
  void updateFilter(BaseFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Применить новый фильтр (создать через BaseFilter.create)
  void applyFilter(BaseFilter newFilter) {
    _debounceTimer?.cancel();
    logDebug('Применен новый фильтр', tag: _logTag);
    state = newFilter;
  }

  /// Сбросить фильтр к начальному состоянию
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен к начальному состоянию', tag: _logTag);
    state = const BaseFilter();
  }

  /// Сбросить только поиск
  void clearQuery() {
    _debounceTimer?.cancel();
    logDebug('Поисковый запрос очищен', tag: _logTag);
    state = state.copyWith(query: '');
  }

  /// Сбросить все фильтры кроме поиска
  void clearAllFiltersExceptQuery() {
    _debounceTimer?.cancel();
    final query = state.query;
    logDebug('Все фильтры очищены кроме поиска', tag: _logTag);
    state = BaseFilter(query: query);
  }

  /// Сбросить все фильтры со статусом кроме поиска
  void clearStatusFilters() {
    _debounceTimer?.cancel();
    logDebug('Фильтры статуса очищены', tag: _logTag);
    state = state.copyWith(
      isFavorite: null,
      isArchived: null,
      isDeleted: null,
      isPinned: null,
      hasNotes: null,
    );
  }

  /// Сбросить все фильтры по датам
  void clearDateFilters() {
    _debounceTimer?.cancel();
    logDebug('Фильтры по датам очищены', tag: _logTag);
    state = state.copyWith(
      createdAfter: null,
      createdBefore: null,
      modifiedAfter: null,
      modifiedBefore: null,
      lastUsedAfter: null,
      lastUsedBefore: null,
    );
  }
}
