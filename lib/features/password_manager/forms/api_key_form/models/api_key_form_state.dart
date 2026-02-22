import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_key_form_state.freezed.dart';

@freezed
sealed class ApiKeyFormState with _$ApiKeyFormState {
  const factory ApiKeyFormState({
    @Default(false) bool isEditMode,
    String? editingApiKeyId,
    @Default('') String name,
    @Default('') String service,
    @Default('') String key,
    @Default('') String tokenType,
    @Default('') String environment,
    @Default('') String description,
    @Default(false) bool revoked,
    String? noteId,
    String? noteName,
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,
    String? nameError,
    String? serviceError,
    String? keyError,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
  }) = _ApiKeyFormState;

  const ApiKeyFormState._();

  bool get hasErrors =>
      nameError != null || serviceError != null || keyError != null;
}
