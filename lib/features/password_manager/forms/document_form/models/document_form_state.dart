import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_form_state.freezed.dart';

/// Информация о странице документа
@freezed
sealed class DocumentPageInfo with _$DocumentPageInfo {
  const factory DocumentPageInfo({
    /// Локальный файл (для новых страниц)
    File? file,

    /// Имя файла
    required String fileName,

    /// Размер файла в байтах
    required int fileSize,

    /// MIME-тип файла
    String? mimeType,

    /// ID существующей страницы (для редактирования)
    String? pageId,

    /// ID файла в БД (для существующих страниц)
    String? fileId,

    /// Номер страницы
    required int pageNumber,

    /// Является ли страница главной (обложкой)
    @Default(false) bool isPrimary,

    /// Является ли страница новой (еще не сохранена)
    @Default(true) bool isNew,
  }) = _DocumentPageInfo;

  const DocumentPageInfo._();

  /// Отформатированный размер файла
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Расширение файла
  String get fileExtension {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }
}

/// Состояние формы документа
@freezed
sealed class DocumentFormState with _$DocumentFormState {
  const factory DocumentFormState({
    // Режим формы
    @Default(false) bool isEditMode,
    String? editingDocumentId,

    // Поля формы
    @Default('') String title,
    String? documentType,
    @Default('') String description,

    // Страницы документа
    @Default([]) List<DocumentPageInfo> pages,

    // Связи
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,
    String? noteId,
    String? noteName,

    // Ошибки валидации
    String? titleError,
    String? pagesError,

    // Состояние загрузки
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,
    @Default(0.0) double uploadProgress,
    @Default(0) int currentUploadingPage,
    @Default(0) int totalPages,

    // Флаг успешного сохранения
    @Default(false) bool isSaved,
  }) = _DocumentFormState;

  const DocumentFormState._();

  /// Проверка валидности формы
  bool get isValid {
    if (isEditMode) {
      return titleError == null && title.isNotEmpty;
    }
    return titleError == null &&
        pagesError == null &&
        title.isNotEmpty &&
        pages.isNotEmpty;
  }

  /// Есть ли хоть одна ошибка
  bool get hasErrors {
    return titleError != null || pagesError != null;
  }

  /// Количество страниц
  int get pageCount => pages.length;

  /// Есть ли новые страницы для загрузки
  bool get hasNewPages => pages.any((p) => p.isNew);

  /// Получить главную страницу (обложку)
  DocumentPageInfo? get primaryPage {
    try {
      return pages.firstWhere((p) => p.isPrimary);
    } catch (_) {
      return pages.isNotEmpty ? pages.first : null;
    }
  }

  /// Общий размер всех страниц
  int get totalPagesSize {
    return pages.fold(0, (sum, page) => sum + page.fileSize);
  }

  /// Отформатированный общий размер
  String get formattedTotalSize {
    final size = totalPagesSize;
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
