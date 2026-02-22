import 'package:freezed_annotation/freezed_annotation.dart';

part 'recovery_codes_form_state.freezed.dart';

@freezed
sealed class RecoveryCodesFormState with _$RecoveryCodesFormState {
  const factory RecoveryCodesFormState({
    @Default(false) bool isEditMode,
    String? editingRecoveryCodesId,
    @Default('') String name,
    @Default('') String codesBlob,
    @Default('') String codesCount,
    @Default('') String usedCount,
    @Default('') String perCodeStatus,
    @Default('') String generatedAt,
    @Default('') String notes,
    @Default('') String displayHint,
    @Default('') String description,
    @Default(false) bool oneTime,
    String? noteId,
    String? noteName,
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,
    String? nameError,
    String? codesBlobError,
    String? codesCountError,
    String? usedCountError,
    String? generatedAtError,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
  }) = _RecoveryCodesFormState;

  const RecoveryCodesFormState._();
}
