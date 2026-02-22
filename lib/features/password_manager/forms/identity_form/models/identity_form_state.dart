import 'package:freezed_annotation/freezed_annotation.dart';

part 'identity_form_state.freezed.dart';

@freezed
sealed class IdentityFormState with _$IdentityFormState {
  const factory IdentityFormState({
    @Default(false) bool isEditMode,
    String? editingIdentityId,
    @Default('') String name,
    @Default('') String idType,
    @Default('') String idNumber,
    @Default('') String fullName,
    @Default('') String dateOfBirth,
    @Default('') String placeOfBirth,
    @Default('') String nationality,
    @Default('') String issuingAuthority,
    @Default('') String issueDate,
    @Default('') String expiryDate,
    @Default('') String mrz,
    @Default('') String scanAttachmentId,
    @Default('') String photoAttachmentId,
    @Default('') String notes,
    @Default('') String description,
    @Default(false) bool verified,
    String? noteId,
    String? noteName,
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,
    String? nameError,
    String? idTypeError,
    String? idNumberError,
    String? dateOfBirthError,
    String? issueDateError,
    String? expiryDateError,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
  }) = _IdentityFormState;

  const IdentityFormState._();
}
