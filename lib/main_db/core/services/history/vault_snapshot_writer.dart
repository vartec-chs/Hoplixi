import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/dao/api_key/api_key_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/bank_card/bank_card_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/certificate/certificate_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/contact/contact_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/crypto_wallet/crypto_wallet_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/file/file_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/file/file_metadata_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/identity/identity_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/license_key/license_key_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/loyalty_card/loyalty_card_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/note/note_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/otp/otp_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/password/password_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/recovery_codes/recovery_code_values_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/recovery_codes/recovery_codes_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/ssh_key/ssh_key_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/vault_items/vault_snapshots_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/wifi/wifi_history_dao.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/services/relations/snapshot_relations_service.dart';
import 'package:hoplixi/main_db/core/tables/file/file_metadata_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_snapshots_history.dart';
import 'package:uuid/uuid.dart';

import '../../main_store.dart';

class VaultSnapshotWriter {
  VaultSnapshotWriter({
    required this.vaultSnapshotsHistoryDao,
    required this.snapshotRelationsService,
    required this.apiKeyHistoryDao,
    required this.passwordHistoryDao,
    required this.noteHistoryDao,
    required this.bankCardHistoryDao,
    required this.certificateHistoryDao,
    required this.contactHistoryDao,
    required this.cryptoWalletHistoryDao,
    required this.fileHistoryDao,
    required this.fileMetadataHistoryDao,
    required this.identityHistoryDao,
    required this.licenseKeyHistoryDao,
    required this.loyaltyCardHistoryDao,
    required this.otpHistoryDao,
    required this.recoveryCodesHistoryDao,
    required this.recoveryCodeValuesHistoryDao,
    required this.sshKeyHistoryDao,
    required this.wifiHistoryDao,
  });

  final VaultSnapshotsHistoryDao vaultSnapshotsHistoryDao;
  final SnapshotRelationsService snapshotRelationsService;
  final ApiKeyHistoryDao apiKeyHistoryDao;
  final PasswordHistoryDao passwordHistoryDao;
  final NoteHistoryDao noteHistoryDao;
  final BankCardHistoryDao bankCardHistoryDao;
  final CertificateHistoryDao certificateHistoryDao;
  final ContactHistoryDao contactHistoryDao;
  final CryptoWalletHistoryDao cryptoWalletHistoryDao;
  final FileHistoryDao fileHistoryDao;
  final FileMetadataHistoryDao fileMetadataHistoryDao;
  final IdentityHistoryDao identityHistoryDao;
  final LicenseKeyHistoryDao licenseKeyHistoryDao;
  final LoyaltyCardHistoryDao loyaltyCardHistoryDao;
  final OtpHistoryDao otpHistoryDao;
  final RecoveryCodesHistoryDao recoveryCodesHistoryDao;
  final RecoveryCodeValuesHistoryDao recoveryCodeValuesHistoryDao;
  final SshKeyHistoryDao sshKeyHistoryDao;
  final WifiHistoryDao wifiHistoryDao;

  Future<String> writeSnapshot({
    required VaultItemType type,
    required Object view,
    required VaultEventHistoryAction action,
    bool includeSecrets = true,
    bool includeRelations = true,
  }) async {
    return switch (type) {
      VaultItemType.apiKey => _writeApiKeySnapshot(
          view as ApiKeyViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      VaultItemType.password => _writePasswordSnapshot(
          view as PasswordViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      VaultItemType.note => _writeNoteSnapshot(
          view as NoteViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      VaultItemType.bankCard => _writeBankCardSnapshot(
          view as BankCardViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      VaultItemType.certificate => _writeCertificateSnapshot(
          view as CertificateViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      VaultItemType.contact => _writeContactSnapshot(
          view as ContactViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      VaultItemType.cryptoWallet => _writeCryptoWalletSnapshot(
          view as CryptoWalletViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      VaultItemType.file => _writeFileSnapshot(
          view as FileViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      VaultItemType.identity => _writeIdentitySnapshot(
          view as IdentityViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      VaultItemType.licenseKey => _writeLicenseKeySnapshot(
          view as LicenseKeyViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      VaultItemType.loyaltyCard => _writeLoyaltyCardSnapshot(
          view as LoyaltyCardViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      VaultItemType.otp => _writeOtpSnapshot(
          view as OtpViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      VaultItemType.recoveryCodes => _writeRecoveryCodesSnapshot(
          view as RecoveryCodesViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      VaultItemType.sshKey => _writeSshKeySnapshot(
          view as SshKeyViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      VaultItemType.wifi => _writeWifiSnapshot(
          view as WifiViewDto,
          action: action,
          includeSecrets: includeSecrets,
          includeRelations: includeRelations,
        ),
      VaultItemType.document => _writeBaseSnapshot((view as DocumentViewDto).item, action),
      _ => throw UnsupportedError('Snapshot is not implemented for $type'),
    };
  }

  Future<String> _writeApiKeySnapshot(
    ApiKeyViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final apiKey = view.apiKey;
    final historyId = await _writeBaseSnapshot(item, action);

    await apiKeyHistoryDao.insertApiKeyHistory(
      ApiKeyHistoryCompanion.insert(
        historyId: historyId,
        service: apiKey.service,
        key: Value(includeSecrets ? apiKey.key : null),
        tokenType: Value(apiKey.tokenType),
        tokenTypeOther: Value(apiKey.tokenTypeOther),
        environment: Value(apiKey.environment),
        environmentOther: Value(apiKey.environmentOther),
        expiresAt: Value(apiKey.expiresAt),
        revoked: Value(apiKey.isRevoked),
        revokedAt: Value(apiKey.revokedAt),
        rotationPeriodDays: Value(apiKey.rotationPeriodDays),
        lastRotatedAt: Value(apiKey.lastRotatedAt),
        owner: Value(apiKey.owner),
        baseUrl: Value(apiKey.baseUrl),
        scopesText: Value(apiKey.scopesText),
      ),
    );

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writePasswordSnapshot(
    PasswordViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final password = view.password;
    final historyId = await _writeBaseSnapshot(item, action);

    await passwordHistoryDao.insertPasswordHistory(
      PasswordHistoryCompanion.insert(
        historyId: historyId,
        login: Value(password.login),
        email: Value(password.email),
        password: Value(includeSecrets ? password.password : null),
        url: Value(password.url),
        expiresAt: Value(password.expiresAt),
      ),
    );

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writeNoteSnapshot(
    NoteViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final note = view.note;
    final historyId = await _writeBaseSnapshot(item, action);

    await noteHistoryDao.insertNoteHistory(
      NoteHistoryCompanion.insert(
        historyId: historyId,
        deltaJson: Value(includeSecrets ? note.deltaJson : null),
        content: Value(includeSecrets ? note.content : null),
      ),
    );

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writeBankCardSnapshot(
    BankCardViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final bankCard = view.bankCard;
    final historyId = await _writeBaseSnapshot(item, action);

    await bankCardHistoryDao.insertBankCardHistory(
      BankCardHistoryCompanion.insert(
        historyId: historyId,
        cardholderName: Value(bankCard.cardholderName),
        cardNumber: Value(includeSecrets ? bankCard.cardNumber : null),
        cardType: Value(bankCard.cardType),
        cardTypeOther: Value(bankCard.cardTypeOther),
        cardNetwork: Value(bankCard.cardNetwork),
        cardNetworkOther: Value(bankCard.cardNetworkOther),
        expiryMonth: Value(bankCard.expiryMonth),
        expiryYear: Value(bankCard.expiryYear),
        cvv: Value(includeSecrets ? bankCard.cvv : null),
        bankName: Value(bankCard.bankName),
        accountNumber: Value(bankCard.accountNumber),
        routingNumber: Value(bankCard.routingNumber),
      ),
    );

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writeCertificateSnapshot(
    CertificateViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final cert = view.certificate;
    final historyId = await _writeBaseSnapshot(item, action);

    await certificateHistoryDao.insertCertificateHistory(
      CertificateHistoryCompanion.insert(
        historyId: historyId,
        certificateFormat: Value(cert.certificateFormat),
        certificateFormatOther: Value(cert.certificateFormatOther),
        certificatePem: Value(cert.certificatePem),
        certificateBlob: Value(cert.certificateBlob),
        privateKey: Value(includeSecrets ? cert.privateKey : null),
        privateKeyPassword: Value(includeSecrets ? cert.privateKeyPassword : null),
        passwordForPfx: Value(includeSecrets ? cert.passwordForPfx : null),
        keyAlgorithm: Value(cert.keyAlgorithm),
        keyAlgorithmOther: Value(cert.keyAlgorithmOther),
        keySize: Value(cert.keySize),
        serialNumber: Value(cert.serialNumber),
        issuer: Value(cert.issuer),
        subject: Value(cert.subject),
        validFrom: Value(cert.validFrom),
        validTo: Value(cert.validTo),
      ),
    );

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writeContactSnapshot(
    ContactViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final contact = view.contact;
    final historyId = await _writeBaseSnapshot(item, action);

    await contactHistoryDao.insertContactHistory(
      ContactHistoryCompanion.insert(
        historyId: historyId,
        firstName: contact.firstName,
        middleName: Value(contact.middleName),
        lastName: Value(contact.lastName),
        phone: Value(contact.phone),
        email: Value(contact.email),
        company: Value(contact.company),
        jobTitle: Value(contact.jobTitle),
        address: Value(contact.address),
        website: Value(contact.website),
        birthday: Value(contact.birthday),
        isEmergencyContact: Value(contact.isEmergencyContact),
      ),
    );

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writeCryptoWalletSnapshot(
    CryptoWalletViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final wallet = view.cryptoWallet;
    final historyId = await _writeBaseSnapshot(item, action);

    await cryptoWalletHistoryDao.insertCryptoWalletHistory(
      CryptoWalletHistoryCompanion.insert(
        historyId: historyId,
        walletType: Value(wallet.walletType),
        walletTypeOther: Value(wallet.walletTypeOther),
        network: Value(wallet.network),
        networkOther: Value(wallet.networkOther),
        mnemonic: Value(includeSecrets ? wallet.mnemonic : null),
        privateKey: Value(includeSecrets ? wallet.privateKey : null),
        derivationPath: Value(wallet.derivationPath),
        derivationScheme: Value(wallet.derivationScheme),
        derivationSchemeOther: Value(wallet.derivationSchemeOther),
        addresses: Value(wallet.addresses),
        xpub: Value(wallet.xpub),
        xprv: Value(includeSecrets ? wallet.xprv : null),
        hardwareDevice: Value(wallet.hardwareDevice),
        watchOnly: Value(wallet.watchOnly),
      ),
    );

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writeFileSnapshot(
    FileViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final historyId = await _writeBaseSnapshot(item, action);

    String? metadataHistoryId;
    if (view.metadata != null) {
      final m = view.metadata!;
      metadataHistoryId = const Uuid().v4();
      await fileMetadataHistoryDao.insertFileMetadataHistory(
        FileMetadataHistoryCompanion.insert(
          id: Value(metadataHistoryId),
          historyId: Value(historyId),
          ownerKind: const Value(FileMetadataHistoryOwnerKind.fileItemHistory),
          ownerId: Value(historyId),
          metadataId: Value(m.id),
          fileName: m.fileName,
          fileExtension: Value(m.fileExtension),
          filePath: Value(m.filePath),
          mimeType: m.mimeType,
          fileSize: m.fileSize,
          sha256: Value(m.sha256),
          availabilityStatus: Value(m.availabilityStatus),
          integrityStatus: Value(m.integrityStatus),
          missingDetectedAt: Value(m.missingDetectedAt),
          deletedAt: Value(m.deletedAt),
          lastIntegrityCheckAt: Value(m.lastIntegrityCheckAt),
        ),
      );
    }

    await fileHistoryDao.insertFileHistory(
      FileHistoryCompanion.insert(
        historyId: historyId,
        metadataHistoryId: Value(metadataHistoryId),
      ),
    );

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writeIdentitySnapshot(
    IdentityViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final identity = view.identity;
    final historyId = await _writeBaseSnapshot(item, action);

    await identityHistoryDao.insertIdentityHistory(
      IdentityHistoryCompanion.insert(
        historyId: historyId,
        firstName: Value(identity.firstName),
        middleName: Value(identity.middleName),
        lastName: Value(identity.lastName),
        displayName: Value(identity.displayName),
        username: Value(identity.username),
        email: Value(identity.email),
        phone: Value(identity.phone),
        address: Value(identity.address),
        birthday: Value(identity.birthday),
        company: Value(identity.company),
        jobTitle: Value(identity.jobTitle),
        website: Value(identity.website),
        taxId: Value(identity.taxId),
        nationalId: Value(identity.nationalId),
        passportNumber: Value(identity.passportNumber),
        driverLicenseNumber: Value(identity.driverLicenseNumber),
      ),
    );

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writeLicenseKeySnapshot(
    LicenseKeyViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final lk = view.licenseKey;
    final historyId = await _writeBaseSnapshot(item, action);

    await licenseKeyHistoryDao.insertLicenseKeyHistory(
      LicenseKeyHistoryCompanion.insert(
        historyId: historyId,
        productName: lk.productName,
        vendor: Value(lk.vendor),
        licenseKey: Value(includeSecrets ? lk.licenseKey : null),
        licenseType: Value(lk.licenseType),
        licenseTypeOther: Value(lk.licenseTypeOther),
        accountEmail: Value(lk.accountEmail),
        accountUsername: Value(lk.accountUsername),
        purchaseEmail: Value(lk.purchaseEmail),
        orderNumber: Value(lk.orderNumber),
        purchaseDate: Value(lk.purchaseDate),
        purchasePrice: Value(lk.purchasePrice),
        currency: Value(lk.currency),
        validFrom: Value(lk.validFrom),
        validTo: Value(lk.validTo),
        renewalDate: Value(lk.renewalDate),
        seats: Value(lk.seats),
        activationLimit: Value(lk.activationLimit),
        activationsUsed: Value(lk.activationsUsed),
      ),
    );

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writeLoyaltyCardSnapshot(
    LoyaltyCardViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final card = view.loyaltyCard;
    final historyId = await _writeBaseSnapshot(item, action);

    await loyaltyCardHistoryDao.insertLoyaltyCardHistory(
      LoyaltyCardHistoryCompanion.insert(
        historyId: historyId,
        programName: card.programName,
        cardNumber: Value(includeSecrets ? card.cardNumber : null),
        barcodeValue: Value(includeSecrets ? card.barcodeValue : null),
        password: Value(includeSecrets ? card.password : null),
        barcodeType: Value(card.barcodeType),
        barcodeTypeOther: Value(card.barcodeTypeOther),
        issuer: Value(card.issuer),
        website: Value(card.website),
        phone: Value(card.phone),
        email: Value(card.email),
        validFrom: Value(card.validFrom),
        validTo: Value(card.validTo),
      ),
    );

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writeOtpSnapshot(
    OtpViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final otp = view.otp;
    final historyId = await _writeBaseSnapshot(item, action);

    await otpHistoryDao.insertOtpHistory(
      OtpHistoryCompanion.insert(
        historyId: historyId,
        type: Value(otp.type),
        issuer: Value(otp.issuer),
        accountName: Value(otp.accountName),
        secret: Value(includeSecrets ? otp.secret : null),
        algorithm: Value(otp.algorithm),
        digits: Value(otp.digits),
        period: Value(otp.period),
        counter: Value(otp.counter),
      ),
    );

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writeRecoveryCodesSnapshot(
    RecoveryCodesViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final rc = view.recoveryCodes;
    final historyId = await _writeBaseSnapshot(item, action);

    await recoveryCodesHistoryDao.insertRecoveryCodesHistory(
      RecoveryCodesHistoryCompanion.insert(
        historyId: historyId,
        codesCount: Value(rc.codesCount),
        usedCount: Value(rc.usedCount),
        generatedAt: Value(rc.generatedAt),
        oneTime: Value(rc.oneTime),
      ),
    );

    if (view.codes.isNotEmpty) {
      final codeCompanions = view.codes.map((c) => RecoveryCodeValuesHistoryCompanion.insert(
        historyId: historyId,
        originalCodeId: Value(c.id),
        code: Value(includeSecrets ? c.code : null),
        used: Value(c.used),
        usedAt: Value(c.usedAt),
        position: Value(c.position),
      )).toList();
      await recoveryCodeValuesHistoryDao.insertRecoveryCodeValuesHistoryBatch(codeCompanions);
    }

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writeSshKeySnapshot(
    SshKeyViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final sk = view.sshKey;
    final historyId = await _writeBaseSnapshot(item, action);

    await sshKeyHistoryDao.insertSshKeyHistory(
      SshKeyHistoryCompanion.insert(
        historyId: historyId,
        publicKey: Value(sk.publicKey),
        privateKey: Value(includeSecrets ? sk.privateKey : null),
        keyType: Value(sk.keyType),
        keyTypeOther: Value(sk.keyTypeOther),
        keySize: Value(sk.keySize),
      ),
    );

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writeWifiSnapshot(
    WifiViewDto view, {
    required VaultEventHistoryAction action,
    required bool includeSecrets,
    required bool includeRelations,
  }) async {
    final item = view.item;
    final wifi = view.wifi;
    final historyId = await _writeBaseSnapshot(item, action);

    await wifiHistoryDao.insertWifiHistory(
      WifiHistoryCompanion.insert(
        historyId: historyId,
        ssid: wifi.ssid,
        password: Value(includeSecrets ? wifi.password : null),
        securityType: Value(wifi.securityType),
        securityTypeOther: Value(wifi.securityTypeOther),
        encryption: Value(wifi.encryption),
        encryptionOther: Value(wifi.encryptionOther),
        hiddenSsid: Value(wifi.hiddenSsid),
      ),
    );

    if (includeRelations) {
      await _snapshotRelations(historyId, item.itemId);
    }

    return historyId;
  }

  Future<String> _writeBaseSnapshot(
    VaultItemViewDto item,
    VaultEventHistoryAction action,
  ) async {
    final historyId = const Uuid().v4();
    final now = DateTime.now();

    final categoryHistoryId = await snapshotRelationsService.snapshotCategoryForItem(
      categoryId: item.categoryId,
      itemId: item.itemId,
      snapshotId: historyId,
    );

    await vaultSnapshotsHistoryDao.insertVaultSnapshot(
      VaultSnapshotsHistoryCompanion.insert(
        id: Value(historyId),
        itemId: item.itemId,
        action: action,
        type: item.type,
        name: item.name,
        description: Value(item.description),
        categoryId: Value(item.categoryId),
        categoryHistoryId: Value(categoryHistoryId),
        iconRefId: Value(item.iconRefId),
        usedCount: Value(item.usedCount),
        isFavorite: Value(item.isFavorite),
        isArchived: Value(item.isArchived),
        isPinned: Value(item.isPinned),
        isDeleted: Value(item.isDeleted),
        createdAt: item.createdAt,
        modifiedAt: item.modifiedAt,
        lastUsedAt: Value(item.lastUsedAt),
        archivedAt: Value(item.archivedAt),
        deletedAt: Value(item.deletedAt),
        recentScore: Value(item.recentScore),
        historyCreatedAt: Value(now),
      ),
    );

    return historyId;
  }

  Future<void> _snapshotRelations(String historyId, String itemId) async {
    await snapshotRelationsService.snapshotTagsForItem(
      historyId: historyId,
      itemId: itemId,
    );

    await snapshotRelationsService.snapshotLinksForItem(
      historyId: historyId,
      itemId: itemId,
    );
  }
}
