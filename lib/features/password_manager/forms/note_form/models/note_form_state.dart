import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';

part 'note_form_state.freezed.dart';

/// Состояние формы заметки
@freezed
sealed class NoteFormState with _$NoteFormState {
  const factory NoteFormState({
    // Режим формы
    @Default(false) bool isEditMode,
    String? editingNoteId,

    bool? edited,

    // Исходные данные для отслеживания изменений (только в режиме редактирования)
    String? originalDeltaJson,
    String? originalTitle,
    String? originalDescription,
    String? originalCategoryId,
    @Default([]) List<String> originalTagIds,

    // Основные поля формы
    @Default('') String title,
    @Default('') String content,
    @Default('[]') String deltaJson,
    @Default('') String description,

    // Связи
    String? categoryId,
    String? categoryName,
    String? iconSource,
    String? iconValue,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,
    @Default([]) List<CustomFieldEntry> customFields,

    // Связи с другими vault items (отслеживание для синхронизации)
    @Default([]) List<String> linkedNoteIds,

    // Ошибки валидации
    String? titleError,
    String? contentError,

    // Состояние загрузки
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,

    // Флаг успешного сохранения
    @Default(false) bool isSaved,

    // Флаг изменений
    @Default(false) bool hasUnsavedChanges,
  }) = _NoteFormState;

  const NoteFormState._();

  /// Проверка валидности формы
  bool get isValid {
    return titleError == null &&
        contentError == null &&
        title.isNotEmpty &&
        content.isNotEmpty;
  }

  /// Есть ли хоть одна ошибка
  bool get hasErrors {
    return titleError != null || contentError != null;
  }
}
