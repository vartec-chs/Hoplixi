import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/document/document_types.dart';

import 'base_filter_provider.dart';

/// Провайдер для управления фильтром документов
final documentsFilterProvider =
    NotifierProvider.autoDispose<DocumentsFilterNotifier, DocumentFilter>(
      DocumentsFilterNotifier.new,
    );

class DocumentsFilterNotifier extends Notifier<DocumentFilter> {
  static const String _logTag = 'DocumentsFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  DocumentFilter build() {
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

    return DocumentFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(DocumentFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  /// Обновить фильтр немедленно без дебаунса
  void updateFilter(DocumentFilter newFilter) {
    logDebug('Фильтр обновлен немедленно', tag: _logTag);
    state = newFilter;
  }

  // ============================================================================
  // Методы фильтрации по типам документов
  // ============================================================================

  /// Установить тип документа в фильтре
  void setDocumentType(DocumentType? documentType) {
    logDebug('Установлен тип документа: $documentType', tag: _logTag);
    state = state.copyWith(documentType: documentType);
  }

  /// Показать только паспорта
  void showOnlyPassports() {
    logDebug('Фильтр: только паспорта', tag: _logTag);
    state = state.copyWith(documentType: DocumentType.passport);
  }

  /// Показать только договоры
  void showOnlyContracts() {
    logDebug('Фильтр: только договоры', tag: _logTag);
    state = state.copyWith(documentType: DocumentType.contract);
  }

  /// Показать только сертификаты
  void showOnlyCertificates() {
    logDebug('Фильтр: только сертификаты', tag: _logTag);
    state = state.copyWith(documentType: DocumentType.certificate);
  }

  /// Показать удостоверения личности
  void showOnlyIdCards() {
    logDebug('Фильтр: только удостоверения', tag: _logTag);
    state = state.copyWith(documentType: DocumentType.idCard);
  }

  /// Показать медицинские документы
  void showOnlyMedical() {
    logDebug('Фильтр: только медицинские', tag: _logTag);
    state = state.copyWith(documentType: DocumentType.medical);
  }

  /// Очистить фильтр типов документов
  void clearDocumentType() {
    logDebug('Очищен тип документа', tag: _logTag);
    state = state.copyWith(documentType: null);
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
  // Статусные фильтры
  // ============================================================================

  /// Установить фильтр по актуальной версии
  void setHasCurrentVersion(bool? hasCurrentVersion) {
    logDebug('Фильтр "актуальная версия" установлен: $hasCurrentVersion', tag: _logTag);
    state = state.copyWith(hasCurrentVersion: hasCurrentVersion);
  }

  /// Установить фильтр по наличию хеша
  void setHasAggregateHash(bool? hasAggregateHash) {
    logDebug('Фильтр "есть хеш" установлен: $hasAggregateHash', tag: _logTag);
    state = state.copyWith(hasAggregateHash: hasAggregateHash);
  }

  // ============================================================================
  // Сортировка
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(DocumentSortField? field) {
    logDebug('Установлено поле сортировки: $field', tag: _logTag);
    state = state.copyWith(sortField: field);
  }

  /// Сортировать по названию
  void sortByName({bool ascending = true}) {
    logDebug('Сортировка по названию: $ascending', tag: _logTag);
    state = state.copyWith(
      sortField: DocumentSortField.name,
      base: state.base.copyWith(
        sortDirection: ascending ? SortDirection.asc : SortDirection.desc,
      ),
    );
  }

  /// Сортировать по дате создания
  void sortByCreatedAt({bool ascending = true}) {
    logDebug('Сортировка по дате создания: $ascending', tag: _logTag);
    state = state.copyWith(
      sortField: DocumentSortField.createdAt,
      base: state.base.copyWith(
        sortDirection: ascending ? SortDirection.asc : SortDirection.desc,
      ),
    );
  }

  /// Сортировать по дате изменения
  void sortByModifiedAt({bool ascending = true}) {
    logDebug('Сортировка по дате изменения: $ascending', tag: _logTag);
    state = state.copyWith(
      sortField: DocumentSortField.modifiedAt,
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
      sortField: DocumentSortField.lastUsedAt,
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
      documentType: null,
      minPageCount: null,
      maxPageCount: null,
      hasCurrentVersion: null,
      hasAggregateHash: null,
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

    if (state.documentType != null) {
      parts.add('Тип: ${state.documentType!.name}');
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

    if (state.hasCurrentVersion != null) {
      parts.add(state.hasCurrentVersion! ? 'Только актуальные' : 'Только архивные');
    }

    if (parts.isEmpty) {
      return 'Нет активных фильтров';
    }

    return parts.join(' • ');
  }
}
