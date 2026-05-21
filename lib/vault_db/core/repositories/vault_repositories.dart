import '../vault_db.dart';
import 'repositories.dart';

/// A class that provides access to all repositories in the VaultDB.
class VaultRepositories {
  final VaultDB db;

  VaultRepositories(this.db);

  late final password = PasswordRepository(db);
  late final note = NoteRepository(db);
  late final apiKey = ApiKeyRepository(db);
  late final bankCard = BankCardRepository(db);
  late final certificate = CertificateRepository(db);
  late final contact = ContactRepository(db);
  late final cryptoWallet = CryptoWalletRepository(db);
  late final document = DocumentRepository(db);
  late final documentVersion = DocumentVersionRepository(db);
  late final documentPage = DocumentPageRepository(db);
  late final file = FileRepository(db);
  late final fileMetadata = FileMetadataRepository(db);
  late final identity = IdentityRepository(db);
  late final licenseKey = LicenseKeyRepository(db);
  late final loyaltyCard = LoyaltyCardRepository(db);
  late final otp = OtpRepository(db);
  late final recoveryCodes = RecoveryCodesRepository(db);
  late final sshKey = SshKeyRepository(db);
  late final wifi = WifiRepository(db);

  // system
  late final category = CategoryRepository(db);
  late final tag = TagRepository(db);
  late final icon = IconRepository(db);
  late final storeMeta = StoreMetaRepository(db);
  late final storeSettings = StoreSettingsRepository(db);
  late final snapshotRelations = SnapshotRelationsRepository(db);
  late final vaultItemRelations = VaultItemRelationsRepository(db);

  late final vaultItem = VaultItemRepository(db);
  late final vaultItemCustomFields = VaultItemCustomFieldsRepository(db);
  late final vaultEventHistory = VaultEventHistoryRepository(db);
}
