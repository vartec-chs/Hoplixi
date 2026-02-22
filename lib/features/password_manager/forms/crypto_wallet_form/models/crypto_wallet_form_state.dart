import 'package:freezed_annotation/freezed_annotation.dart';

part 'crypto_wallet_form_state.freezed.dart';

@freezed
sealed class CryptoWalletFormState with _$CryptoWalletFormState {
  const factory CryptoWalletFormState({
    @Default(false) bool isEditMode,
    String? editingCryptoWalletId,
    @Default('') String name,
    @Default('') String walletType,
    @Default('') String mnemonic,
    @Default('') String privateKey,
    @Default('') String derivationPath,
    @Default('') String network,
    @Default('') String addresses,
    @Default('') String xpub,
    @Default('') String xprv,
    @Default('') String hardwareDevice,
    @Default('') String derivationScheme,
    @Default('') String notesOnUsage,
    @Default('') String description,
    @Default(false) bool watchOnly,
    String? noteId,
    String? noteName,
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,
    String? nameError,
    String? walletTypeError,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
  }) = _CryptoWalletFormState;

  const CryptoWalletFormState._();
}
