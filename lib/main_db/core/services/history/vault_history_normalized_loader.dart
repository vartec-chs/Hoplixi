import '../../daos/daos.dart';
import '../../models/dto_history/cards/cards_exports.dart';
import '../../tables/vault_items/vault_items.dart';
import '../../models/mappers/history/vault_snapshot_history_mapper.dart';
import 'vault_history_restore_policy_service.dart';

class NormalizedHistorySnapshot {
  const NormalizedHistorySnapshot({
    required this.snapshot,
    required this.fields,
    required this.sensitiveKeys,
    required this.customFields,
    required this.restoreWarnings,
  });

  final VaultSnapshotCardDto snapshot;
  final Map<String, Object?> fields;
  final Set<String> sensitiveKeys;
  final List<dynamic> customFields;
  final List<String> restoreWarnings;
}

class VaultHistoryNormalizedLoader {
  VaultHistoryNormalizedLoader({
    required this.snapshotsHistoryDao,
    required this.restorePolicyService,
    required this.apiKeyHistoryDao,
    required this.passwordHistoryDao,
    required this.bankCardHistoryDao,
    required this.certificateHistoryDao,
    required this.cryptoWalletHistoryDao,
    required this.wifiHistoryDao,
    required this.sshKeyHistoryDao,
    required this.licenseKeyHistoryDao,
    required this.otpHistoryDao,
    required this.recoveryCodesHistoryDao,
    required this.loyaltyCardHistoryDao,
    required this.fileHistoryDao,
    required this.contactHistoryDao,
    required this.identityHistoryDao,
    required this.noteHistoryDao,
  });

  final VaultSnapshotsHistoryDao snapshotsHistoryDao;
  final VaultHistoryRestorePolicyService restorePolicyService;
  final ApiKeyHistoryDao apiKeyHistoryDao;
  final PasswordHistoryDao passwordHistoryDao;
  final BankCardHistoryDao bankCardHistoryDao;
  final CertificateHistoryDao certificateHistoryDao;
  final CryptoWalletHistoryDao cryptoWalletHistoryDao;
  final WifiHistoryDao wifiHistoryDao;
  final SshKeyHistoryDao sshKeyHistoryDao;
  final LicenseKeyHistoryDao licenseKeyHistoryDao;
  final OtpHistoryDao otpHistoryDao;
  final RecoveryCodesHistoryDao recoveryCodesHistoryDao;
  final LoyaltyCardHistoryDao loyaltyCardHistoryDao;
  final FileMetadataHistoryDao fileHistoryDao;
  final ContactHistoryDao contactHistoryDao;
  final IdentityHistoryDao identityHistoryDao;
  final NoteHistoryDao noteHistoryDao;

  Future<NormalizedHistorySnapshot?> loadHistorySnapshot(String historyId) async {
    final snapshotData = await snapshotsHistoryDao.getSnapshotById(historyId);
    if (snapshotData == null) return null;

    final snapshotDto = snapshotData.toVaultSnapshotCardDto();
    final fields = <String, Object?>{};
    final sensitiveKeys = <String>{};

    fields['name'] = snapshotDto.name;
    fields['description'] = snapshotDto.description;

    switch (snapshotDto.type) {
      case VaultItemType.apiKey:
        final data = await apiKeyHistoryDao.getApiKeyHistoryByHistoryIds([historyId]);
        if (data.isNotEmpty) {
          final item = data.first;
          fields['service'] = item.service;
          fields['key'] = item.key;
          fields['tokenType'] = item.tokenType?.name;
          fields['environment'] = item.environment?.name;
          fields['expiresAt'] = item.expiresAt;
          fields['revokedAt'] = item.revokedAt;
          fields['rotationPeriodDays'] = item.rotationPeriodDays;
          fields['lastRotatedAt'] = item.lastRotatedAt;
          fields['owner'] = item.owner;
          fields['baseUrl'] = item.baseUrl;
          sensitiveKeys.add('key');
        }
        break;
      case VaultItemType.password:
        final data = await passwordHistoryDao.getPasswordHistoryByHistoryIds([historyId]);
        if (data.isNotEmpty) {
          final item = data.first;
          fields['login'] = item.login;
          fields['email'] = item.email;
          fields['password'] = item.password;
          fields['url'] = item.url;
          fields['expiresAt'] = item.expiresAt;
          sensitiveKeys.add('password');
        }
        break;
      case VaultItemType.bankCard:
        final data = await bankCardHistoryDao.getBankCardHistoryByHistoryIds([historyId]);
        if (data.isNotEmpty) {
          final item = data.first;
          fields['cardholderName'] = item.cardholderName;
          fields['cardNumber'] = item.cardNumber;
          fields['cardType'] = item.cardType?.name;
          fields['cardTypeOther'] = item.cardTypeOther;
          fields['cardNetwork'] = item.cardNetwork?.name;
          fields['cardNetworkOther'] = item.cardNetworkOther;
          fields['expiryMonth'] = item.expiryMonth;
          fields['expiryYear'] = item.expiryYear;
          fields['cvv'] = item.cvv;
          fields['bankName'] = item.bankName;
          fields['accountNumber'] = item.accountNumber;
          fields['routingNumber'] = item.routingNumber;
          sensitiveKeys.add('cardNumber');
          sensitiveKeys.add('cvv');
          sensitiveKeys.add('accountNumber');
          sensitiveKeys.add('routingNumber');
        }
        break;
      case VaultItemType.certificate:
        final data = await certificateHistoryDao.getCertificateHistoryByHistoryIds([historyId]);
        if (data.isNotEmpty) {
          final item = data.first;
          fields['certificateFormat'] = item.certificateFormat?.name;
          fields['certificateFormatOther'] = item.certificateFormatOther;
          fields['certificatePem'] = item.certificatePem;
          fields['certificateBlob'] = item.certificateBlob;
          fields['privateKey'] = item.privateKey;
          fields['privateKeyPassword'] = item.privateKeyPassword;
          fields['passwordForPfx'] = item.passwordForPfx;
          fields['keyAlgorithm'] = item.keyAlgorithm?.name;
          fields['keyAlgorithmOther'] = item.keyAlgorithmOther;
          fields['keySize'] = item.keySize;
          fields['serialNumber'] = item.serialNumber;
          fields['issuer'] = item.issuer;
          fields['subject'] = item.subject;
          fields['validFrom'] = item.validFrom;
          fields['validTo'] = item.validTo;
          sensitiveKeys.add('certificatePem');
          sensitiveKeys.add('certificateBlob');
          sensitiveKeys.add('privateKey');
          sensitiveKeys.add('privateKeyPassword');
          sensitiveKeys.add('passwordForPfx');
        }
        break;
      case VaultItemType.cryptoWallet:
        final data = await cryptoWalletHistoryDao.getCryptoWalletHistoryByHistoryIds([historyId]);
        if (data.isNotEmpty) {
          final item = data.first;
          fields['walletType'] = item.walletType?.name;
          fields['walletTypeOther'] = item.walletTypeOther;
          fields['network'] = item.network?.name;
          fields['networkOther'] = item.networkOther;
          fields['mnemonic'] = item.mnemonic;
          fields['privateKey'] = item.privateKey;
          fields['derivationPath'] = item.derivationPath;
          fields['derivationScheme'] = item.derivationScheme?.name;
          fields['derivationSchemeOther'] = item.derivationSchemeOther;
          fields['addresses'] = item.addresses;
          fields['xpub'] = item.xpub;
          fields['xprv'] = item.xprv;
          fields['hardwareDevice'] = item.hardwareDevice;
          fields['watchOnly'] = item.watchOnly;
          sensitiveKeys.add('mnemonic');
          sensitiveKeys.add('privateKey');
          sensitiveKeys.add('xprv');
        }
        break;
      case VaultItemType.wifi:
        final data = await wifiHistoryDao.getWifiHistoryByHistoryIds([historyId]);
        if (data.isNotEmpty) {
          final item = data.first;
          fields['ssid'] = item.ssid;
          fields['password'] = item.password;
          fields['securityType'] = item.securityType?.name;
          fields['securityTypeOther'] = item.securityTypeOther;
          fields['encryption'] = item.encryption?.name;
          fields['encryptionOther'] = item.encryptionOther;
          fields['hiddenSsid'] = item.hiddenSsid;
          sensitiveKeys.add('password');
        }
        break;
      case VaultItemType.sshKey:
        final data = await sshKeyHistoryDao.getSshKeyHistoryByHistoryIds([historyId]);
        if (data.isNotEmpty) {
          final item = data.first;
          fields['publicKey'] = item.publicKey;
          fields['privateKey'] = item.privateKey;
          fields['keyType'] = item.keyType?.name;
          fields['keyTypeOther'] = item.keyTypeOther;
          fields['keySize'] = item.keySize;
          sensitiveKeys.add('privateKey');
        }
        break;
      case VaultItemType.licenseKey:
        final data = await licenseKeyHistoryDao.getLicenseKeyHistoryByHistoryIds([historyId]);
        if (data.isNotEmpty) {
          final item = data.first;
          fields['productName'] = item.productName;
          fields['vendor'] = item.vendor;
          fields['licenseKey'] = item.licenseKey;
          fields['licenseType'] = item.licenseType?.name;
          fields['licenseTypeOther'] = item.licenseTypeOther;
          fields['accountEmail'] = item.accountEmail;
          fields['accountUsername'] = item.accountUsername;
          fields['purchaseEmail'] = item.purchaseEmail;
          fields['orderNumber'] = item.orderNumber;
          fields['purchaseDate'] = item.purchaseDate;
          fields['purchasePrice'] = item.purchasePrice;
          fields['currency'] = item.currency;
          fields['validFrom'] = item.validFrom;
          fields['validTo'] = item.validTo;
          fields['renewalDate'] = item.renewalDate;
          fields['seats'] = item.seats;
          fields['activationLimit'] = item.activationLimit;
          fields['activationsUsed'] = item.activationsUsed;
          sensitiveKeys.add('licenseKey');
        }
        break;
      case VaultItemType.otp:
        final data = await otpHistoryDao.getOtpHistoryByHistoryIds([historyId]);
        if (data.isNotEmpty) {
          final item = data.first;
          fields['type'] = item.type?.name;
          fields['issuer'] = item.issuer;
          fields['accountName'] = item.accountName;
          fields['secret'] = item.secret;
          fields['algorithm'] = item.algorithm?.name;
          fields['digits'] = item.digits;
          fields['period'] = item.period;
          fields['counter'] = item.counter;
          sensitiveKeys.add('secret');
        }
        break;
      case VaultItemType.recoveryCodes:
        final data = await recoveryCodesHistoryDao.getRecoveryCodesHistoryByHistoryIds([historyId]);
        if (data.isNotEmpty) {
          final item = data.first;
          fields['codesCount'] = item.codesCount;
          fields['usedCount'] = item.usedCount;
          fields['generatedAt'] = item.generatedAt;
          fields['oneTime'] = item.oneTime;
        }
        break;
      case VaultItemType.loyaltyCard:
        final data = await loyaltyCardHistoryDao.getLoyaltyCardHistoryByHistoryIds([historyId]);
        if (data.isNotEmpty) {
          final item = data.first;
          fields['programName'] = item.programName;
          fields['cardNumber'] = item.cardNumber;
          fields['barcodeValue'] = item.barcodeValue;
          fields['password'] = item.password;
          fields['barcodeType'] = item.barcodeType?.name;
          fields['barcodeTypeOther'] = item.barcodeTypeOther;
          fields['issuer'] = item.issuer;
          fields['website'] = item.website;
          fields['phone'] = item.phone;
          fields['email'] = item.email;
          fields['validFrom'] = item.validFrom;
          fields['validTo'] = item.validTo;
          sensitiveKeys.add('cardNumber');
          sensitiveKeys.add('barcodeValue');
          sensitiveKeys.add('password');
        }
        break;
      case VaultItemType.file:
        final data = await fileHistoryDao.getFileHistoryByHistoryIds([historyId]);
        if (data.isNotEmpty) {
          final item = data.first;
          fields['fileName'] = item.fileName;
          fields['fileExtension'] = item.fileExtension;
          fields['mimeType'] = item.mimeType;
          fields['fileSize'] = item.fileSize;
          fields['sha256'] = item.sha256;
          fields['availabilityStatus'] = item.availabilityStatus?.name;
          fields['integrityStatus'] = item.integrityStatus?.name;
          fields['missingDetectedAt'] = item.missingDetectedAt;
          fields['deletedAt'] = item.deletedAt;
          fields['lastIntegrityCheckAt'] = item.lastIntegrityCheckAt;
          fields['snapshotCreatedAt'] = item.snapshotCreatedAt;
          sensitiveKeys.add('filePath');
        }
        break;
      case VaultItemType.contact:
        final data = await contactHistoryDao.getContactHistoryByHistoryIds([historyId]);
        if (data.isNotEmpty) {
          final item = data.first;
          fields['firstName'] = item.firstName;
          fields['middleName'] = item.middleName;
          fields['lastName'] = item.lastName;
          fields['phone'] = item.phone;
          fields['email'] = item.email;
          fields['company'] = item.company;
          fields['jobTitle'] = item.jobTitle;
          fields['address'] = item.address;
          fields['website'] = item.website;
          fields['birthday'] = item.birthday;
          fields['isEmergencyContact'] = item.isEmergencyContact;
        }
        break;
      case VaultItemType.identity:
        final data = await identityHistoryDao.getIdentityHistoryByHistoryIds([historyId]);
        if (data.isNotEmpty) {
          final item = data.first;
          fields['firstName'] = item.firstName;
          fields['middleName'] = item.middleName;
          fields['lastName'] = item.lastName;
          fields['displayName'] = item.displayName;
          fields['username'] = item.username;
          fields['email'] = item.email;
          fields['phone'] = item.phone;
          fields['address'] = item.address;
          fields['birthday'] = item.birthday;
          fields['company'] = item.company;
          fields['jobTitle'] = item.jobTitle;
          fields['website'] = item.website;
          fields['taxId'] = item.taxId;
          fields['nationalId'] = item.nationalId;
          fields['passportNumber'] = item.passportNumber;
          fields['driverLicenseNumber'] = item.driverLicenseNumber;
        }
        break;
      case VaultItemType.note:
        final data = await noteHistoryDao.getNoteHistoryByHistoryIds([historyId]);
        if (data.isNotEmpty) {
          final item = data.first;
          fields['deltaJson'] = item.deltaJson;
          fields['content'] = item.content;
        }
        break;
      case VaultItemType.document:
        // Documents only have snapshot data for now
        break;
    }

    final normalized = NormalizedHistorySnapshot(
      snapshot: snapshotDto,
      fields: fields,
      sensitiveKeys: sensitiveKeys,
      customFields: const [],
      restoreWarnings: [],
    );

    return NormalizedHistorySnapshot(
      snapshot: snapshotDto,
      fields: fields,
      sensitiveKeys: sensitiveKeys,
      customFields: const [],
      restoreWarnings: restorePolicyService.restoreWarnings(normalized),
    );
  }

  Future<NormalizedHistorySnapshot?> loadCurrentSnapshot({
    required String itemId,
    required VaultItemType type,
  }) async {
    // TODO: Implement loading current live state and normalizing it
    return null;
  }
}
