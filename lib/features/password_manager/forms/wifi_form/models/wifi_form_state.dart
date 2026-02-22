import 'package:freezed_annotation/freezed_annotation.dart';

part 'wifi_form_state.freezed.dart';

@freezed
sealed class WifiFormState with _$WifiFormState {
  const factory WifiFormState({
    @Default(false) bool isEditMode,
    String? editingWifiId,
    @Default('') String name,
    @Default('') String ssid,
    @Default('') String password,
    @Default('') String security,
    @Default(false) bool hidden,
    @Default('') String eapMethod,
    @Default('') String username,
    @Default('') String identity,
    @Default('') String domain,
    @Default('') String lastConnectedBssid,
    @Default('') String priority,
    @Default('') String notes,
    @Default('') String qrCodePayload,
    @Default('') String description,
    String? noteId,
    String? noteName,
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,
    String? nameError,
    String? ssidError,
    String? priorityError,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
  }) = _WifiFormState;

  const WifiFormState._();

  bool get hasErrors =>
      nameError != null || ssidError != null || priorityError != null;
}
