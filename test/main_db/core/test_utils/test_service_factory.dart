import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/repositories/base/api_key_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/bank_card_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/certificate_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/contact_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/crypto_wallet_repository.dart';
import 'package:hoplixi/main_db/core/repositories/base/document_repository.dart';
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
import 'package:hoplixi/main_db/core/services/entities/api_key_service.dart';
import 'package:hoplixi/main_db/core/services/entities/password_service.dart';
import 'package:hoplixi/main_db/core/services/history/history.dart';
import 'package:hoplixi/main_db/core/services/relations/snapshot_relations_service.dart';
import 'package:hoplixi/main_db/core/services/relations/vault_item_relations_service.dart';
import 'package:hoplixi/main_db/core/services/vault_items_state_service.dart';
import 'package:hoplixi/main_db/core/services/vault_typed_view_resolver.dart';

class TestServiceFactory {
  TestServiceFactory(this.db);

  final MainStore db;

  StoreHistoryPolicyService createStoreHistoryPolicyService() {
    return StoreHistoryPolicyService(db.storeSettingsDao);
  }

  VaultEventHistoryService createVaultEventHistoryService() {
    return VaultEventHistoryService(db.vaultEventsHistoryDao);
  }

  SnapshotRelationsService createSnapshotRelationsService() {
    return SnapshotRelationsService(
      categoriesDao: db.categoriesDao,
      tagsDao: db.tagsDao,
      itemTagsDao: db.itemTagsDao,
      itemLinksDao: db.itemLinksDao,
      itemCategoryHistoryDao: db.itemCategoryHistoryDao,
      vaultItemTagHistoryDao: db.vaultItemTagHistoryDao,
      itemLinkHistoryDao: db.itemLinkHistoryDao,
    );
  }

  VaultSnapshotWriter createVaultSnapshotWriter() {
    return VaultSnapshotWriter(
      vaultSnapshotsHistoryDao: db.vaultSnapshotsHistoryDao,
      snapshotRelationsService: createSnapshotRelationsService(),
      customFieldsSnapshotService: CustomFieldsSnapshotService(
        customFieldsDao: db.vaultItemCustomFieldsDao,
        customFieldsHistoryDao: db.vaultItemCustomFieldsHistoryDao,
      ),
      handlerRegistry: VaultHistoryServiceAssembly(db).snapshotHandlerRegistry,
    );
  }

  VaultHistoryService createVaultHistoryService() {
    return VaultHistoryService(
      policyService: createStoreHistoryPolicyService(),
      snapshotWriter: createVaultSnapshotWriter(),
      eventHistoryService: createVaultEventHistoryService(),
    );
  }

  VaultItemRelationsService createVaultItemRelationsService() {
    return VaultItemRelationsService(
      db: db,
      vaultItemsDao: db.vaultItemsDao,
      categoriesDao: db.categoriesDao,
      tagsDao: db.tagsDao,
      itemTagsDao: db.itemTagsDao,
      itemLinksDao: db.itemLinksDao,
    );
  }

  VaultItemsStateService createVaultItemsStateService() {
    return VaultItemsStateService(
      db: db,
      viewResolver: createVaultTypedViewResolver(),
      historyService: createVaultHistoryService(),
    );
  }

  VaultTypedViewResolver createVaultTypedViewResolver() {
    return VaultTypedViewResolver(
      apiKeyRepository: createApiKeyRepository(),
      passwordRepository: createPasswordRepository(),
      bankCardRepository: createBankCardRepository(),
      noteRepository: createNoteRepository(),
      otpRepository: createOtpRepository(),
      documentRepository: createDocumentRepository(),
      fileRepository: createFileRepository(),
      contactRepository: createContactRepository(),
      sshKeyRepository: createSshKeyRepository(),
      certificateRepository: createCertificateRepository(),
      cryptoWalletRepository: createCryptoWalletRepository(),
      wifiRepository: createWifiRepository(),
      identityRepository: createIdentityRepository(),
      licenseKeyRepository: createLicenseKeyRepository(),
      recoveryCodesRepository: createRecoveryCodesRepository(),
      loyaltyCardRepository: createLoyaltyCardRepository(),
    );
  }

  ApiKeyRepository createApiKeyRepository() => ApiKeyRepository(db);
  PasswordRepository createPasswordRepository() => PasswordRepository(db);
  BankCardRepository createBankCardRepository() => BankCardRepository(db);
  CertificateRepository createCertificateRepository() =>
      CertificateRepository(db);
  ContactRepository createContactRepository() => ContactRepository(db);
  CryptoWalletRepository createCryptoWalletRepository() =>
      CryptoWalletRepository(db);
  IdentityRepository createIdentityRepository() => IdentityRepository(db);
  LicenseKeyRepository createLicenseKeyRepository() => LicenseKeyRepository(db);
  LoyaltyCardRepository createLoyaltyCardRepository() =>
      LoyaltyCardRepository(db);
  NoteRepository createNoteRepository() => NoteRepository(db);
  OtpRepository createOtpRepository() => OtpRepository(db);
  RecoveryCodesRepository createRecoveryCodesRepository() =>
      RecoveryCodesRepository(db);
  SshKeyRepository createSshKeyRepository() => SshKeyRepository(db);
  WifiRepository createWifiRepository() => WifiRepository(db);
  FileRepository createFileRepository() => FileRepository(db);
  DocumentRepository createDocumentRepository() => DocumentRepository(db);

  ApiKeyService createApiKeyService() {
    return ApiKeyService(
      db: db,
      repository: createApiKeyRepository(),
      relationsService: createVaultItemRelationsService(),
      historyService: createVaultHistoryService(),
      vaultItemsStateService: createVaultItemsStateService(),
    );
  }

  PasswordService createPasswordService() {
    return PasswordService(
      db: db,
      repository: createPasswordRepository(),
      relationsService: createVaultItemRelationsService(),
      historyService: createVaultHistoryService(),
      vaultItemsStateService: createVaultItemsStateService(),
    );
  }
}
