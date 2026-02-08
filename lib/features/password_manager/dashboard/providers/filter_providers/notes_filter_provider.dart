import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'base_filter_provider.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';

/// Провайдер для управления фильтром заметок
final notesFilterProvider = NotifierProvider<NotesFilterNotifier, NotesFilter>(
  NotesFilterNotifier.new,
);

class NotesFilterNotifier extends Notifier<NotesFilter> {
  static const String _logTag = 'NotesFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  NotesFilter build() {
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

    return NotesFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(NotesFilter newFilter) {
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
  void updateTitle(String? title) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление названия: "$title"', tag: _logTag);
      state = state.copyWith(title: title?.trim());
    });
  }

  /// Установить название без дебаунсинга
  void setTitle(String? title) {
    _debounceTimer?.cancel();
    logDebug('Установка названия: "$title"', tag: _logTag);
    state = state.copyWith(title: title?.trim());
  }

  /// Очистить фильтр названия
  void clearTitle() {
    _debounceTimer?.cancel();
    logDebug('Очищено название', tag: _logTag);
    state = state.copyWith(title: null);
  }

  // ============================================================================
  // Методы фильтрации по содержимому
  // ============================================================================

  /// Обновить фильтр по содержимому с дебаунсингом
  void updateContent(String? content) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление содержимого: "$content"', tag: _logTag);
      state = state.copyWith(content: content?.trim());
    });
  }

  /// Установить содержимое без дебаунсинга
  void setContent(String? content) {
    _debounceTimer?.cancel();
    logDebug('Установка содержимого: "$content"', tag: _logTag);
    state = state.copyWith(content: content?.trim());
  }

  /// Очистить фильтр содержимого
  void clearContent() {
    _debounceTimer?.cancel();
    logDebug('Очищено содержимое', tag: _logTag);
    state = state.copyWith(content: null);
  }

  // ============================================================================
  // Методы фильтрации по описанию
  // ============================================================================

  /// Установить фильтр по наличию описания
  void setHasDescription(bool? hasDescription) {
    logDebug(
      'Фильтр "имеет описание" установлен: $hasDescription',
      tag: _logTag,
    );
    state = state.copyWith(hasDescription: hasDescription);
  }

  /// Показать только с описанием
  void showOnlyWithDescription() {
    logDebug('Фильтр: только с описанием', tag: _logTag);
    state = state.copyWith(hasDescription: true);
  }

  /// Показать только без описания
  void showOnlyWithoutDescription() {
    logDebug('Фильтр: только без описания', tag: _logTag);
    state = state.copyWith(hasDescription: false);
  }

  // ============================================================================
  // Методы фильтрации по Delta JSON
  // ============================================================================

  /// Установить фильтр по наличию Delta JSON (расширенное форматирование)
  void setHasDeltaJson(bool? hasDeltaJson) {
    logDebug(
      'Фильтр "имеет Delta JSON" установлен: $hasDeltaJson',
      tag: _logTag,
    );
    state = state.copyWith(hasDeltaJson: hasDeltaJson);
  }

  /// Показать только с Delta JSON (форматированные заметки)
  void showOnlyWithDeltaJson() {
    logDebug('Фильтр: только с Delta JSON', tag: _logTag);
    state = state.copyWith(hasDeltaJson: true);
  }

  /// Показать только без Delta JSON (простые заметки)
  void showOnlyWithoutDeltaJson() {
    logDebug('Фильтр: только без Delta JSON', tag: _logTag);
    state = state.copyWith(hasDeltaJson: false);
  }

  // ============================================================================
  // Методы фильтрации по длине контента
  // ============================================================================

  /// Установить минимальную длину контента
  void setMinContentLength(int? minLength) {
    logDebug(
      'Минимальная длина контента установлена: $minLength',
      tag: _logTag,
    );
    state = state.copyWith(minContentLength: minLength);
  }

  /// Установить максимальную длину контента
  void setMaxContentLength(int? maxLength) {
    logDebug(
      'Максимальная длина контента установлена: $maxLength',
      tag: _logTag,
    );
    state = state.copyWith(maxContentLength: maxLength);
  }

  /// Установить диапазон длины контента
  void setContentLengthRange(int? minLength, int? maxLength) {
    logDebug(
      'Диапазон длины контента установлен: $minLength - $maxLength',
      tag: _logTag,
    );
    state = state.copyWith(
      minContentLength: minLength,
      maxContentLength: maxLength,
    );
  }

  /// Показать короткие заметки (до 500 символов)
  void showShortNotes() {
    logDebug('Фильтр: короткие заметки (до 500 символов)', tag: _logTag);
    state = state.copyWith(minContentLength: null, maxContentLength: 500);
  }

  /// Показать средние заметки (500-5000 символов)
  void showMediumNotes() {
    logDebug('Фильтр: средние заметки (500-5000 символов)', tag: _logTag);
    state = state.copyWith(minContentLength: 500, maxContentLength: 5000);
  }

  /// Показать длинные заметки (более 5000 символов)
  void showLongNotes() {
    logDebug('Фильтр: длинные заметки (более 5000 символов)', tag: _logTag);
    state = state.copyWith(minContentLength: 5000, maxContentLength: null);
  }

  /// Очистить фильтр по длине контента
  void clearContentLengthFilter() {
    logDebug('Очищен фильтр длины контента', tag: _logTag);
    state = state.copyWith(minContentLength: null, maxContentLength: null);
  }

  // ============================================================================
  // Методы сортировки
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(NotesSortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  /// Сортировать по названию
  void sortByTitle() {
    logDebug('Сортировка по названию', tag: _logTag);
    state = state.copyWith(sortField: NotesSortField.title);
  }

  /// Сортировать по описанию
  void sortByDescription() {
    logDebug('Сортировка по описанию', tag: _logTag);
    state = state.copyWith(sortField: NotesSortField.description);
  }

  /// Сортировать по длине контента
  void sortByContentLength() {
    logDebug('Сортировка по длине контента', tag: _logTag);
    state = state.copyWith(sortField: NotesSortField.contentLength);
  }

  /// Сортировать по дате создания
  void sortByCreatedAt() {
    logDebug('Сортировка по дате создания', tag: _logTag);
    state = state.copyWith(sortField: NotesSortField.createdAt);
  }

  /// Сортировать по дате изменения
  void sortByModifiedAt() {
    logDebug('Сортировка по дате изменения', tag: _logTag);
    state = state.copyWith(sortField: NotesSortField.modifiedAt);
  }

  /// Сортировать по дате последнего доступа
  void sortByLastAccessed() {
    logDebug('Сортировка по дате последнего доступа', tag: _logTag);
    state = state.copyWith(sortField: NotesSortField.lastAccessed);
  }

  /// Переключить поле сортировки между несколькими
  void cycleSortField(List<NotesSortField> fields) {
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
  bool get hasNotesSpecificConstraints {
    if (state.title != null) return true;
    if (state.content != null) return true;
    if (state.hasDescription != null) return true;
    if (state.hasDeltaJson != null) return true;
    if (state.minContentLength != null) return true;
    if (state.maxContentLength != null) return true;
    return false;
  }

  /// Проверить есть ли активные фильтры (включая базовые)
  bool get hasActiveConstraints => state.hasActiveConstraints;

  /// Получить текущий фильтр
  NotesFilter get currentFilter => state;

  /// Получить базовый фильтр
  BaseFilter get baseFilter => state.base;

  /// Проверить валидность диапазона длины контента
  bool get isValidContentLengthRange => state.isValidContentLengthRange;

  /// Обновить весь фильтр заметок сразу
  void updateFilter(NotesFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Применить новый фильтр (создать через NotesFilter.create)
  void applyFilter(NotesFilter newFilter) {
    _debounceTimer?.cancel();
    logDebug('Применен новый фильтр', tag: _logTag);
    state = newFilter;
  }

  /// Сбросить фильтр к начальному состоянию
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен к начальному состоянию', tag: _logTag);
    state = NotesFilter(base: ref.read(baseFilterProvider));
  }

  /// Сбросить только фильтры специфичные для заметок
  void clearNotesSpecificFilters() {
    _debounceTimer?.cancel();
    logDebug('Фильтры заметок очищены', tag: _logTag);
    state = state.copyWith(
      title: null,
      content: null,
      hasDescription: null,
      hasDeltaJson: null,
      minContentLength: null,
      maxContentLength: null,
    );
  }

  /// Сбросить фильтры текстовых полей (title, content)
  void clearTextFilters() {
    _debounceTimer?.cancel();
    logDebug('Текстовые фильтры очищены', tag: _logTag);
    state = state.copyWith(title: null, content: null);
  }

  /// Сбросить фильтры по статусу (hasDescription, hasDeltaJson)
  void clearStatusFilters() {
    _debounceTimer?.cancel();
    logDebug('Фильтры статуса очищены', tag: _logTag);
    state = state.copyWith(hasDescription: null, hasDeltaJson: null);
  }

  /// Применить фильтр для поиска по названию и содержимому
  void applyTextSearch({
    required String query,
    bool searchTitle = true,
    bool searchContent = true,
  }) {
    _debounceTimer?.cancel();
    logDebug(
      'Поиск текста: "$query" (title=$searchTitle, content=$searchContent)',
      tag: _logTag,
    );

    state = state.copyWith(
      title: searchTitle ? query : null,
      content: searchContent ? query : null,
    );
  }

  /// Применить пресет для поиска пустых заметок (без контента)
  void applyEmptyNotesPreset() {
    _debounceTimer?.cancel();
    logDebug('Применен пресет для пустых заметок', tag: _logTag);
    state = state.copyWith(maxContentLength: 0, title: null, content: null);
  }

  /// Применить пресет для поиска форматированных заметок
  void applyFormattedNotesPreset() {
    _debounceTimer?.cancel();
    logDebug('Применен пресет для форматированных заметок', tag: _logTag);
    state = state.copyWith(hasDeltaJson: true, hasDescription: null);
  }

  /// Применить пресет для поиска обычных заметок
  void applyPlainNotesPreset() {
    _debounceTimer?.cancel();
    logDebug('Применен пресет для обычных заметок', tag: _logTag);
    state = state.copyWith(hasDeltaJson: false, hasDescription: null);
  }

  /// Применить пресет для детальных заметок с описанием
  void applyDetailedNotesPreset() {
    _debounceTimer?.cancel();
    logDebug('Применен пресет для детальных заметок', tag: _logTag);
    state = state.copyWith(hasDescription: true, minContentLength: 100);
  }

  /// Получить копию фильтра с изменениями
  NotesFilter copyFilter({
    BaseFilter? base,
    String? title,
    String? content,
    bool? hasDescription,
    bool? hasDeltaJson,
    int? minContentLength,
    int? maxContentLength,
    NotesSortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      title: title ?? state.title,
      content: content ?? state.content,
      hasDescription: hasDescription ?? state.hasDescription,
      hasDeltaJson: hasDeltaJson ?? state.hasDeltaJson,
      minContentLength: minContentLength ?? state.minContentLength,
      maxContentLength: maxContentLength ?? state.maxContentLength,
      sortField: sortField ?? state.sortField,
    );
  }
}
