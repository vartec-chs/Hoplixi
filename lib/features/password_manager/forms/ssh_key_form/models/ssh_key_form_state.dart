import 'package:freezed_annotation/freezed_annotation.dart';

part 'ssh_key_form_state.freezed.dart';

@freezed
sealed class SshKeyFormState with _$SshKeyFormState {
  const factory SshKeyFormState({
    @Default(false) bool isEditMode,
    String? editingSshKeyId,
    @Default('') String name,
    @Default('') String publicKey,
    @Default('') String privateKey,
    @Default('') String keyType,
    @Default('') String fingerprint,
    @Default('') String usage,
    @Default('') String description,
    @Default(false) bool addedToAgent,
    String? noteId,
    String? noteName,
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,
    String? nameError,
    String? publicKeyError,
    String? privateKeyError,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
  }) = _SshKeyFormState;

  const SshKeyFormState._();

  bool get hasErrors =>
      nameError != null || publicKeyError != null || privateKeyError != null;
}
