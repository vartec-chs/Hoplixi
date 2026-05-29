import 'package:hoplixi/vault_db/core/repositories/repositories.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart';
import 'package:hoplixi/vault_db/core/services/history/history.dart';
import 'package:hoplixi/vault_db/core/services/utils/vault_typed_view_resolver.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

import '../relations/snapshot_relations_service.dart';

class VaultHistoryServiceAssembly {
  VaultHistoryServiceAssembly({required this.db, required this.repos});

  final VaultDB db;
  final VaultRepositories repos;

  late final VaultTypedViewResolver viewResolver = VaultTypedViewResolver(
    repos,
  );

  late final VaultItemHistoryModules historyModules = VaultItemHistoryModules([
    VaultItemHistoryModule(
      type: VaultItemType.apiKey,
      normalizer: ApiKeyHistoryNormalizer(
        apiKeyHistoryDao: db.apiKeyHistoryDao,
        apiKeyRepository: repos.apiKey,
      ),
      restoreHandler: ApiKeyHistoryRestoreHandler(
        apiKeyItemsDao: db.apiKeyItemsDao,
      ),
      snapshotHandler: ApiKeySnapshotHandler(
        apiKeyHistoryDao: db.apiKeyHistoryDao,
      ),
      cardReader: ApiKeyHistoryCardReader(
        apiKeyHistoryDao: db.apiKeyHistoryDao,
      ),
    ),
    VaultItemHistoryModule(
      type: VaultItemType.password,
      normalizer: PasswordHistoryNormalizer(
        passwordHistoryDao: db.passwordHistoryDao,
        passwordRepository: repos.password,
      ),
      restoreHandler: PasswordHistoryRestoreHandler(
        passwordItemsDao: db.passwordItemsDao,
      ),
      snapshotHandler: PasswordSnapshotHandler(
        passwordHistoryDao: db.passwordHistoryDao,
      ),
      cardReader: PasswordHistoryCardReader(
        passwordHistoryDao: db.passwordHistoryDao,
      ),
    ),
    VaultItemHistoryModule(
      type: VaultItemType.bankCard,
      normalizer: BankCardHistoryNormalizer(
        bankCardHistoryDao: db.bankCardHistoryDao,
        bankCardRepository: repos.bankCard,
      ),
      restoreHandler: BankCardHistoryRestoreHandler(
        bankCardItemsDao: db.bankCardItemsDao,
      ),
      snapshotHandler: BankCardSnapshotHandler(
        bankCardHistoryDao: db.bankCardHistoryDao,
      ),
      cardReader: BankCardHistoryCardReader(
        bankCardHistoryDao: db.bankCardHistoryDao,
      ),
    ),
    VaultItemHistoryModule(
      type: VaultItemType.certificate,
      normalizer: CertificateHistoryNormalizer(
        certificateHistoryDao: db.certificateHistoryDao,
        certificateRepository: repos.certificate,
      ),
      restoreHandler: CertificateHistoryRestoreHandler(
        certificateItemsDao: db.certificateItemsDao,
      ),
      snapshotHandler: CertificateSnapshotHandler(
        certificateHistoryDao: db.certificateHistoryDao,
      ),
      cardReader: CertificateHistoryCardReader(
        certificateHistoryDao: db.certificateHistoryDao,
      ),
    ),
    VaultItemHistoryModule(
      type: VaultItemType.contact,
      normalizer: ContactHistoryNormalizer(
        contactHistoryDao: db.contactHistoryDao,
        contactRepository: repos.contact,
      ),
      restoreHandler: ContactHistoryRestoreHandler(
        contactItemsDao: db.contactItemsDao,
      ),
      snapshotHandler: ContactSnapshotHandler(
        contactHistoryDao: db.contactHistoryDao,
      ),
      cardReader: ContactHistoryCardReader(
        contactHistoryDao: db.contactHistoryDao,
      ),
    ),
    VaultItemHistoryModule(
      type: VaultItemType.cryptoWallet,
      normalizer: CryptoWalletHistoryNormalizer(
        cryptoWalletHistoryDao: db.cryptoWalletHistoryDao,
        cryptoWalletRepository: repos.cryptoWallet,
      ),
      restoreHandler: CryptoWalletHistoryRestoreHandler(
        cryptoWalletItemsDao: db.cryptoWalletItemsDao,
      ),
      snapshotHandler: CryptoWalletSnapshotHandler(
        cryptoWalletHistoryDao: db.cryptoWalletHistoryDao,
      ),
      cardReader: CryptoWalletHistoryCardReader(
        cryptoWalletHistoryDao: db.cryptoWalletHistoryDao,
      ),
    ),
    VaultItemHistoryModule(
      type: VaultItemType.file,
      normalizer: FileHistoryNormalizer(
        fileHistoryDao: db.fileHistoryDao,
        fileMetadataHistoryDao: db.fileMetadataHistoryDao,
        fileRepository: repos.file,
      ),
      restoreHandler: FileHistoryRestoreHandler(
        fileItemsDao: db.fileItemsDao,
        fileMetadataDao: db.fileMetadataDao,
      ),
      snapshotHandler: FileSnapshotHandler(
        fileHistoryDao: db.fileHistoryDao,
        fileMetadataHistoryDao: db.fileMetadataHistoryDao,
      ),
      cardReader: FileHistoryCardReader(
        fileHistoryDao: db.fileHistoryDao,
        fileMetadataHistoryDao: db.fileMetadataHistoryDao,
      ),
    ),
    VaultItemHistoryModule(
      type: VaultItemType.identity,
      normalizer: IdentityHistoryNormalizer(
        identityHistoryDao: db.identityHistoryDao,
        identityRepository: repos.identity,
      ),
      restoreHandler: IdentityHistoryRestoreHandler(
        identityItemsDao: db.identityItemsDao,
      ),
      snapshotHandler: IdentitySnapshotHandler(
        identityHistoryDao: db.identityHistoryDao,
      ),
      cardReader: IdentityHistoryCardReader(
        identityHistoryDao: db.identityHistoryDao,
      ),
    ),
    VaultItemHistoryModule(
      type: VaultItemType.licenseKey,
      normalizer: LicenseKeyHistoryNormalizer(
        licenseKeyHistoryDao: db.licenseKeyHistoryDao,
        licenseKeyRepository: repos.licenseKey,
      ),
      restoreHandler: LicenseKeyHistoryRestoreHandler(
        licenseKeyItemsDao: db.licenseKeyItemsDao,
      ),
      snapshotHandler: LicenseKeySnapshotHandler(
        licenseKeyHistoryDao: db.licenseKeyHistoryDao,
      ),
      cardReader: LicenseKeyHistoryCardReader(
        licenseKeyHistoryDao: db.licenseKeyHistoryDao,
      ),
    ),
    VaultItemHistoryModule(
      type: VaultItemType.loyaltyCard,
      normalizer: LoyaltyCardHistoryNormalizer(
        loyaltyCardHistoryDao: db.loyaltyCardHistoryDao,
        loyaltyCardRepository: repos.loyaltyCard,
      ),
      restoreHandler: LoyaltyCardHistoryRestoreHandler(
        loyaltyCardItemsDao: db.loyaltyCardItemsDao,
      ),
      snapshotHandler: LoyaltyCardSnapshotHandler(
        loyaltyCardHistoryDao: db.loyaltyCardHistoryDao,
      ),
      cardReader: LoyaltyCardHistoryCardReader(
        loyaltyCardHistoryDao: db.loyaltyCardHistoryDao,
      ),
    ),
    VaultItemHistoryModule(
      type: VaultItemType.note,
      normalizer: NoteHistoryNormalizer(
        noteHistoryDao: db.noteHistoryDao,
        noteRepository: repos.note,
      ),
      restoreHandler: NoteHistoryRestoreHandler(noteItemsDao: db.noteItemsDao),
      snapshotHandler: NoteSnapshotHandler(noteHistoryDao: db.noteHistoryDao),
      cardReader: NoteHistoryCardReader(noteHistoryDao: db.noteHistoryDao),
    ),
    VaultItemHistoryModule(
      type: VaultItemType.otp,
      normalizer: OtpHistoryNormalizer(
        otpHistoryDao: db.otpHistoryDao,
        otpRepository: repos.otp,
      ),
      restoreHandler: OtpHistoryRestoreHandler(otpItemsDao: db.otpItemsDao),
      snapshotHandler: OtpSnapshotHandler(otpHistoryDao: db.otpHistoryDao),
      cardReader: OtpHistoryCardReader(otpHistoryDao: db.otpHistoryDao),
    ),
    VaultItemHistoryModule(
      type: VaultItemType.recoveryCodes,
      normalizer: RecoveryCodesHistoryNormalizer(
        recoveryCodesHistoryDao: db.recoveryCodesHistoryDao,
        recoveryCodesRepository: repos.recoveryCodes,
      ),
      restoreHandler: RecoveryCodesHistoryRestoreHandler(
        recoveryCodesItemsDao: db.recoveryCodesItemsDao,
        recoveryCodesDao: db.recoveryCodesDao,
      ),
      snapshotHandler: RecoveryCodesSnapshotHandler(
        recoveryCodesHistoryDao: db.recoveryCodesHistoryDao,
      ),
      cardReader: RecoveryCodesHistoryCardReader(
        recoveryCodesHistoryDao: db.recoveryCodesHistoryDao,
      ),
    ),
    VaultItemHistoryModule(
      type: VaultItemType.sshKey,
      normalizer: SshKeyHistoryNormalizer(
        sshKeyHistoryDao: db.sshKeyHistoryDao,
        sshKeyRepository: repos.sshKey,
      ),
      restoreHandler: SshKeyHistoryRestoreHandler(
        sshKeyItemsDao: db.sshKeyItemsDao,
      ),
      snapshotHandler: SshKeySnapshotHandler(
        sshKeyHistoryDao: db.sshKeyHistoryDao,
      ),
      cardReader: SshKeyHistoryCardReader(
        sshKeyHistoryDao: db.sshKeyHistoryDao,
      ),
    ),
    VaultItemHistoryModule(
      type: VaultItemType.wifi,
      normalizer: WifiHistoryNormalizer(
        wifiHistoryDao: db.wifiHistoryDao,
        wifiRepository: repos.wifi,
      ),
      restoreHandler: WifiHistoryRestoreHandler(wifiItemsDao: db.wifiItemsDao),
      snapshotHandler: WifiSnapshotHandler(wifiHistoryDao: db.wifiHistoryDao),
      cardReader: WifiHistoryCardReader(wifiHistoryDao: db.wifiHistoryDao),
    ),
    VaultItemHistoryModule(
      type: VaultItemType.document,
      normalizer: DocumentHistoryNormalizer(),
      restoreHandler: DocumentHistoryRestoreHandler(),
      snapshotHandler: DocumentSnapshotHandler(),
      cardReader: DocumentHistoryCardReader(),
    ),
  ]);

  late final VaultHistoryRestorePolicyService restorePolicy =
      VaultHistoryRestorePolicyService();

  late final VaultHistoryNormalizedLoader loader = VaultHistoryNormalizedLoader(
    db: db,
    restorePolicyService: restorePolicy,
    historyModules: historyModules,
  );

  late final VaultHistoryReadService readService = VaultHistoryReadService(
    db: db,
    historyModules: historyModules,
    genericReader: GenericHistoryCardReader(),
  );

  late final VaultHistoryDiffService diffService = VaultHistoryDiffService();

  late final VaultHistoryDetailService detailService =
      VaultHistoryDetailService(
        loader: loader,
        diffService: diffService,
        restorePolicy: restorePolicy,
      );

  late final VaultSnapshotWriter snapshotWriter = VaultSnapshotWriter(
    vaultSnapshotsHistoryDao: db.vaultSnapshotsHistoryDao,
    snapshotRelationsService: SnapshotRelationsService(db: db),
    customFieldsSnapshotService: CustomFieldsSnapshotService(
      customFieldsDao: db.vaultItemCustomFieldsDao,
      customFieldsHistoryDao: db.vaultItemCustomFieldsHistoryDao,
    ),
    historyModules: historyModules,
  );

  late final StoreHistoryPolicyService policyService =
      StoreHistoryPolicyService(db.storeSettingsDao);

  late final VaultEventHistoryRepository eventHistoryRepository =
      repos.vaultEventHistory;

  late final VaultHistoryService historyService = VaultHistoryService(
    db: db,
    snapshotWriter: snapshotWriter,
    eventHistoryRepository: eventHistoryRepository,
  );

  late final VaultHistoryRestoreService restoreService =
      VaultHistoryRestoreService(
        loader: loader,
        policy: restorePolicy,
        db: db,
        vaultItemsDao: db.vaultItemsDao,
        historyModules: historyModules,
        customFieldsRestoreService: CustomFieldsRestoreService(
          customFieldsHistoryDao: db.vaultItemCustomFieldsHistoryDao,
          customFieldsDao: db.vaultItemCustomFieldsDao,
        ),
        tagsRestoreService: TagsRestoreService(
          itemTagsDao: db.itemTagsDao,
          tagsDao: db.tagsDao,
          vaultItemTagHistoryDao: db.vaultItemTagHistoryDao,
        ),
        itemLinksRestoreService: ItemLinksRestoreService(
          itemLinkHistoryDao: db.itemLinkHistoryDao,
          itemLinksDao: db.itemLinksDao,
          vaultItemsDao: db.vaultItemsDao,
        ),
        viewResolver: viewResolver,
        snapshotWriter: snapshotWriter,
        eventHistoryRepository: eventHistoryRepository,
      );

  late final VaultHistoryDeleteService deleteService =
      VaultHistoryDeleteService(db: db);

  late final VaultHistoryRetentionService retentionService =
      VaultHistoryRetentionService(
        snapshotsHistoryDao: db.vaultSnapshotsHistoryDao,
        deleteService: deleteService,
        settingsDao: db.storeSettingsDao,
      );
}
