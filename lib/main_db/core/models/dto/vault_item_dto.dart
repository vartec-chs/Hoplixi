import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/api_key/api_key_items.dart';
import '../../tables/bank_card/bank_card_items.dart';
import '../../tables/certificate/certificate_items.dart';
import '../../tables/crypto_wallet/crypto_wallet_items.dart';
import '../../tables/license_key/license_key_items.dart';
import '../../tables/loyalty_card/loyalty_card_items.dart';
import '../../tables/otp/otp_items.dart';
import '../../tables/ssh_key/ssh_key_items.dart';
import '../../tables/wifi/wifi_items.dart';
import 'converters.dart';

part 'vault_item_dto.freezed.dart';
part 'vault_item_dto.g.dart';

@freezed
sealed class VaultItemDto with _$VaultItemDto {
  // Shared fields are listed in each constructor for freezed common properties support.

  const factory VaultItemDto.password({
    String? id,
    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,
    @Default(0) int usedCount,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
    double? recentScore,
    DateTime? lastUsedAt,
    // Specific fields
    String? login,
    String? email,
    required String password,
    String? url,
    DateTime? expiresAt,
  }) = PasswordItemDto;

  const factory VaultItemDto.otp({
    String? id,
    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,
    @Default(0) int usedCount,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
    double? recentScore,
    DateTime? lastUsedAt,
    // Specific fields
    @JsonKey(required: true, disallowNullValue: true)
    @Default(OtpType.otp)
    OtpType type,
    String? issuer,
    String? accountName,
    @Uint8ListConverter() required Uint8List secret,
    @JsonKey(required: true, disallowNullValue: true)
    @Default(OtpHashAlgorithm.SHA1)
    OtpHashAlgorithm algorithm,
    @Default(6) int digits,
    @Default(30) int? period,
    int? counter,
  }) = OtpItemDto;

  const factory VaultItemDto.note({
    String? id,
    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,
    @Default(0) int usedCount,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
    double? recentScore,
    DateTime? lastUsedAt,
    // Specific fields
    required String deltaJson,
    required String content,
  }) = NoteItemDto;

  const factory VaultItemDto.bankCard({
    String? id,
    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,
    @Default(0) int usedCount,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
    double? recentScore,
    DateTime? lastUsedAt,
    // Specific fields
    String? cardholderName,
    required String cardNumber,

    CardType? cardType,
    String? cardTypeOther,
    CardNetwork? cardNetwork,
    String? cardNetworkOther,
    String? expiryMonth,
    String? expiryYear,
    String? cvv,
    String? bankName,
    String? accountNumber,
    String? routingNumber,
  }) = BankCardItemDto;

  const factory VaultItemDto.document({
    String? id,
    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,
    @Default(0) int usedCount,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
    double? recentScore,
    DateTime? lastUsedAt,
    // Specific fields
    String? currentVersionId,
  }) = DocumentItemDto;

  const factory VaultItemDto.file({
    String? id,
    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,
    @Default(0) int usedCount,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
    double? recentScore,
    DateTime? lastUsedAt,
    // Specific fields
    String? metadataId,
  }) = FileItemDto;

  const factory VaultItemDto.contact({
    String? id,
    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,
    @Default(0) int usedCount,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
    double? recentScore,
    DateTime? lastUsedAt,
    // Specific fields
    String? phone,
    String? email,
    String? company,
    String? jobTitle,
    String? address,
    String? website,
    DateTime? birthday,
    @Default(false) bool isEmergencyContact,
  }) = ContactItemDto;

  const factory VaultItemDto.apiKey({
    String? id,
    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,
    @Default(0) int usedCount,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
    double? recentScore,
    DateTime? lastUsedAt,
    // Specific fields
    required String service,
    required String key,
    ApiKeyTokenType? tokenType,
    String? tokenTypeOther,
    ApiKeyEnvironment? environment,
    String? environmentOther,
    DateTime? expiresAt,
    @Default(false) bool revoked,
    DateTime? revokedAt,
    int? rotationPeriodDays,
    DateTime? lastRotatedAt,
    String? owner,
    String? baseUrl,
    String? scopesText,
  }) = ApiKeyItemDto;

  const factory VaultItemDto.sshKey({
    String? id,
    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,
    @Default(0) int usedCount,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
    double? recentScore,
    DateTime? lastUsedAt,
    // Specific fields
    String? publicKey,
    String? privateKey,
    SshKeyType? keyType,
    String? keyTypeOther,
    int? keySize,
  }) = SshKeyItemDto;

  const factory VaultItemDto.certificate({
    String? id,
    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,
    @Default(0) int usedCount,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
    double? recentScore,
    DateTime? lastUsedAt,
    // Specific fields
    CertificateFormat? certificateFormat,
    String? certificateFormatOther,
    String? certificatePem,
    @Uint8ListConverter() Uint8List? certificateBlob,
    String? privateKey,
    String? privateKeyPassword,
    String? passwordForPfx,
    CertificateKeyAlgorithm? keyAlgorithm,
    String? keyAlgorithmOther,
    int? keySize,
    String? serialNumber,
    String? issuer,
    String? subject,
    DateTime? validFrom,
    DateTime? validTo,
  }) = CertificateItemDto;

  const factory VaultItemDto.cryptoWallet({
    String? id,
    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,
    @Default(0) int usedCount,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
    double? recentScore,
    DateTime? lastUsedAt,
    // Specific fields
    CryptoWalletType? walletType,
    String? walletTypeOther,
    CryptoNetwork? network,
    String? networkOther,
    String? mnemonic,
    String? privateKey,
    String? derivationPath,
    CryptoDerivationScheme? derivationScheme,
    String? derivationSchemeOther,
    String? addresses,
    String? xpub,
    String? xprv,
    String? hardwareDevice,
    @Default(false) bool watchOnly,
  }) = CryptoWalletItemDto;

  const factory VaultItemDto.wifi({
    String? id,
    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,
    @Default(0) int usedCount,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
    double? recentScore,
    DateTime? lastUsedAt,
    // Specific fields
    required String ssid,
    String? password,
    WifiSecurityType? securityType,
    String? securityTypeOther,
    WifiEncryptionType? encryption,
    String? encryptionOther,
    @Default(false) bool hiddenSsid,
  }) = WifiItemDto;

  const factory VaultItemDto.identity({
    String? id,
    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,
    @Default(0) int usedCount,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
    double? recentScore,
    DateTime? lastUsedAt,
    // Specific fields
    String? firstName,
    String? middleName,
    String? lastName,
    String? displayName,
    String? username,
    String? email,
    String? phone,
    String? address,
    DateTime? birthday,
    String? company,
    String? jobTitle,
    String? website,
    String? taxId,
    String? nationalId,
    String? passportNumber,
    String? driverLicenseNumber,
  }) = IdentityItemDto;

  const factory VaultItemDto.licenseKey({
    String? id,
    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,
    @Default(0) int usedCount,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
    double? recentScore,
    DateTime? lastUsedAt,
    // Specific fields
    required String productName,
    String? vendor,
    required String licenseKey,
    LicenseType? licenseType,
    String? licenseTypeOther,
    String? accountEmail,
    String? accountUsername,
    String? purchaseEmail,
    String? orderNumber,
    DateTime? purchaseDate,
    double? purchasePrice,
    String? currency,
    DateTime? validFrom,
    DateTime? validTo,
    DateTime? renewalDate,
    int? seats,
    int? activationLimit,
    int? activationsUsed,
  }) = LicenseKeyItemDto;

  const factory VaultItemDto.recoveryCodes({
    String? id,
    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,
    @Default(0) int usedCount,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
    double? recentScore,
    DateTime? lastUsedAt,
    // Specific fields
    @Default(0) int codesCount,
    @Default(0) int usedCountSpecific,
    DateTime? generatedAt,
    @Default(false) bool oneTime,
  }) = RecoveryCodesItemDto;

  const factory VaultItemDto.loyaltyCard({
    String? id,
    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,
    @Default(0) int usedCount,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
    double? recentScore,
    DateTime? lastUsedAt,
    // Specific fields
    required String programName,
    String? cardNumber,
    String? barcodeValue,
    String? password,
    LoyaltyBarcodeType? barcodeType,
    String? barcodeTypeOther,
    String? issuer,
    String? website,
    String? phone,
    String? email,
    DateTime? validFrom,
    DateTime? validTo,
  }) = LoyaltyCardItemDto;

  factory VaultItemDto.fromJson(Map<String, dynamic> json) =>
      _$VaultItemDtoFromJson(json);
}
