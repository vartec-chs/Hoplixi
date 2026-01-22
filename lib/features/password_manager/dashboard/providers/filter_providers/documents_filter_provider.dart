import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';

import 'base_filter_provider.dart';

/// Провайдер для управления фильтром документов
final documentsFilterProvider =
    NotifierProvider<DocumentsFilterNotifier, DocumentsFilter>(
      DocumentsFilterNotifier.new,
    );

class DocumentsFilterNotifier extends Notifier<DocumentsFilter> {
  static const String _logTag = 'DocumentsFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  DocumentsFilter build() {
    logDebug('Инициализация фильтра документов', tag: _logTag);

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('Обновление базового фильтра', tag: _logTag);
      state = state.copyWith(base: next);
    });

    // Очищаем таймер при dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return DocumentsFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(DocumentsFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  /// Обновить фильтр немедленно без дебаунса
  void updateFilter(DocumentsFilter newFilter) {
    logDebug('Фильтр обновлен немедленно', tag: _logTag);
    state = newFilter;
  }

  // ============================================================================
  // Методы фильтрации по типам документов
  // ============================================================================

  /// Добавить тип документа в фильтр
  void addDocumentType(String documentType) {
    final normalizedType = documentType.trim().toLowerCase();
    if (normalizedType.isEmpty ||
        state.documentTypes.contains(normalizedType)) {
      return;
    }
    final updated = [...state.documentTypes, normalizedType];
    logDebug('Добавлен тип документа: $normalizedType', tag: _logTag);
    state = state.copyWith(documentTypes: updated);
  }

  /// Удалить тип документа из фильтра
  void removeDocumentType(String documentType) {
    final normalizedType = documentType.trim().toLowerCase();
    final updated = state.documentTypes
        .where((e) => e != normalizedType)
        .toList();
    logDebug('Удален тип документа: $normalizedType', tag: _logTag);
    state = state.copyWith(documentTypes: updated);
  }

  /// Переключить тип документа в фильтре
  void toggleDocumentType(String documentType) {
    final normalizedType = documentType.trim().toLowerCase();
    if (state.documentTypes.contains(normalizedType)) {
      removeDocumentType(normalizedType);
    } else {
      addDocumentType(normalizedType);
    }
  }

  /// Установить типы документов (заменить все)
  void setDocumentTypes(List<String> documentTypes) {
    final normalized = documentTypes
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    logDebug('Установлены типы документов: $normalized', tag: _logTag);
    state = state.copyWith(documentTypes: normalized);
  }

  /// Показать только паспорта
  void showOnlyPassports() {
    logDebug('Фильтр: только паспорта', tag: _logTag);
    state = state.copyWith(documentTypes: ['passport']);
  }

  /// Показать только договоры
  void showOnlyContracts() {
    logDebug('Фильтр: только договоры', tag: _logTag);
    state = state.copyWith(documentTypes: ['contract']);
  }

  /// Показать только сертификаты
  void showOnlyCertificates() {
    logDebug('Фильтр: только сертификаты', tag: _logTag);
    state = state.copyWith(documentTypes: ['certificate']);
  }

  /// Показать удостоверения личности
  void showOnlyIdCards() {
    logDebug('Фильтр: только удостоверения', tag: _logTag);
    state = state.copyWith(documentTypes: ['id_card']);
  }

  /// Показать медицинские документы
  void showOnlyMedical() {
    logDebug('Фильтр: только медицинские', tag: _logTag);
    state = state.copyWith(documentTypes: ['medical']);
  }

  /// Очистить фильтр типов документов
  void clearDocumentTypes() {
    logDebug('Очищены типы документов', tag: _logTag);
    state = state.copyWith(documentTypes: []);
  }

  // ============================================================================
  // Методы фильтрации по количеству страниц
  // ============================================================================

  /// Установить минимальное количество страниц
  void setMinPageCount(int? count) {
    if (count != null && count < 0) return;
    logDebug(
      'Установлено минимальное количество страниц: $count',
      tag: _logTag,
    );
    state = state.copyWith(minPageCount: count);
  }

  /// Установить максимальное количество страниц
  void setMaxPageCount(int? count) {
    if (count != null && count < 0) return;
    logDebug(
      'Установлено максимальное количество страниц: $count',
      tag: _logTag,
    );
    state = state.copyWith(maxPageCount: count);
  }

  /// Установить диапазон количества страниц
  void setPageCountRange(int? min, int? max) {
    if (min != null && min < 0) return;
    if (max != null && max < 0) return;
    if (min != null && max != null && min > max) return;
    logDebug('Установлен диапазон страниц: $min-$max', tag: _logTag);
    state = state.copyWith(minPageCount: min, maxPageCount: max);
  }

  /// Показать только однострочные документы
  void showOnlySinglePageDocuments() {
    logDebug('Фильтр: только однострочные документы', tag: _logTag);
    state = state.copyWith(minPageCount: 1, maxPageCount: 1);
  }

  /// Показать многостраничные документы
  void showOnlyMultiPageDocuments() {
    logDebug('Фильтр: только многостраничные документы', tag: _logTag);
    state = state.copyWith(minPageCount: 2, maxPageCount: null);
  }

  /// Очистить фильтр по количеству страниц
  void clearPageCountFilter() {
    logDebug('Очищен фильтр количества страниц', tag: _logTag);
    state = state.copyWith(minPageCount: null, maxPageCount: null);
  }

  // ============================================================================
  // Методы фильтрации по текстовым полям
  // ============================================================================

  /// Установить поиск по названию
  void setTitleQuery(String? query) {
    final normalized = query?.trim();
    logDebug('Установлен поиск по названию: $normalized', tag: _logTag);
    updateFilterDebounced(
      state.copyWith(
        titleQuery: normalized?.isEmpty == true ? null : normalized,
      ),
    );
  }

  /// Установить поиск по описанию
  void setDescriptionQuery(String? query) {
    final normalized = query?.trim();
    logDebug('Установлен поиск по описанию: $normalized', tag: _logTag);
    updateFilterDebounced(
      state.copyWith(
        descriptionQuery: normalized?.isEmpty == true ? null : normalized,
      ),
    );
  }

  /// Установить поиск по агрегированному тексту (OCR)
  void setAggregatedTextQuery(String? query) {
    final normalized = query?.trim();
    logDebug(
      'Установлен поиск по агрегированному тексту: $normalized',
      tag: _logTag,
    );
    updateFilterDebounced(
      state.copyWith(
        aggregatedTextQuery: normalized?.isEmpty == true ? null : normalized,
      ),
    );
  }

  /// Очистить все текстовые запросы
  void clearTextQueries() {
    logDebug('Очищены текстовые запросы', tag: _logTag);
    state = state.copyWith(
      titleQuery: null,
      descriptionQuery: null,
      aggregatedTextQuery: null,
    );
  }

  // ============================================================================
  // Сортировка
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(DocumentsSortField? field) {
    logDebug('Установлено поле сортировки: $field', tag: _logTag);
    state = state.copyWith(sortField: field);
  }

  /// Сортировать по названию
  void sortByTitle({bool ascending = true}) {
    logDebug('Сортировка по названию: $ascending', tag: _logTag);
    state = state.copyWith(
      sortField: DocumentsSortField.title,
      base: state.base.copyWith(
        sortDirection: ascending ? SortDirection.asc : SortDirection.desc,
      ),
    );
  }

  /// Сортировать по типу документа
  void sortByDocumentType({bool ascending = true}) {
    logDebug('Сортировка по типу документа: $ascending', tag: _logTag);
    state = state.copyWith(
      sortField: DocumentsSortField.documentType,
      base: state.base.copyWith(
        sortDirection: ascending ? SortDirection.asc : SortDirection.desc,
      ),
    );
  }

  /// Сортировать по количеству страниц
  void sortByPageCount({bool ascending = true}) {
    logDebug('Сортировка по количеству страниц: $ascending', tag: _logTag);
    state = state.copyWith(
      sortField: DocumentsSortField.pageCount,
      base: state.base.copyWith(
        sortDirection: ascending ? SortDirection.asc : SortDirection.desc,
      ),
    );
  }

  /// Сортировать по дате создания
  void sortByCreatedAt({bool ascending = true}) {
    logDebug('Сортировка по дате создания: $ascending', tag: _logTag);
    state = state.copyWith(
      sortField: DocumentsSortField.createdAt,
      base: state.base.copyWith(
        sortDirection: ascending ? SortDirection.asc : SortDirection.desc,
      ),
    );
  }

  /// Сортировать по дате изменения
  void sortByModifiedAt({bool ascending = true}) {
    logDebug('Сортировка по дате изменения: $ascending', tag: _logTag);
    state = state.copyWith(
      sortField: DocumentsSortField.modifiedAt,
      base: state.base.copyWith(
        sortDirection: ascending ? SortDirection.asc : SortDirection.desc,
      ),
    );
  }

  /// Сортировать по дате последнего использования
  void sortByLastUsedAt({bool ascending = true}) {
    logDebug(
      'Сортировка по последнему использованию: $ascending',
      tag: _logTag,
    );
    state = state.copyWith(
      sortField: DocumentsSortField.lastUsedAt,
      base: state.base.copyWith(
        sortDirection: ascending ? SortDirection.asc : SortDirection.desc,
      ),
    );
  }

  // ============================================================================
  // Сброс фильтров
  // ============================================================================

  /// Сбросить все специфичные для документов фильтры
  void resetDocumentSpecificFilters() {
    logDebug('Сброс специфичных фильтров документов', tag: _logTag);
    state = state.copyWith(
      documentTypes: [],
      minPageCount: null,
      maxPageCount: null,
      titleQuery: null,
      descriptionQuery: null,
      aggregatedTextQuery: null,
      sortField: null,
    );
  }

  /// Полный сброс фильтра (включая базовый)
  void resetAll() {
    logDebug('Полный сброс фильтра документов', tag: _logTag);
    ref.read(baseFilterProvider.notifier).reset();
    resetDocumentSpecificFilters();
  }

  // ============================================================================
  // Утилиты
  // ============================================================================

  /// Проверить, есть ли активные фильтры
  bool get hasActiveFilters => state.hasActiveConstraints;

  /// Получить описание активных фильтров
  String getActiveFiltersDescription() {
    final parts = <String>[];

    if (state.documentTypes.isNotEmpty) {
      parts.add('Типы: ${state.documentTypes.join(", ")}');
    }

    if (state.minPageCount != null || state.maxPageCount != null) {
      if (state.minPageCount != null && state.maxPageCount != null) {
        parts.add('Страницы: ${state.minPageCount}-${state.maxPageCount}');
      } else if (state.minPageCount != null) {
        parts.add('Мин. страниц: ${state.minPageCount}');
      } else {
        parts.add('Макс. страниц: ${state.maxPageCount}');
      }
    }

    if (state.titleQuery != null) {
      parts.add('Название: "${state.titleQuery}"');
    }

    if (state.descriptionQuery != null) {
      parts.add('Описание: "${state.descriptionQuery}"');
    }

    if (state.aggregatedTextQuery != null) {
      parts.add('Текст: "${state.aggregatedTextQuery}"');
    }

    if (parts.isEmpty) {
      return 'Нет активных фильтров';
    }

    return parts.join(' • ');
  }
}
