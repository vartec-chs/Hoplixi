import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';

import 'base_filter_provider.dart';

/// Провайдер для управления фильтром заметок
final notesFilterProvider =
    NotifierProvider.autoDispose<NotesFilterNotifier, NoteFilter>(
      NotesFilterNotifier.new,
    );

class NotesFilterNotifier extends Notifier<NoteFilter> {
  static const String _logTag = 'NotesFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  NoteFilter build() {
    logDebug('Инициализация фильтра заметок', tag: _logTag);

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('Обновление базового фильтра', tag: _logTag);
      state = state.copyWith(base: next);
    });

    // Очищаем таймер при dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return NoteFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(NoteFilter newFilter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен с дебаунсом', tag: _logTag);
    _debounceTimer = Timer(_debounceDuration, () {
      state = newFilter;
    });
  }

  // ============================================================================
  // Методы фильтрации по названию
  // ============================================================================

  /// Обновить фильтр по названию с дебаунсингом
  void updateName(String? name) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление названия: "$name"', tag: _logTag);
      state = state.copyWith(name: name?.trim());
    });
  }

  /// Установить название без дебаунсинга
  void setName(String? name) {
    _debounceTimer?.cancel();
    logDebug('Установка названия: "$name"', tag: _logTag);
    state = state.copyWith(name: name?.trim());
  }

  /// Очистить фильтр названия
  void clearName() {
    _debounceTimer?.cancel();
    logDebug('Очищено название', tag: _logTag);
    state = state.copyWith(name: null);
  }

  // ============================================================================
  // Методы фильтрации по содержимому
  // ============================================================================

  /// Обновить фильтр по содержимому с дебаунсингом
  void updateContentQuery(String? contentQuery) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление содержимого: "$contentQuery"', tag: _logTag);
      state = state.copyWith(contentQuery: contentQuery?.trim());
    });
  }

  /// Установить содержимое без дебаунсинга
  void setContentQuery(String? contentQuery) {
    _debounceTimer?.cancel();
    logDebug('Установка содержимого: "$contentQuery"', tag: _logTag);
    state = state.copyWith(contentQuery: contentQuery?.trim());
  }

  /// Очистить фильтр содержимого
  void clearContentQuery() {
    _debounceTimer?.cancel();
    logDebug('Очищено содержимое', tag: _logTag);
    state = state.copyWith(contentQuery: null);
  }

  // ============================================================================
  // Методы фильтрации по наличию данных
  // ============================================================================

  /// Установить фильтр по наличию содержимого
  void setHasContent(bool? hasContent) {
    logDebug('Фильтр "имеет содержимое" установлен: $hasContent', tag: _logTag);
    state = state.copyWith(hasContent: hasContent);
  }

  // ============================================================================
  // Методы сортировки
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(NoteSortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  /// Сортировать по названию
  void sortByName() {
    logDebug('Сортировка по названию', tag: _logTag);
    state = state.copyWith(sortField: NoteSortField.name);
  }

  /// Сортировать по дате создания
  void sortByCreatedAt() {
    logDebug('Сортировка по дате создания', tag: _logTag);
    state = state.copyWith(sortField: NoteSortField.createdAt);
  }

  /// Сортировать по дате изменения
  void sortByModifiedAt() {
    logDebug('Сортировка по дате изменения', tag: _logTag);
    state = state.copyWith(sortField: NoteSortField.modifiedAt);
  }

  /// Сортировать по дате последнего доступа
  void sortByLastUsedAt() {
    logDebug('Сортировка по дате последнего доступа', tag: _logTag);
    state = state.copyWith(sortField: NoteSortField.lastUsedAt);
  }

  /// Переключить поле сортировки между несколькими
  void cycleSortField(List<NoteSortField> fields) {
    if (fields.isEmpty) return;

    final currentIndex = fields.indexWhere((f) => f == state.sortField);
    final nextIndex = (currentIndex + 1) % fields.length;
    final newField = fields[nextIndex];

    logDebug('Циклический переход: $newField', tag: _logTag);
    state = state.copyWith(sortField: newField);
  }

  // ============================================================================
  // Методы управления фильтром в целом
  // ============================================================================

  /// Проверить есть ли активные фильтры специфичные для заметок
  bool get hasNotesSpecificConstraints => state.hasActiveConstraints;

  /// Проверить есть ли активные фильтры (включая базовые)
  bool get hasActiveConstraints => state.hasActiveConstraints;

  /// Получить текущий фильтр
  NoteFilter get currentFilter => state;

  /// Получить базовый фильтр
  BaseFilter get baseFilter => state.base;

  /// Обновить весь фильтр заметок сразу
  void updateFilter(NoteFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Применить новый фильтр (создать через NoteFilter.create)
  void applyFilter(NoteFilter newFilter) {
    _debounceTimer?.cancel();
    logDebug('Применен новый фильтр', tag: _logTag);
    state = newFilter;
  }

  /// Сбросить фильтр к начальному состоянию
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен к начальному состоянию', tag: _logTag);
    state = NoteFilter(base: ref.read(baseFilterProvider));
  }

  /// Сбросить только фильтры специфичные для заметок
  void clearNotesSpecificFilters() {
    _debounceTimer?.cancel();
    logDebug('Фильтры заметок очищены', tag: _logTag);
    state = state.copyWith(name: null, contentQuery: null, hasContent: null);
  }

  /// Сбросить фильтры текстовых полей (name, contentQuery)
  void clearTextFilters() {
    _debounceTimer?.cancel();
    logDebug('Текстовые фильтры очищены', tag: _logTag);
    state = state.copyWith(name: null, contentQuery: null);
  }

  /// Применить фильтр для поиска по названию и содержимому
  void applyTextSearch({
    required String query,
    bool searchName = true,
    bool searchContent = true,
  }) {
    _debounceTimer?.cancel();
    logDebug(
      'Поиск текста: "$query" (name=$searchName, content=$searchContent)',
      tag: _logTag,
    );

    state = state.copyWith(
      name: searchName ? query : null,
      contentQuery: searchContent ? query : null,
    );
  }

  /// Получить копию фильтра с изменениями
  NoteFilter copyFilter({
    BaseFilter? base,
    String? name,
    String? contentQuery,
    bool? hasContent,
    NoteSortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      name: name ?? state.name,
      contentQuery: contentQuery ?? state.contentQuery,
      hasContent: hasContent ?? state.hasContent,
      sortField: sortField ?? state.sortField,
    );
  }
}
