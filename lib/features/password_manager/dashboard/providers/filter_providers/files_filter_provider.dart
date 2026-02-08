import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'base_filter_provider.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';

/// Провайдер для управления фильтром файлов
final filesFilterProvider = NotifierProvider<FilesFilterNotifier, FilesFilter>(
  FilesFilterNotifier.new,
);

class FilesFilterNotifier extends Notifier<FilesFilter> {
  static const String _logTag = 'FilesFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  FilesFilter build() {
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

    return FilesFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(FilesFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  // ============================================================================
  // Методы фильтрации по расширениям файлов
  // ============================================================================

  /// Добавить расширение в фильтр
  void addFileExtension(String extension) {
    final normalizedExt = extension.trim().toLowerCase();
    if (normalizedExt.isEmpty || state.fileExtensions.contains(normalizedExt)) {
      return;
    }
    final updated = [...state.fileExtensions, normalizedExt];
    logDebug('Добавлено расширение: $normalizedExt', tag: _logTag);
    state = state.copyWith(fileExtensions: updated);
  }

  /// Удалить расширение из фильтра
  void removeFileExtension(String extension) {
    final normalizedExt = extension.trim().toLowerCase();
    final updated = state.fileExtensions
        .where((e) => e != normalizedExt)
        .toList();
    logDebug('Удалено расширение: $normalizedExt', tag: _logTag);
    state = state.copyWith(fileExtensions: updated);
  }

  /// Переключить расширение в фильтре
  void toggleFileExtension(String extension) {
    final normalizedExt = extension.trim().toLowerCase();
    if (state.fileExtensions.contains(normalizedExt)) {
      removeFileExtension(normalizedExt);
    } else {
      addFileExtension(normalizedExt);
    }
  }

  /// Установить расширения (заменить все)
  void setFileExtensions(List<String> extensions) {
    final normalized = extensions
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    logDebug('Установлены расширения: $normalized', tag: _logTag);
    state = state.copyWith(fileExtensions: normalized);
  }

  /// Показать только документы
  void showOnlyDocuments() {
    logDebug('Фильтр: только документы', tag: _logTag);
    state = state.copyWith(
      fileExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
    );
  }

  /// Показать только изображения
  void showOnlyImages() {
    logDebug('Фильтр: только изображения', tag: _logTag);
    state = state.copyWith(
      fileExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'],
    );
  }

  /// Показать только видео
  void showOnlyVideos() {
    logDebug('Фильтр: только видео', tag: _logTag);
    state = state.copyWith(
      fileExtensions: ['mp4', 'avi', 'mov', 'mkv', 'flv', 'wmv'],
    );
  }

  /// Показать только аудиофайлы
  void showOnlyAudio() {
    logDebug('Фильтр: только аудиофайлы', tag: _logTag);
    state = state.copyWith(
      fileExtensions: ['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg'],
    );
  }

  /// Показать только архивы
  void showOnlyArchives() {
    logDebug('Фильтр: только архивы', tag: _logTag);
    state = state.copyWith(
      fileExtensions: ['zip', 'rar', '7z', 'tar', 'gz', 'bz2'],
    );
  }

  /// Очистить фильтр расширений
  void clearFileExtensions() {
    logDebug('Очищены расширения', tag: _logTag);
    state = state.copyWith(fileExtensions: []);
  }

  // ============================================================================
  // Методы фильтрации по MIME типам
  // ============================================================================

  /// Добавить MIME тип в фильтр
  void addMimeType(String mimeType) {
    final normalizedMime = mimeType.trim().toLowerCase();
    if (normalizedMime.isEmpty || state.mimeTypes.contains(normalizedMime)) {
      return;
    }
    final updated = [...state.mimeTypes, normalizedMime];
    logDebug('Добавлен MIME тип: $normalizedMime', tag: _logTag);
    state = state.copyWith(mimeTypes: updated);
  }

  /// Удалить MIME тип из фильтра
  void removeMimeType(String mimeType) {
    final normalizedMime = mimeType.trim().toLowerCase();
    final updated = state.mimeTypes.where((m) => m != normalizedMime).toList();
    logDebug('Удален MIME тип: $normalizedMime', tag: _logTag);
    state = state.copyWith(mimeTypes: updated);
  }

  /// Переключить MIME тип в фильтре
  void toggleMimeType(String mimeType) {
    final normalizedMime = mimeType.trim().toLowerCase();
    if (state.mimeTypes.contains(normalizedMime)) {
      removeMimeType(normalizedMime);
    } else {
      addMimeType(normalizedMime);
    }
  }

  /// Установить MIME типы (заменить все)
  void setMimeTypes(List<String> mimeTypes) {
    final normalized = mimeTypes
        .map((m) => m.trim().toLowerCase())
        .where((m) => m.isNotEmpty)
        .toList();
    logDebug('Установлены MIME типы: $normalized', tag: _logTag);
    state = state.copyWith(mimeTypes: normalized);
  }

  /// Показать только текстовые файлы
  void showOnlyTextFiles() {
    logDebug('Фильтр: только текстовые файлы', tag: _logTag);
    state = state.copyWith(
      mimeTypes: ['text/plain', 'text/html', 'text/xml', 'application/json'],
    );
  }

  /// Очистить фильтр MIME типов
  void clearMimeTypes() {
    logDebug('Очищены MIME типы', tag: _logTag);
    state = state.copyWith(mimeTypes: []);
  }

  // ============================================================================
  // Методы фильтрации по размеру файла
  // ============================================================================

  /// Установить минимальный размер файла (в байтах)
  void setMinFileSize(int? minSize) {
    logDebug(
      'Минимальный размер файла установлен: $minSize байт',
      tag: _logTag,
    );
    state = state.copyWith(minFileSize: minSize);
  }

  /// Установить максимальный размер файла (в байтах)
  void setMaxFileSize(int? maxSize) {
    logDebug(
      'Максимальный размер файла установлен: $maxSize байт',
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

  /// Показать маленькие файлы (до 1 МБ)
  void showSmallFiles() {
    logDebug('Фильтр: маленькие файлы (до 1 МБ)', tag: _logTag);
    state = state.copyWith(
      minFileSize: null,
      maxFileSize: 1024 * 1024, // 1 MB
    );
  }

  /// Показать средние файлы (1-100 МБ)
  void showMediumFiles() {
    logDebug('Фильтр: средние файлы (1-100 МБ)', tag: _logTag);
    state = state.copyWith(
      minFileSize: 1024 * 1024, // 1 MB
      maxFileSize: 100 * 1024 * 1024, // 100 MB
    );
  }

  /// Показать большие файлы (более 100 МБ)
  void showLargeFiles() {
    logDebug('Фильтр: большие файлы (более 100 МБ)', tag: _logTag);
    state = state.copyWith(
      minFileSize: 100 * 1024 * 1024, // 100 MB
      maxFileSize: null,
    );
  }

  /// Показать огромные файлы (более 1 ГБ)
  void showHugeFiles() {
    logDebug('Фильтр: огромные файлы (более 1 ГБ)', tag: _logTag);
    state = state.copyWith(
      minFileSize: 1024 * 1024 * 1024, // 1 GB
      maxFileSize: null,
    );
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
  // Методы сортировки
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(FilesSortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  /// Сортировать по названию
  void sortByName() {
    logDebug('Сортировка по названию', tag: _logTag);
    state = state.copyWith(sortField: FilesSortField.name);
  }

  /// Сортировать по имени файла
  void sortByFileName() {
    logDebug('Сортировка по имени файла', tag: _logTag);
    state = state.copyWith(sortField: FilesSortField.fileName);
  }

  /// Сортировать по размеру файла
  void sortByFileSize() {
    logDebug('Сортировка по размеру файла', tag: _logTag);
    state = state.copyWith(sortField: FilesSortField.fileSize);
  }

  /// Сортировать по расширению файла
  void sortByFileExtension() {
    logDebug('Сортировка по расширению файла', tag: _logTag);
    state = state.copyWith(sortField: FilesSortField.fileExtension);
  }

  /// Сортировать по MIME типу
  void sortByMimeType() {
    logDebug('Сортировка по MIME типу', tag: _logTag);
    state = state.copyWith(sortField: FilesSortField.mimeType);
  }

  /// Сортировать по дате создания
  void sortByCreatedAt() {
    logDebug('Сортировка по дате создания', tag: _logTag);
    state = state.copyWith(sortField: FilesSortField.createdAt);
  }

  /// Сортировать по дате изменения
  void sortByModifiedAt() {
    logDebug('Сортировка по дате изменения', tag: _logTag);
    state = state.copyWith(sortField: FilesSortField.modifiedAt);
  }

  /// Переключить поле сортировки между несколькими
  void cycleSortField(List<FilesSortField> fields) {
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
  bool get hasFilesSpecificConstraints {
    if (state.fileExtensions.isNotEmpty) return true;
    if (state.mimeTypes.isNotEmpty) return true;
    if (state.minFileSize != null) return true;
    if (state.maxFileSize != null) return true;
    if (state.fileName != null) return true;
    return false;
  }

  /// Проверить есть ли активные фильтры (включая базовые)
  bool get hasActiveConstraints => state.hasActiveConstraints;

  /// Получить текущий фильтр
  FilesFilter get currentFilter => state;

  /// Получить базовый фильтр
  BaseFilter get baseFilter => state.base;

  /// Проверить валидность диапазона размера файла
  bool get isValidFileSizeRange => state.isValidFileSizeRange;

  /// Обновить весь фильтр файлов сразу
  void updateFilter(FilesFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Применить новый фильтр (создать через FilesFilter.create)
  void applyFilter(FilesFilter newFilter) {
    _debounceTimer?.cancel();
    logDebug('Применен новый фильтр', tag: _logTag);
    state = newFilter;
  }

  /// Сбросить фильтр к начальному состоянию
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен к начальному состоянию', tag: _logTag);
    state = FilesFilter(base: ref.read(baseFilterProvider));
  }

  /// Сбросить только фильтры специфичные для файлов
  void clearFilesSpecificFilters() {
    _debounceTimer?.cancel();
    logDebug('Фильтры файлов очищены', tag: _logTag);
    state = state.copyWith(
      fileExtensions: [],
      mimeTypes: [],
      minFileSize: null,
      maxFileSize: null,
      fileName: null,
    );
  }

  /// Сбросить фильтры расширений и MIME типов
  void clearTypeFilters() {
    _debounceTimer?.cancel();
    logDebug('Фильтры типов файлов очищены', tag: _logTag);
    state = state.copyWith(fileExtensions: [], mimeTypes: []);
  }

  /// Получить копию фильтра с изменениями
  FilesFilter copyFilter({
    BaseFilter? base,
    List<String>? fileExtensions,
    List<String>? mimeTypes,
    int? minFileSize,
    int? maxFileSize,
    String? fileName,
    FilesSortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      fileExtensions: fileExtensions ?? state.fileExtensions,
      mimeTypes: mimeTypes ?? state.mimeTypes,
      minFileSize: minFileSize ?? state.minFileSize,
      maxFileSize: maxFileSize ?? state.maxFileSize,
      fileName: fileName ?? state.fileName,
      sortField: sortField ?? state.sortField,
    );
  }
}
