import 'package:drift/drift.dart';
import 'package:result_dart/result_dart.dart';

import '../../daos/daos.dart';
import '../../errors/db_error.dart';
import '../../errors/db_result.dart';
import '../../main_store.dart';
import '../../tables/tables.dart';
import 'vault_history_normalized_loader.dart';
import 'vault_history_restore_policy_service.dart';

bool _isBlankString(Object? value) {
  return value == null || (value is String && value.trim().isEmpty);
}

DbResult<Unit>? _missingRequiredField({
  required String entity,
  required String fieldName,
  required Object? value,
}) {
  if (!_isBlankString(value)) return null;

  return Failure(
    DBCoreError.conflict(
      code: 'history.restore.missing_field',
      message:
          'Нельзя восстановить запись: в снимке отсутствует обязательное поле "$fieldName"',
      entity: entity,
    ),
  );
}

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

  Future<DbResult<Unit>> restoreRevision({
    required String historyId,
    bool recreate = false,
  }) async {
    try {
      final selected = await loader.loadHistorySnapshot(historyId);
      if (selected == null) {
        return Failure(
          DBCoreError.notFound(entity: 'HistorySnapshot', id: historyId),
        );
      }

      if (!policy.isRestorable(selected)) {
        return Failure(
          DBCoreError.validation(
            code: 'history.restore.not_allowed',
            message:
                'Восстановление для этого типа записи или состояния невозможно.',
            entity: selected.snapshot.type.name,
          ),
        );
      }

      return await db.transaction(() async {
        final snapshot = selected.snapshot;
        final fields = selected.fields;

        // Check for missing required fields
        switch (snapshot.type) {
          case VaultItemType.apiKey:
            if (fields['service'] == null) {
              return Failure(
                DBCoreError.conflict(
                  code: 'history.restore.missing_field',
                  message:
                      'Нельзя восстановить запись: в снимке отсутствует обязательное поле "service"',
                  entity: 'apiKey',
                ),
              );
            }
            if (fields['key'] == null) {
              return Failure(
                DBCoreError.conflict(
                  code: 'history.restore.missing_field',
                  message:
                      'Нельзя восстановить запись: в снимке отсутствует обязательное поле "key"',
                  entity: 'apiKey',
                ),
              );
            }
            break;
          case VaultItemType.password:
            if (fields['password'] == null) {
              return Failure(
                DBCoreError.conflict(
                  code: 'history.restore.missing_field',
                  message:
                      'Нельзя восстановить запись: в снимке отсутствует обязательное поле "password"',
                  entity: 'password',
                ),
              );
            }
            break;
          case VaultItemType.bankCard:
            if (fields['cardNumber'] == null) {
              return Failure(
                DBCoreError.conflict(
                  code: 'history.restore.missing_field',
                  message:
                      'Нельзя восстановить запись: в снимке отсутствует обязательное поле "cardNumber"',
                  entity: 'bankCard',
                ),
              );
            }
            break;
          case VaultItemType.loyaltyCard:
            if (fields['programName'] == null) {
              return Failure(
                DBCoreError.conflict(
                  code: 'history.restore.missing_field',
                  message:
                      'Нельзя восстановить запись: в снимке отсутствует обязательное поле "programName"',
                  entity: 'loyaltyCard',
                ),
              );
            }
            break;
          case VaultItemType.note:
            final deltaJsonError = _missingRequiredField(
              entity: 'note',
              fieldName: 'deltaJson',
              value: fields['deltaJson'],
            );
            if (deltaJsonError != null) return deltaJsonError;

            final contentError = _missingRequiredField(
              entity: 'note',
              fieldName: 'content',
              value: fields['content'],
            );
            if (contentError != null) return contentError;
            break;
          case VaultItemType.contact:
            final firstNameError = _missingRequiredField(
              entity: 'contact',
              fieldName: 'firstName',
              value: fields['firstName'],
            );
            if (firstNameError != null) return firstNameError;
            break;
          case VaultItemType.licenseKey:
            final productNameError = _missingRequiredField(
              entity: 'licenseKey',
              fieldName: 'productName',
              value: fields['productName'],
            );
            if (productNameError != null) return productNameError;

            final licenseKeyError = _missingRequiredField(
              entity: 'licenseKey',
              fieldName: 'licenseKey',
              value: fields['licenseKey'],
            );
            if (licenseKeyError != null) return licenseKeyError;
            break;
          case VaultItemType.otp:
            if (fields['type'] == null ||
                fields['secret'] == null ||
                fields['algorithm'] == null ||
                fields['digits'] == null) {
              return Failure(
                DBCoreError.conflict(
                  code: 'history.restore.missing_field',
                  message:
                      'Нельзя восстановить запись: в снимке отсутствуют обязательные поля OTP',
                  entity: 'otp',
                ),
              );
            }
            break;
          case VaultItemType.sshKey:
            if (fields['privateKey'] == null) {
              return Failure(
                DBCoreError.conflict(
                  code: 'history.restore.missing_field',
                  message:
                      'Нельзя восстановить запись: в снимке отсутствует обязательное поле "privateKey"',
                  entity: 'sshKey',
                ),
              );
            }
            break;
          case VaultItemType.wifi:
            if (fields['ssid'] == null || fields['password'] == null) {
              return Failure(
                DBCoreError.conflict(
                  code: 'history.restore.missing_field',
                  message:
                      'Нельзя восстановить запись: в снимке отсутствуют обязательные поля WiFi',
                  entity: 'wifi',
                ),
              );
            }
            break;
          default:
            break;
        }

        // 1. Restore base vault item
        await vaultItemsDao.upsertVaultItem(
          VaultItemsCompanion(
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
          ),
        );

        // 2. Restore type-specific data
        switch (snapshot.type) {
          case VaultItemType.apiKey:
            await apiKeyItemsDao.upsertApiKeyItem(
              ApiKeyItemsCompanion(
                itemId: Value(snapshot.itemId),
                service: Value(fields['service'] as String),
                key: Value(fields['key'] as String),
                tokenType: Value(
                  fields['tokenType'] != null
                      ? ApiKeyTokenType.values.firstWhere(
                          (e) => e.name == fields['tokenType'] as String,
                        )
                      : null,
                ),
                environment: Value(
                  fields['environment'] != null
                      ? ApiKeyEnvironment.values.firstWhere(
                          (e) => e.name == fields['environment'] as String,
                        )
                      : null,
                ),
                expiresAt: Value(fields['expiresAt'] as DateTime?),
                revokedAt: Value(fields['revokedAt'] as DateTime?),
                owner: Value(fields['owner'] as String?),
                baseUrl: Value(fields['baseUrl'] as String?),
              ),
            );
            break;
          case VaultItemType.password:
            await passwordItemsDao.upsertPasswordItem(
              PasswordItemsCompanion(
                itemId: Value(snapshot.itemId),
                login: Value(fields['login'] as String?),
                email: Value(fields['email'] as String?),
                password: Value(fields['password'] as String),
                url: Value(fields['url'] as String?),
                expiresAt: Value(fields['expiresAt'] as DateTime?),
              ),
            );
            break;
          case VaultItemType.note:
            await noteItemsDao.upsertNoteItem(
              NoteItemsCompanion(
                itemId: Value(snapshot.itemId),
                deltaJson: Value(fields['deltaJson'] as String),
                content: Value(fields['content'] as String),
              ),
            );
            break;
          case VaultItemType.bankCard:
            await bankCardItemsDao.upsertBankCardItem(
              BankCardItemsCompanion(
                itemId: Value(snapshot.itemId),
                cardholderName: Value(fields['cardholderName'] as String?),
                cardNumber: Value(fields['cardNumber'] as String),
                cardType: Value(
                  fields['cardType'] != null
                      ? CardType.values.firstWhere(
                          (e) => e.name == fields['cardType'] as String,
                        )
                      : null,
                ),
                cardTypeOther: Value(fields['cardTypeOther'] as String?),
                cardNetwork: Value(
                  fields['cardNetwork'] != null
                      ? CardNetwork.values.firstWhere(
                          (e) => e.name == fields['cardNetwork'] as String,
                        )
                      : null,
                ),
                cardNetworkOther: Value(fields['cardNetworkOther'] as String?),
                expiryMonth: Value(fields['expiryMonth'] as String?),
                expiryYear: Value(fields['expiryYear'] as String?),
                cvv: Value(fields['cvv'] as String?),
                bankName: Value(fields['bankName'] as String?),
                accountNumber: Value(fields['accountNumber'] as String?),
                routingNumber: Value(fields['routingNumber'] as String?),
              ),
            );
            break;
          case VaultItemType.certificate:
            await certificateItemsDao.upsertCertificateItem(
              CertificateItemsCompanion(
                itemId: Value(snapshot.itemId),
                certificateFormat: Value(
                  fields['certificateFormat'] != null
                      ? CertificateFormat.values.firstWhere(
                          (e) =>
                              e.name == fields['certificateFormat'] as String,
                        )
                      : null,
                ),
                certificateFormatOther: Value(
                  fields['certificateFormatOther'] as String?,
                ),
                certificatePem: Value(fields['certificatePem'] as String?),
                certificateBlob: Value(fields['certificateBlob'] as Uint8List?),
                privateKey: Value(fields['privateKey'] as String?),
                privateKeyPassword: Value(
                  fields['privateKeyPassword'] as String?,
                ),
                passwordForPfx: Value(fields['passwordForPfx'] as String?),
                keyAlgorithm: Value(
                  fields['keyAlgorithm'] != null
                      ? CertificateKeyAlgorithm.values.firstWhere(
                          (e) => e.name == fields['keyAlgorithm'] as String,
                        )
                      : null,
                ),
                keyAlgorithmOther: Value(
                  fields['keyAlgorithmOther'] as String?,
                ),
                keySize: Value(fields['keySize'] as int?),
                serialNumber: Value(fields['serialNumber'] as String?),
                issuer: Value(fields['issuer'] as String?),
                subject: Value(fields['subject'] as String?),
                validFrom: Value(fields['validFrom'] as DateTime?),
                validTo: Value(fields['validTo'] as DateTime?),
              ),
            );
            break;
          case VaultItemType.contact:
            await contactItemsDao.upsertContactItem(
              ContactItemsCompanion(
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
                isEmergencyContact: Value(fields['isEmergencyContact'] as bool),
              ),
            );
            break;
          case VaultItemType.cryptoWallet:
            await cryptoWalletItemsDao.upsertCryptoWalletItem(
              CryptoWalletItemsCompanion(
                itemId: Value(snapshot.itemId),
                walletType: Value(
                  fields['walletType'] != null
                      ? CryptoWalletType.values.firstWhere(
                          (e) => e.name == fields['walletType'] as String,
                        )
                      : null,
                ),
                walletTypeOther: Value(fields['walletTypeOther'] as String?),
                network: Value(
                  fields['network'] != null
                      ? CryptoNetwork.values.firstWhere(
                          (e) => e.name == fields['network'] as String,
                        )
                      : null,
                ),
                networkOther: Value(fields['networkOther'] as String?),
                mnemonic: Value(fields['mnemonic'] as String?),
                privateKey: Value(fields['privateKey'] as String?),
                derivationPath: Value(fields['derivationPath'] as String?),
                derivationScheme: Value(
                  fields['derivationScheme'] != null
                      ? CryptoDerivationScheme.values.firstWhere(
                          (e) => e.name == fields['derivationScheme'] as String,
                        )
                      : null,
                ),
                derivationSchemeOther: Value(
                  fields['derivationSchemeOther'] as String?,
                ),
                addresses: Value(fields['addresses'] as String?),
                xpub: Value(fields['xpub'] as String?),
                xprv: Value(fields['xprv'] as String?),
                hardwareDevice: Value(fields['hardwareDevice'] as String?),
                watchOnly: Value(fields['watchOnly'] as bool),
              ),
            );
            break;
          case VaultItemType.identity:
            await identityItemsDao.upsertIdentityItem(
              IdentityItemsCompanion(
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
                driverLicenseNumber: Value(
                  fields['driverLicenseNumber'] as String?,
                ),
              ),
            );
            break;
          case VaultItemType.licenseKey:
            await licenseKeyItemsDao.upsertLicenseKeyItem(
              LicenseKeyItemsCompanion(
                itemId: Value(snapshot.itemId),
                productName: Value(fields['productName'] as String),
                vendor: Value(fields['vendor'] as String?),
                licenseKey: Value(fields['licenseKey'] as String),
                licenseType: Value(
                  fields['licenseType'] != null
                      ? LicenseType.values.firstWhere(
                          (e) => e.name == fields['licenseType'] as String,
                        )
                      : null,
                ),
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
              ),
            );
            break;
          case VaultItemType.loyaltyCard:
            await loyaltyCardItemsDao.upsertLoyaltyCardItem(
              LoyaltyCardItemsCompanion(
                itemId: Value(snapshot.itemId),
                programName: Value(fields['programName'] as String),
                cardNumber: Value(fields['cardNumber'] as String?),
                barcodeValue: Value(fields['barcodeValue'] as String?),
                password: Value(fields['password'] as String?),
                barcodeType: Value(
                  fields['barcodeType'] != null
                      ? LoyaltyBarcodeType.values.firstWhere(
                          (e) => e.name == fields['barcodeType'] as String,
                        )
                      : null,
                ),
                barcodeTypeOther: Value(fields['barcodeTypeOther'] as String?),
                issuer: Value(fields['issuer'] as String?),
                website: Value(fields['website'] as String?),
                phone: Value(fields['phone'] as String?),
                email: Value(fields['email'] as String?),
                validFrom: Value(fields['validFrom'] as DateTime?),
                validTo: Value(fields['validTo'] as DateTime?),
              ),
            );
            break;
          case VaultItemType.otp:
            await otpItemsDao.upsertOtpItem(
              OtpItemsCompanion(
                itemId: Value(snapshot.itemId),
                type: Value(
                  OtpType.values.firstWhere(
                    (e) => e.name == fields['type'] as String,
                  ),
                ),
                issuer: Value(fields['issuer'] as String?),
                accountName: Value(fields['accountName'] as String?),
                secret: Value(fields['secret'] as Uint8List),
                algorithm: Value(
                  OtpHashAlgorithm.values.firstWhere(
                    (e) => e.name == fields['algorithm'] as String,
                  ),
                ),
                digits: Value(fields['digits'] as int),
                period: Value(fields['period'] as int?),
                counter: Value(fields['counter'] as int?),
              ),
            );
            break;
          case VaultItemType.sshKey:
            await sshKeyItemsDao.upsertSshKeyItem(
              SshKeyItemsCompanion(
                itemId: Value(snapshot.itemId),
                publicKey: Value(fields['publicKey'] as String?),
                privateKey: Value(fields['privateKey'] as String),
                keyType: Value(
                  fields['keyType'] != null
                      ? SshKeyType.values.firstWhere(
                          (e) => e.name == fields['keyType'] as String,
                        )
                      : null,
                ),
                keyTypeOther: Value(fields['keyTypeOther'] as String?),
                keySize: Value(fields['keySize'] as int?),
              ),
            );
            break;
          case VaultItemType.wifi:
            await wifiItemsDao.upsertWifiItem(
              WifiItemsCompanion(
                itemId: Value(snapshot.itemId),
                ssid: Value(fields['ssid'] as String),
                password: Value(fields['password'] as String),
                securityType: Value(
                  fields['securityType'] != null
                      ? WifiSecurityType.values.firstWhere(
                          (e) => e.name == fields['securityType'] as String,
                        )
                      : null,
                ),
                securityTypeOther: Value(
                  fields['securityTypeOther'] as String?,
                ),
                encryption: Value(
                  fields['encryption'] != null
                      ? WifiEncryptionType.values.firstWhere(
                          (e) => e.name == fields['encryption'] as String,
                        )
                      : null,
                ),
                encryptionOther: Value(fields['encryptionOther'] as String?),
                hiddenSsid: Value(fields['hiddenSsid'] as bool),
              ),
            );
            break;

          case VaultItemType.document:
            return Failure(
              const DBCoreError.validation(
                code: 'history.restore.document_not_supported_yet',
                message:
                    'Восстановление документов из истории пока не поддерживается',
                entity: 'document',
              ),
            );
          case VaultItemType.file:
            return Failure(
              const DBCoreError.validation(
                code: 'history.restore.file_not_supported_yet',
                message:
                    'Восстановление файлов из истории пока не поддерживается',
                entity: 'file',
              ),
            );
          case VaultItemType.recoveryCodes:
            return Failure(
              const DBCoreError.validation(
                code: 'history.restore.recovery_codes_not_supported_yet',
                message:
                    'Восстановление recovery codes из истории пока не поддерживается',
                entity: 'recoveryCodes',
              ),
            );
        }

        return Success(unit);
      });
    } catch (e, s) {
      return Failure(
        DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s),
      );
    }
  }
}
