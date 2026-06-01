import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';

part 'identity_form_state.freezed.dart';

@freezed
sealed class IdentityFormState with _$IdentityFormState {
  const factory IdentityFormState({
    @Default(false) bool isEditMode,
    String? editingIdentityId,
    @Default('') String name,
    @Default('') String firstName,
    @Default('') String middleName,
    @Default('') String lastName,
    @Default('') String displayName,
    @Default('') String username,
    @Default('') String email,
    @Default('') String phone,
    @Default('') String address,
    @Default('') String birthday,
    @Default('') String company,
    @Default('') String jobTitle,
    @Default('') String website,
    @Default('') String taxId,
    @Default('') String nationalId,
    @Default('') String passportNumber,
    @Default('') String driverLicenseNumber,
    @Default('') String description,
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,
    @Default([]) List<CustomFieldEntry> customFields,
    String? nameError,
    String? birthdayError,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
  }) = _IdentityFormState;

  const IdentityFormState._();
}
