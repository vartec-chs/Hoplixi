import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact_form_state.freezed.dart';

@freezed
sealed class ContactFormState with _$ContactFormState {
  const factory ContactFormState({
    @Default(false) bool isEditMode,
    String? editingContactId,
    @Default('') String name,
    @Default('') String phone,
    @Default('') String email,
    @Default('') String company,
    @Default('') String jobTitle,
    @Default('') String address,
    @Default('') String website,
    DateTime? birthday,
    @Default('') String description,
    @Default(false) bool isEmergencyContact,
    String? noteId,
    String? noteName,
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,
    String? nameError,
    String? emailError,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
  }) = _ContactFormState;

  const ContactFormState._();

  bool get hasErrors => nameError != null || emailError != null;
}
