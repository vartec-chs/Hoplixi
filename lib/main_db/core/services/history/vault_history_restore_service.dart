import 'package:drift/drift.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import '../../daos/daos.dart';
import '../../errors/db_error.dart';
import '../../errors/db_result.dart';
import '../../main_store.dart';
import '../../tables/tables.dart';
import 'vault_history_normalized_loader.dart';
import 'vault_history_restore_policy_service.dart';

class VaultHistoryRestoreService {
  VaultHistoryRestoreService({
    required this.loader,
    required this.policy,
    required this.db,
    required this.vaultItemsDao,
    required this.apiKeyItemsDao,
    required this.passwordItemsDao,
    required this.noteItemsDao,
    required this.bankCardItemsDao,
    required this.certificateItemsDao,
    required this.contactItemsDao,
    required this.cryptoWalletItemsDao,
    required this.identityItemsDao,
    required this.licenseKeyItemsDao,
    required this.loyaltyCardItemsDao,
    required this.otpItemsDao,
    required this.sshKeyItemsDao,
    required this.wifiItemsDao,
    required this.fileItemsDao,
    required this.fileMetadataDao,
    required this.fileHistoryDao,
    required this.fileMetadataHistoryDao,
    required this.recoveryCodesItemsDao,
    required this.recoveryCodesDao,
    required this.recoveryCodesHistoryDao,
    required this.recoveryCodeValuesHistoryDao,
  });

  final VaultHistoryNormalizedLoader loader;
  final VaultHistoryRestorePolicyService policy;
  final MainStore db;
  final VaultItemsDao vaultItemsDao;
  final ApiKeyItemsDao apiKeyItemsDao;
  final PasswordItemsDao passwordItemsDao;
  final NoteItemsDao noteItemsDao;
  final BankCardItemsDao bankCardItemsDao;
  final CertificateItemsDao certificateItemsDao;
  final ContactItemsDao contactItemsDao;
  final CryptoWalletItemsDao cryptoWalletItemsDao;
  final IdentityItemsDao identityItemsDao;
  final LicenseKeyItemsDao licenseKeyItemsDao;
  final LoyaltyCardItemsDao loyaltyCardItemsDao;
  final OtpItemsDao otpItemsDao;
  final SshKeyItemsDao sshKeyItemsDao;
  final WifiItemsDao wifiItemsDao;
  final FileItemsDao fileItemsDao;
  final FileMetadataDao fileMetadataDao;
  final FileHistoryDao fileHistoryDao;
  final FileMetadataHistoryDao fileMetadataHistoryDao;
  final RecoveryCodesItemsDao recoveryCodesItemsDao;
  final RecoveryCodesDao recoveryCodesDao;
  final RecoveryCodesHistoryDao recoveryCodesHistoryDao;
  final RecoveryCodeValuesHistoryDao recoveryCodeValuesHistoryDao;

  Future<DbResult<Unit>> restoreRevision({
    required String historyId,
    bool recreate = false,
  }) async {
    try {
      final selected = await loader.loadHistorySnapshot(historyId);
      if (selected == null) {
        return Failure(DBCoreError.notFound(entity: 'HistorySnapshot', id: historyId));
      }

      if (!policy.isRestorable(selected)) {
        return Failure(DBCoreError.validation(
          code: 'history.restore.not_allowed',
          message: 'Восстановление для этого типа записи или состояния невозможно.',
          entity: selected.snapshot.type.name,
        ));
      }

      return await db.transaction(() async {
        final snapshot = selected.snapshot;
        final fields = selected.fields;

        // Check for missing required fields
        switch (snapshot.type) {
          case VaultItemType.apiKey:
            if (fields['service'] == null || fields['key'] == null) {
              return const Failure(DBCoreError.conflict(
                code: 'history.restore.missing_field',
                message: 'Нельзя восстановить запись: в снимке отсутствуют обязательные поля API Key',
                entity: 'apiKey',
              ));
            }
            break;
          case VaultItemType.password:
            if (fields['password'] == null) {
              return const Failure(DBCoreError.conflict(
                code: 'history.restore.missing_field',
                message: 'Нельзя восстановить запись: в снимке отсутствует обязательное поле "password"',
                entity: 'password',
              ));
            }
            break;
          case VaultItemType.bankCard:
            if (fields['cardNumber'] == null) {
              return const Failure(DBCoreError.conflict(
                code: 'history.restore.missing_field',
                message: 'Нельзя восстановить запись: в снимке отсутствует обязательное поле "cardNumber"',
                entity: 'bankCard',
              ));
            }
            break;
          case VaultItemType.loyaltyCard:
            if (fields['programName'] == null) {
              return const Failure(DBCoreError.conflict(
                code: 'history.restore.missing_field',
                message: 'Нельзя восстановить запись: в снимке отсутствует обязательное поле "programName"',
                entity: 'loyaltyCard',
              ));
            }
            break;
          case VaultItemType.otp:
            if (fields['type'] == null || fields['secret'] == null || fields['algorithm'] == null || fields['digits'] == null) {
              return const Failure(DBCoreError.conflict(
                code: 'history.restore.missing_field',
                message: 'Нельзя восстановить запись: в снимке отсутствуют обязательные поля OTP',
                entity: 'otp',
              ));
            }
            break;
          case VaultItemType.sshKey:
            if (fields['privateKey'] == null) {
              return const Failure(DBCoreError.conflict(
                code: 'history.restore.missing_field',
                message: 'Нельзя восстановить запись: в снимке отсутствует обязательное поле "privateKey"',
                entity: 'sshKey',
              ));
            }
            break;
          case VaultItemType.wifi:
            if (fields['ssid'] == null || fields['password'] == null) {
              return const Failure(DBCoreError.conflict(
                code: 'history.restore.missing_field',
                message: 'Нельзя восстановить запись: в снимке отсутствуют обязательные поля WiFi',
                entity: 'wifi',
              ));
            }
            break;
          case VaultItemType.recoveryCodes:
            final values = await recoveryCodeValuesHistoryDao.getRecoveryCodeValuesByHistoryId(historyId);
            if (fields['codesCount'] != null && (fields['codesCount'] as int) > 0 && values.isEmpty) {
               return const Failure(DBCoreError.conflict(
                code: 'history.restore.missing_recovery_code_value',
                message: 'Нельзя восстановить recovery codes: в снимке отсутствуют значения кодов',
                entity: 'recoveryCodes',
              ));
            }
            if (values.any((v) => v.code == null)) {
               return const Failure(DBCoreError.conflict(
                code: 'history.restore.missing_recovery_code_value',
                message: 'Нельзя восстановить recovery codes: в снимке отсутствуют значения кодов',
                entity: 'recoveryCodes',
              ));
            }
            break;
          default:
            break;
        }

        // 1. Restore base vault item
        await vaultItemsDao.upsertVaultItem(VaultItemsCompanion(
          id: Value(snapshot.itemId),
          type: Value(snapshot.type),
          name: Value(snapshot.name),
          description: Value(snapshot.description),
          categoryId: Value(snapshot.categoryId),
          iconRefId: Value(snapshot.iconRefId),
          isFavorite: Value(snapshot.isFavorite),
          isArchived: Value(snapshot.isArchived),
          isPinned: Value(snapshot.isPinned),
          isDeleted: Value(snapshot.isDeleted),
          createdAt: Value(snapshot.createdAt),
          modifiedAt: Value(DateTime.now()),
          lastUsedAt: Value(snapshot.lastUsedAt),
          archivedAt: Value(snapshot.archivedAt),
          deletedAt: Value(snapshot.deletedAt),
          recentScore: Value(snapshot.recentScore),
          usedCount: Value(snapshot.usedCount),
        ));

        // 2. Restore type-specific data
        switch (snapshot.type) {
          case VaultItemType.apiKey:
            final tokenTypeName = fields['tokenType'] as String?;
            final environmentName = fields['environment'] as String?;
            await apiKeyItemsDao.upsertApiKeyItem(ApiKeyItemsCompanion(
              itemId: Value(snapshot.itemId),
              service: Value(fields['service'] as String),
              key: Value(fields['key'] as String),
              tokenType: Value(tokenTypeName == null ? null : ApiKeyTokenType.values.byName(tokenTypeName)),
              environment: Value(environmentName == null ? null : ApiKeyEnvironment.values.byName(environmentName)),
              expiresAt: Value(fields['expiresAt'] as DateTime?),
              revokedAt: Value(fields['revokedAt'] as DateTime?),
              owner: Value(fields['owner'] as String?),
              baseUrl: Value(fields['baseUrl'] as String?),
            ));
            break;
          case VaultItemType.password:
            await passwordItemsDao.upsertPasswordItem(PasswordItemsCompanion(
              itemId: Value(snapshot.itemId),
              login: Value(fields['login'] as String?),
              email: Value(fields['email'] as String?),
              password: Value(fields['password'] as String),
              url: Value(fields['url'] as String?),
              expiresAt: Value(fields['expiresAt'] as DateTime?),
            ));
            break;
          case VaultItemType.note:
            await noteItemsDao.upsertNoteItem(NoteItemsCompanion(
              itemId: Value(snapshot.itemId),
              deltaJson: Value(fields['deltaJson'] as String),
              content: Value(fields['content'] as String),
            ));
            break;
          case VaultItemType.bankCard:
            final cardTypeName = fields['cardType'] as String?;
            final cardNetworkName = fields['cardNetwork'] as String?;
            await bankCardItemsDao.upsertBankCardItem(BankCardItemsCompanion(
              itemId: Value(snapshot.itemId),
              cardholderName: Value(fields['cardholderName'] as String?),
              cardNumber: Value(fields['cardNumber'] as String),
              cardType: Value(cardTypeName == null ? null : CardType.values.byName(cardTypeName)),
              cardTypeOther: Value(fields['cardTypeOther'] as String?),
              cardNetwork: Value(cardNetworkName == null ? null : CardNetwork.values.byName(cardNetworkName)),
              cardNetworkOther: Value(fields['cardNetworkOther'] as String?),
              expiryMonth: Value(fields['expiryMonth'] as String?),
              expiryYear: Value(fields['expiryYear'] as String?),
              cvv: Value(fields['cvv'] as String?),
              bankName: Value(fields['bankName'] as String?),
              accountNumber: Value(fields['accountNumber'] as String?),
              routingNumber: Value(fields['routingNumber'] as String?),
            ));
            break;
          case VaultItemType.certificate:
            final certificateFormatName = fields['certificateFormat'] as String?;
            final keyAlgorithmName = fields['keyAlgorithm'] as String?;
            await certificateItemsDao.upsertCertificateItem(CertificateItemsCompanion(
              itemId: Value(snapshot.itemId),
              certificateFormat: Value(certificateFormatName == null ? null : CertificateFormat.values.byName(certificateFormatName)),
              certificateFormatOther: Value(fields['certificateFormatOther'] as String?),
              certificatePem: Value(fields['certificatePem'] as String?),
              certificateBlob: Value(fields['certificateBlob'] as Uint8List?),
              privateKey: Value(fields['privateKey'] as String?),
              privateKeyPassword: Value(fields['privateKeyPassword'] as String?),
              passwordForPfx: Value(fields['passwordForPfx'] as String?),
              keyAlgorithm: Value(keyAlgorithmName == null ? null : CertificateKeyAlgorithm.values.byName(keyAlgorithmName)),
              keyAlgorithmOther: Value(fields['keyAlgorithmOther'] as String?),
              keySize: Value(fields['keySize'] as int?),
              serialNumber: Value(fields['serialNumber'] as String?),
              issuer: Value(fields['issuer'] as String?),
              subject: Value(fields['subject'] as String?),
              validFrom: Value(fields['validFrom'] as DateTime?),
              validTo: Value(fields['validTo'] as DateTime?),
            ));
            break;
          case VaultItemType.contact:
            await contactItemsDao.upsertContactItem(ContactItemsCompanion(
              itemId: Value(snapshot.itemId),
              firstName: Value(fields['firstName'] as String),
              middleName: Value(fields['middleName'] as String?),
              lastName: Value(fields['lastName'] as String?),
              phone: Value(fields['phone'] as String?),
              email: Value(fields['email'] as String?),
              company: Value(fields['company'] as String?),
              jobTitle: Value(fields['jobTitle'] as String?),
              address: Value(fields['address'] as String?),
              website: Value(fields['website'] as String?),
              birthday: Value(fields['birthday'] as DateTime?),
              isEmergencyContact: Value(fields['isEmergencyContact'] as bool? ?? false),
            ));
            break;
          case VaultItemType.cryptoWallet:
            final walletTypeName = fields['walletType'] as String?;
            final networkName = fields['network'] as String?;
            final derivationSchemeName = fields['derivationScheme'] as String?;
            await cryptoWalletItemsDao.upsertCryptoWalletItem(CryptoWalletItemsCompanion(
              itemId: Value(snapshot.itemId),
              walletType: Value(walletTypeName == null ? null : CryptoWalletType.values.byName(walletTypeName)),
              walletTypeOther: Value(fields['walletTypeOther'] as String?),
              network: Value(networkName == null ? null : CryptoNetwork.values.byName(networkName)),
              networkOther: Value(fields['networkOther'] as String?),
              mnemonic: Value(fields['mnemonic'] as String?),
              privateKey: Value(fields['privateKey'] as String?),
              derivationPath: Value(fields['derivationPath'] as String?),
              derivationScheme: Value(derivationSchemeName == null ? null : CryptoDerivationScheme.values.byName(derivationSchemeName)),
              derivationSchemeOther: Value(fields['derivationSchemeOther'] as String?),
              addresses: Value(fields['addresses'] as String?),
              xpub: Value(fields['xpub'] as String?),
              xprv: Value(fields['xprv'] as String?),
              hardwareDevice: Value(fields['hardwareDevice'] as String?),
              watchOnly: Value(fields['watchOnly'] as bool? ?? false),
            ));
            break;
          case VaultItemType.identity:
            await identityItemsDao.upsertIdentityItem(IdentityItemsCompanion(
              itemId: Value(snapshot.itemId),
              firstName: Value(fields['firstName'] as String?),
              middleName: Value(fields['middleName'] as String?),
              lastName: Value(fields['lastName'] as String?),
              displayName: Value(fields['displayName'] as String?),
              username: Value(fields['username'] as String?),
              email: Value(fields['email'] as String?),
              phone: Value(fields['phone'] as String?),
              address: Value(fields['address'] as String?),
              birthday: Value(fields['birthday'] as DateTime?),
              company: Value(fields['company'] as String?),
              jobTitle: Value(fields['jobTitle'] as String?),
              website: Value(fields['website'] as String?),
              taxId: Value(fields['taxId'] as String?),
              nationalId: Value(fields['nationalId'] as String?),
              passportNumber: Value(fields['passportNumber'] as String?),
              driverLicenseNumber: Value(fields['driverLicenseNumber'] as String?),
            ));
            break;
          case VaultItemType.licenseKey:
            final licenseTypeName = fields['licenseType'] as String?;
            await licenseKeyItemsDao.upsertLicenseKeyItem(LicenseKeyItemsCompanion(
              itemId: Value(snapshot.itemId),
              productName: Value(fields['productName'] as String),
              vendor: Value(fields['vendor'] as String?),
              licenseKey: Value(fields['licenseKey'] as String),
              licenseType: Value(licenseTypeName == null ? null : LicenseType.values.byName(licenseTypeName)),
              licenseTypeOther: Value(fields['licenseTypeOther'] as String?),
              accountEmail: Value(fields['accountEmail'] as String?),
              accountUsername: Value(fields['accountUsername'] as String?),
              purchaseEmail: Value(fields['purchaseEmail'] as String?),
              orderNumber: Value(fields['orderNumber'] as String?),
              purchaseDate: Value(fields['purchaseDate'] as DateTime?),
              purchasePrice: Value(fields['purchasePrice'] as double?),
              currency: Value(fields['currency'] as String?),
              validFrom: Value(fields['validFrom'] as DateTime?),
              validTo: Value(fields['validTo'] as DateTime?),
              renewalDate: Value(fields['renewalDate'] as DateTime?),
              seats: Value(fields['seats'] as int?),
              activationLimit: Value(fields['activationLimit'] as int?),
              activationsUsed: Value(fields['activationsUsed'] as int?),
            ));
            break;
          case VaultItemType.loyaltyCard:
            final barcodeTypeName = fields['barcodeType'] as String?;
            await loyaltyCardItemsDao.upsertLoyaltyCardItem(LoyaltyCardItemsCompanion(
              itemId: Value(snapshot.itemId),
              programName: Value(fields['programName'] as String),
              cardNumber: Value(fields['cardNumber'] as String?),
              barcodeValue: Value(fields['barcodeValue'] as String?),
              password: Value(fields['password'] as String?),
              barcodeType: Value(barcodeTypeName == null ? null : LoyaltyBarcodeType.values.byName(barcodeTypeName)),
              barcodeTypeOther: Value(fields['barcodeTypeOther'] as String?),
              issuer: Value(fields['issuer'] as String?),
              website: Value(fields['website'] as String?),
              phone: Value(fields['phone'] as String?),
              email: Value(fields['email'] as String?),
              validFrom: Value(fields['validFrom'] as DateTime?),
              validTo: Value(fields['validTo'] as DateTime?),
            ));
            break;
          case VaultItemType.otp:
            await otpItemsDao.upsertOtpItem(OtpItemsCompanion(
              itemId: Value(snapshot.itemId),
              type: Value<OtpType>(OtpType.values.byName(fields['type'] as String)),
              issuer: Value(fields['issuer'] as String?),
              accountName: Value(fields['accountName'] as String?),
              secret: Value<Uint8List>(fields['secret'] as Uint8List),
              algorithm: Value<OtpHashAlgorithm>(OtpHashAlgorithm.values.byName(fields['algorithm'] as String)),
              digits: Value<int>(fields['digits'] as int),
              period: Value(fields['period'] as int?),
              counter: Value(fields['counter'] as int?),
            ));
            break;
          case VaultItemType.sshKey:
            final keyTypeName = fields['keyType'] as String?;
            await sshKeyItemsDao.upsertSshKeyItem(SshKeyItemsCompanion(
              itemId: Value(snapshot.itemId),
              publicKey: Value(fields['publicKey'] as String?),
              privateKey: Value(fields['privateKey'] as String),
              keyType: Value(keyTypeName == null ? null : SshKeyType.values.byName(keyTypeName)),
              keyTypeOther: Value(fields['keyTypeOther'] as String?),
              keySize: Value(fields['keySize'] as int?),
            ));
            break;
          case VaultItemType.wifi:
            await wifiItemsDao.upsertWifiItem(WifiItemsCompanion(
              itemId: Value(snapshot.itemId),
              ssid: Value(fields['ssid'] as String),
              password: Value(fields['password'] as String),
              securityType: Value(fields['securityType'] == null ? null : WifiSecurityType.values.byName(fields['securityType'] as String)),
              securityTypeOther: Value(fields['securityTypeOther'] as String?),
              encryption: Value(fields['encryption'] == null ? null : WifiEncryptionType.values.byName(fields['encryption'] as String)),
              encryptionOther: Value(fields['encryptionOther'] as String?),
              hiddenSsid: Value(fields['hiddenSsid'] as bool? ?? false),
            ));
            break;
          case VaultItemType.file:
            String? metadataId;
            if (fields['metadataHistoryId'] != null) {
              final metaHistory = await fileMetadataHistoryDao.getFileMetadataHistoryById(fields['metadataHistoryId'] as String);
              if (metaHistory != null) {
                metadataId = metaHistory.metadataId ?? const Uuid().v4();
                await fileMetadataDao.upsertFileMetadata(FileMetadataCompanion(
                  id: Value(metadataId),
                  fileName: Value(metaHistory.fileName),
                  fileExtension: Value(metaHistory.fileExtension),
                  filePath: Value(metaHistory.filePath),
                  mimeType: Value(metaHistory.mimeType),
                  fileSize: Value(metaHistory.fileSize),
                  sha256: Value(metaHistory.sha256),
                  availabilityStatus: Value(metaHistory.availabilityStatus),
                  integrityStatus: Value(metaHistory.integrityStatus),
                  missingDetectedAt: Value(metaHistory.missingDetectedAt),
                  deletedAt: Value(metaHistory.deletedAt),
                  lastIntegrityCheckAt: Value(metaHistory.lastIntegrityCheckAt),
                ));
              }
            }
            await fileItemsDao.upsertFileItem(FileItemsCompanion(
              itemId: Value(snapshot.itemId),
              metadataId: Value(metadataId),
            ));
            break;
          case VaultItemType.recoveryCodes:
            await recoveryCodesItemsDao.upsertRecoveryCodesItem(RecoveryCodesItemsCompanion(
              itemId: Value(snapshot.itemId),
              generatedAt: Value(fields['generatedAt'] as DateTime?),
              oneTime: Value(fields['oneTime'] as bool? ?? false),
            ));
            
            final historyValues = await recoveryCodeValuesHistoryDao.getRecoveryCodeValuesByHistoryId(historyId);
            final liveValues = historyValues.map((h) => RecoveryCodesCompanion(
              itemId: Value(snapshot.itemId),
              code: Value(h.code!),
              used: Value(h.used),
              usedAt: Value(h.usedAt),
              position: Value(h.position),
            )).toList();
            
            await recoveryCodesDao.replaceRecoveryCodesForItem(
              itemId: snapshot.itemId,
              codes: liveValues,
            );
            break;
          case VaultItemType.document:
            return const Failure(DBCoreError.validation(
              code: 'history.restore.document_not_supported_yet',
              message: 'Восстановление документов из истории пока не поддерживается',
              entity: 'document',
            ));
        }

        return Success(unit);
      });
    } catch (e, s) {
      return Failure(DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s));
    }
  }
}
