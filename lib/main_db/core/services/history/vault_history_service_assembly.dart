import 'package:hoplixi/main_db/core/repositories/base/api_key_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/bank_card_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/certificate_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/contact_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/crypto_wallet_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/file_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/identity_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/license_key_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/loyalty_card_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/note_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/otp_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/password_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/recovery_codes_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/ssh_key_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/wifi_repository.dart';
import 'package:hoplixi/main_db/core/services/history/custom_fields/custom_fields_restore_service.dart';
import 'package:hoplixi/main_db/core/services/history/item_links_restore_service.dart';
import 'package:hoplixi/main_db/core/services/history/tags_restore_service.dart';

import '../../main_store.dart';
import 'normalizers/normalizers.dart';
import 'readers/readers.dart';
import 'restore_handlers/restore_handlers.dart';
import 'vault_history_detail_service.dart';
import 'utils/vault_history_diff_service.dart';
import 'vault_history_normalized_loader.dart';
import 'vault_history_read_service.dart';
import 'policy/vault_history_restore_policy_service.dart';
import 'vault_history_restore_service.dart';

class VaultHistoryServiceAssembly {
  VaultHistoryServiceAssembly(this.db);

  final MainStore db;

  late final VaultHistoryNormalizerRegistry normalizerRegistry =
      VaultHistoryNormalizerRegistry([
        ApiKeyHistoryNormalizer(
          apiKeyHistoryDao: db.apiKeyHistoryDao,
          apiKeyRepository: ApiKeyRepository(db),
        ),
        PasswordHistoryNormalizer(
          passwordHistoryDao: db.passwordHistoryDao,
          passwordRepository: PasswordRepository(db),
        ),
        BankCardHistoryNormalizer(
          bankCardHistoryDao: db.bankCardHistoryDao,
          bankCardRepository: BankCardRepository(db),
        ),
        CertificateHistoryNormalizer(
          certificateHistoryDao: db.certificateHistoryDao,
          certificateRepository: CertificateRepository(db),
        ),
        ContactHistoryNormalizer(
          contactHistoryDao: db.contactHistoryDao,
          contactRepository: ContactRepository(db),
        ),
        CryptoWalletHistoryNormalizer(
          cryptoWalletHistoryDao: db.cryptoWalletHistoryDao,
          cryptoWalletRepository: CryptoWalletRepository(db),
        ),
        FileHistoryNormalizer(
          fileHistoryDao: db.fileHistoryDao,
          fileMetadataHistoryDao: db.fileMetadataHistoryDao,
          fileRepository: FileRepository(db),
        ),
        IdentityHistoryNormalizer(
          identityHistoryDao: db.identityHistoryDao,
          identityRepository: IdentityRepository(db),
        ),
        LicenseKeyHistoryNormalizer(
          licenseKeyHistoryDao: db.licenseKeyHistoryDao,
          licenseKeyRepository: LicenseKeyRepository(db),
        ),
        LoyaltyCardHistoryNormalizer(
          loyaltyCardHistoryDao: db.loyaltyCardHistoryDao,
          loyaltyCardRepository: LoyaltyCardRepository(db),
        ),
        NoteHistoryNormalizer(
          noteHistoryDao: db.noteHistoryDao,
          noteRepository: NoteRepository(db),
        ),
        OtpHistoryNormalizer(
          otpHistoryDao: db.otpHistoryDao,
          otpRepository: OtpRepository(db),
        ),
        RecoveryCodesHistoryNormalizer(
          recoveryCodesHistoryDao: db.recoveryCodesHistoryDao,
          recoveryCodeValuesHistoryDao: db.recoveryCodeValuesHistoryDao,
          recoveryCodesRepository: RecoveryCodesRepository(db),
        ),
        SshKeyHistoryNormalizer(
          sshKeyHistoryDao: db.sshKeyHistoryDao,
          sshKeyRepository: SshKeyRepository(db),
        ),
        WifiHistoryNormalizer(
          wifiHistoryDao: db.wifiHistoryDao,
          wifiRepository: WifiRepository(db),
        ),
        DocumentHistoryNormalizer(),
      ]);

  late final VaultHistoryRestoreHandlerRegistry restoreHandlerRegistry =
      VaultHistoryRestoreHandlerRegistry([
        ApiKeyHistoryRestoreHandler(apiKeyItemsDao: db.apiKeyItemsDao),
        PasswordHistoryRestoreHandler(passwordItemsDao: db.passwordItemsDao),
        BankCardHistoryRestoreHandler(bankCardItemsDao: db.bankCardItemsDao),
        CertificateHistoryRestoreHandler(
          certificateItemsDao: db.certificateItemsDao,
        ),
        ContactHistoryRestoreHandler(contactItemsDao: db.contactItemsDao),
        CryptoWalletHistoryRestoreHandler(
          cryptoWalletItemsDao: db.cryptoWalletItemsDao,
        ),
        FileHistoryRestoreHandler(
          fileItemsDao: db.fileItemsDao,
          fileMetadataDao: db.fileMetadataDao,
        ),
        IdentityHistoryRestoreHandler(identityItemsDao: db.identityItemsDao),
        LicenseKeyHistoryRestoreHandler(
          licenseKeyItemsDao: db.licenseKeyItemsDao,
        ),
        LoyaltyCardHistoryRestoreHandler(
          loyaltyCardItemsDao: db.loyaltyCardItemsDao,
        ),
        NoteHistoryRestoreHandler(noteItemsDao: db.noteItemsDao),
        OtpHistoryRestoreHandler(otpItemsDao: db.otpItemsDao),
        RecoveryCodesHistoryRestoreHandler(
          recoveryCodesItemsDao: db.recoveryCodesItemsDao,
          recoveryCodesDao: db.recoveryCodesDao,
          recoveryCodeValuesHistoryDao: db.recoveryCodeValuesHistoryDao,
        ),
        SshKeyHistoryRestoreHandler(sshKeyItemsDao: db.sshKeyItemsDao),
        WifiHistoryRestoreHandler(wifiItemsDao: db.wifiItemsDao),
        DocumentHistoryRestoreHandler(),
      ]);

  late final VaultHistoryCardReaderRegistry readerRegistry =
      VaultHistoryCardReaderRegistry([
        ApiKeyHistoryCardReader(apiKeyHistoryDao: db.apiKeyHistoryDao),
        PasswordHistoryCardReader(passwordHistoryDao: db.passwordHistoryDao),
        BankCardHistoryCardReader(bankCardHistoryDao: db.bankCardHistoryDao),
        CertificateHistoryCardReader(
          certificateHistoryDao: db.certificateHistoryDao,
        ),
        ContactHistoryCardReader(contactHistoryDao: db.contactHistoryDao),
        CryptoWalletHistoryCardReader(
          cryptoWalletHistoryDao: db.cryptoWalletHistoryDao,
        ),
        FileHistoryCardReader(
          fileHistoryDao: db.fileHistoryDao,
          fileMetadataHistoryDao: db.fileMetadataHistoryDao,
        ),
        IdentityHistoryCardReader(identityHistoryDao: db.identityHistoryDao),
        LicenseKeyHistoryCardReader(
          licenseKeyHistoryDao: db.licenseKeyHistoryDao,
        ),
        LoyaltyCardHistoryCardReader(
          loyaltyCardHistoryDao: db.loyaltyCardHistoryDao,
        ),
        NoteHistoryCardReader(noteHistoryDao: db.noteHistoryDao),
        OtpHistoryCardReader(otpHistoryDao: db.otpHistoryDao),
        RecoveryCodesHistoryCardReader(
          recoveryCodesHistoryDao: db.recoveryCodesHistoryDao,
        ),
        SshKeyHistoryCardReader(sshKeyHistoryDao: db.sshKeyHistoryDao),
        WifiHistoryCardReader(wifiHistoryDao: db.wifiHistoryDao),
        DocumentHistoryCardReader(),
      ]);

  late final VaultHistoryRestorePolicyService restorePolicy =
      VaultHistoryRestorePolicyService();

  late final VaultHistoryNormalizedLoader loader = VaultHistoryNormalizedLoader(
    snapshotsHistoryDao: db.vaultSnapshotsHistoryDao,
    vaultItemsDao: db.vaultItemsDao,
    restorePolicyService: restorePolicy,
    normalizerRegistry: normalizerRegistry,
    customFieldsHistoryDao: db.vaultItemCustomFieldsHistoryDao,
    customFieldsDao: db.vaultItemCustomFieldsDao,
  );

  late final VaultHistoryReadService readService = VaultHistoryReadService(
    snapshotFilterDao: db.vaultSnapshotHistoryFilterDao,
    snapshotsHistoryDao: db.vaultSnapshotsHistoryDao,
    readerRegistry: readerRegistry,
    genericReader: GenericHistoryCardReader(),
  );

  late final VaultHistoryDiffService diffService = VaultHistoryDiffService();

  late final VaultHistoryDetailService detailService =
      VaultHistoryDetailService(
        loader: loader,
        diffService: diffService,
        restorePolicy: restorePolicy,
      );

  late final VaultHistoryRestoreService restoreService =
      VaultHistoryRestoreService(
        loader: loader,
        policy: restorePolicy,
        db: db,
        vaultItemsDao: db.vaultItemsDao,
        restoreHandlerRegistry: restoreHandlerRegistry,
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
          itemLinksDao: db.itemLinksDao,
          itemLinkHistoryDao: db.itemLinkHistoryDao,
          vaultItemsDao: db.vaultItemsDao,
        ),
      );
}
