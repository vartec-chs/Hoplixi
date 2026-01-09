import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_form_state.freezed.dart';

/// Состояние формы файла
@freezed
sealed class FileFormState with _$FileFormState {
  const factory FileFormState({
    // Режим формы
    @Default(false) bool isEditMode,
    String? editingFileId,

    // Поля формы
    @Default('') String name,
    @Default('') String description,
    String? noteId,

    // Информация о файле (для создания)
    File? selectedFile,
    String? selectedFileName,
    int? selectedFileSize,
    String? selectedFileExtension,
    String? selectedFileMimeType,

    // Информация о файле (для редактирования)
    String? existingFileName,
    int? existingFileSize,
    String? existingFileExtension,

    // Связи
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,

    // Ошибки валидации
    String? nameError,
    String? fileError,

    // Состояние загрузки
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,
    @Default(0.0) double uploadProgress,

    // Флаг успешного сохранения
    @Default(false) bool isSaved,
  }) = _FileFormState;

  const FileFormState._();

  /// Проверка валидности формы
  bool get isValid {
    if (isEditMode) {
      return nameError == null && name.isNotEmpty;
    }
    return nameError == null &&
        fileError == null &&
        name.isNotEmpty &&
        selectedFile != null;
  }

  /// Есть ли хоть одна ошибка
  bool get hasErrors {
    return nameError != null || fileError != null;
  }

  /// Отформатированный размер файла
  String get formattedFileSize {
    final size = isEditMode ? existingFileSize : selectedFileSize;
    if (size == null) return '';

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

  /// Имя отображаемого файла
  String get displayFileName {
    return isEditMode ? (existingFileName ?? '') : (selectedFileName ?? '');
  }

  /// Расширение отображаемого файла
  String get displayFileExtension {
    return isEditMode
        ? (existingFileExtension ?? '')
        : (selectedFileExtension ?? '');
  }
}
