import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/file/file_metadata.dart';

import 'base_filter_provider.dart';

/// Провайдер для управления фильтром файлов
final filesFilterProvider =
    NotifierProvider.autoDispose<FilesFilterNotifier, FileFilter>(
      FilesFilterNotifier.new,
    );

class FilesFilterNotifier extends Notifier<FileFilter> {
  static const String _logTag = 'FilesFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  FileFilter build() {
    logDebug('Инициализация фильтра файлов', tag: _logTag);

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('Обновление базового фильтра', tag: _logTag);
      state = state.copyWith(base: next);
    });

    // Очищаем таймер при dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return FileFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(FileFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  // ============================================================================
  // Методы фильтрации по расширениям файлов
  // ============================================================================

  /// Установить расширение в фильтре
  void setFileExtension(String? extension) {
    final normalizedExt = extension?.trim().toLowerCase();
    logDebug('Установлено расширение: $normalizedExt', tag: _logTag);
    state = state.copyWith(fileExtension: normalizedExt);
  }

  /// Очистить фильтр расширений
  void clearFileExtension() {
    logDebug('Очищено расширение', tag: _logTag);
    state = state.copyWith(fileExtension: null);
  }

  // ============================================================================
  // Методы фильтрации по MIME типам
  // ============================================================================

  /// Установить MIME тип в фильтре
  void setMimeType(String? mimeType) {
    final normalizedMime = mimeType?.trim().toLowerCase();
    logDebug('Установлен MIME тип: $normalizedMime', tag: _logTag);
    state = state.copyWith(mimeType: normalizedMime);
  }

  /// Очистить фильтр MIME типов
  void clearMimeType() {
    logDebug('Очищен MIME тип', tag: _logTag);
    state = state.copyWith(mimeType: null);
  }

  // ============================================================================
  // Методы фильтрации по размеру файла
  // ============================================================================

  /// Установить минимальный размер файла (в байтах)
  void setMinFileSize(int? minSize) {
    logDebug(
      'Минимальная размер файла установлен: $minSize байт',
      tag: _logTag,
    );
    state = state.copyWith(minFileSize: minSize);
  }

  /// Установить максимальный размер файла (в байтах)
  void setMaxFileSize(int? maxSize) {
    logDebug(
      'Максимальная размер файла установлен: $maxSize байт',
      tag: _logTag,
    );
    state = state.copyWith(maxFileSize: maxSize);
  }

  /// Установить диапазон размера файла (в байтах)
  void setFileSizeRange(int? minSize, int? maxSize) {
    logDebug(
      'Диапазон размера файла установлен: $minSize - $maxSize байт',
      tag: _logTag,
    );
    state = state.copyWith(minFileSize: minSize, maxFileSize: maxSize);
  }

  /// Очистить фильтр размера файла
  void clearFileSizeFilter() {
    logDebug('Очищен фильтр размера файла', tag: _logTag);
    state = state.copyWith(minFileSize: null, maxFileSize: null);
  }

  // ============================================================================
  // Методы фильтрации по названию файла
  // ============================================================================

  /// Обновить фильтр по названию файла с дебаунсингом
  void updateFileName(String? fileName) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление названия файла: "$fileName"', tag: _logTag);
      state = state.copyWith(fileName: fileName?.trim());
    });
  }

  /// Установить название файла без дебаунсинга
  void setFileName(String? fileName) {
    _debounceTimer?.cancel();
    logDebug('Установка названия файла: "$fileName"', tag: _logTag);
    state = state.copyWith(fileName: fileName?.trim());
  }

  /// Очистить фильтр названия файла
  void clearFileName() {
    _debounceTimer?.cancel();
    logDebug('Очищено название файла', tag: _logTag);
    state = state.copyWith(fileName: null);
  }

  // ============================================================================
  // Методы фильтрации по статусу
  // ============================================================================

  /// Установить статус доступности
  void setAvailabilityStatus(FileAvailabilityStatus? status) {
    logDebug('Установлен статус доступности: $status', tag: _logTag);
    state = state.copyWith(availabilityStatus: status);
  }

  /// Установить статус целостности
  void setIntegrityStatus(FileIntegrityStatus? status) {
    logDebug('Установлен статус целостности: $status', tag: _logTag);
    state = state.copyWith(integrityStatus: status);
  }

  // ============================================================================
  // Методы сортировки
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(FileSortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  /// Сортировать по названию
  void sortByName() {
    logDebug('Сортировка по названию', tag: _logTag);
    state = state.copyWith(sortField: FileSortField.name);
  }

  /// Сортировать по имени файла
  void sortByFileName() {
    logDebug('Сортировка по имени файла', tag: _logTag);
    state = state.copyWith(sortField: FileSortField.fileName);
  }

  /// Сортировать по размеру файла
  void sortByFileSize() {
    logDebug('Сортировка по размеру файла', tag: _logTag);
    state = state.copyWith(sortField: FileSortField.fileSize);
  }

  /// Сортировать по дате создания
  void sortByCreatedAt() {
    logDebug('Сортировка по дате создания', tag: _logTag);
    state = state.copyWith(sortField: FileSortField.createdAt);
  }

  /// Сортировать по дате изменения
  void sortByModifiedAt() {
    logDebug('Сортировка по дате изменения', tag: _logTag);
    state = state.copyWith(sortField: FileSortField.modifiedAt);
  }

  /// Переключить поле сортировки между несколькими
  void cycleSortField(List<FileSortField> fields) {
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

  /// Проверить есть ли активные фильтры специфичные для файлов
  bool get hasFilesSpecificConstraints => state.hasActiveConstraints;

  /// Проверить есть ли активные фильтры (включая базовые)
  bool get hasActiveConstraints => state.hasActiveConstraints;

  /// Получить текущий фильтр
  FileFilter get currentFilter => state;

  /// Получить базовый фильтр
  BaseFilter get baseFilter => state.base;

  /// Обновить весь фильтр файлов сразу
  void updateFilter(FileFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Применить новый фильтр (создать через FileFilter.create)
  void applyFilter(FileFilter newFilter) {
    _debounceTimer?.cancel();
    logDebug('Применен новый фильтр', tag: _logTag);
    state = newFilter;
  }

  /// Сбросить фильтр к начальному состоянию
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен к начальному состоянию', tag: _logTag);
    state = FileFilter(base: ref.read(baseFilterProvider));
  }

  /// Сбросить только фильтры специфичные для файлов
  void clearFilesSpecificFilters() {
    _debounceTimer?.cancel();
    logDebug('Фильтры файлов очищены', tag: _logTag);
    state = state.copyWith(
      fileExtension: null,
      mimeType: null,
      minFileSize: null,
      maxFileSize: null,
      fileName: null,
      availabilityStatus: null,
      integrityStatus: null,
    );
  }

  /// Получить копию фильтра с изменениями
  FileFilter copyFilter({
    BaseFilter? base,
    String? fileExtension,
    String? mimeType,
    int? minFileSize,
    int? maxFileSize,
    String? fileName,
    FileAvailabilityStatus? availabilityStatus,
    FileIntegrityStatus? integrityStatus,
    FileSortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      fileExtension: fileExtension ?? state.fileExtension,
      mimeType: mimeType ?? state.mimeType,
      minFileSize: minFileSize ?? state.minFileSize,
      maxFileSize: maxFileSize ?? state.maxFileSize,
      fileName: fileName ?? state.fileName,
      availabilityStatus: availabilityStatus ?? state.availabilityStatus,
      integrityStatus: integrityStatus ?? state.integrityStatus,
      sortField: sortField ?? state.sortField,
    );
  }
}
