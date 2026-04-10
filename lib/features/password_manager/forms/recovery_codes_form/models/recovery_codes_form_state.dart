import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/shared/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/db_core/models/dto/recovery_code_item_dto.dart';

part 'recovery_codes_form_state.freezed.dart';

@freezed
sealed class RecoveryCodesFormState with _$RecoveryCodesFormState {
  const factory RecoveryCodesFormState({
    @Default(false) bool isEditMode,
    String? editingRecoveryCodesId,
    @Default('') String name,

    /// Текст для вставки кодов (один код на строку).
    @Default('') String codesInput,
    @Default('') String generatedAt,
    @Default('') String displayHint,
    @Default('') String description,
    @Default(false) bool oneTime,

    /// Существующие коды (только в режиме редактирования).
    @Default([]) List<RecoveryCodeItemDto> existingCodes,
    String? noteId,
    String? noteName,
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,
    @Default([]) List<CustomFieldEntry> customFields,
    String? nameError,
    String? codesInputError,
    String? generatedAtError,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
  }) = _RecoveryCodesFormState;

  const RecoveryCodesFormState._();
}
