import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';

part 'wifi_form_state.freezed.dart';

@freezed
sealed class WifiFormState with _$WifiFormState {
  const factory WifiFormState({
    @Default(false) bool isEditMode,
    String? editingWifiId,
    @Default('') String name,
    @Default('') String ssid,
    @Default('') String password,
    @Default('') String securityType,
    @Default('') String securityTypeOther,
    @Default('') String encryption,
    @Default('') String encryptionOther,
    @Default(false) bool hiddenSsid,
    @Default('') String description,
    String? noteId,
    String? noteName,
    String? categoryId,
    String? categoryName,
    String? iconSource,
    String? iconValue,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,
    @Default([]) List<CustomFieldEntry> customFields,
    String? nameError,
    String? ssidError,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
  }) = _WifiFormState;

  const WifiFormState._();

  bool get hasErrors => nameError != null || ssidError != null;
}
