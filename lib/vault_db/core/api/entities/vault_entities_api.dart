import 'package:hoplixi/vault_db/core/api/entities/vault_entity_type_api.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';
import 'package:hoplixi/vault_db/core/services/vault_entity_services.dart';

/// Public command API boundary for typed vault entities.
class VaultEntitiesApi {
  VaultEntitiesApi({
    required VaultEntityServices services,
    required VaultRepositories repositories,
  }) : apiKeys =
           VaultEntityTypeApi<
             CreateApiKeyDto,
             PatchApiKeyDto,
             ApiKeyViewDto,
             ApiKeyCardDto
           >(
             create: services.apiKey.create,
             update: services.apiKey.update,
             getView: repositories.apiKey.getViewById,
             getCard: repositories.apiKey.getCardById,
             listCards: repositories.apiKey.getCards,
             softDelete: services.apiKey.softDelete,
             recover: services.apiKey.recover,
             archive: services.apiKey.archive,
             restoreArchived: services.apiKey.restoreArchived,
             setFavorite: services.apiKey.setFavorite,
             setPinned: services.apiKey.setPinned,
             deletePermanently: repositories.apiKey.deletePermanently,
           ),
       bankCards =
           VaultEntityTypeApi<
             CreateBankCardDto,
             PatchBankCardDto,
             BankCardViewDto,
             BankCardCardDto
           >(
             create: services.bankCard.create,
             update: services.bankCard.update,
             getView: repositories.bankCard.getViewById,
             getCard: repositories.bankCard.getCardById,
             listCards: repositories.bankCard.getCards,
             softDelete: services.bankCard.softDelete,
             recover: services.bankCard.recover,
             archive: services.bankCard.archive,
             restoreArchived: services.bankCard.restoreArchived,
             setFavorite: services.bankCard.setFavorite,
             setPinned: services.bankCard.setPinned,
             deletePermanently: repositories.bankCard.deletePermanently,
           ),
       certificates =
           VaultEntityTypeApi<
             CreateCertificateDto,
             PatchCertificateDto,
             CertificateViewDto,
             CertificateCardDto
           >(
             create: services.certificate.create,
             update: services.certificate.update,
             getView: repositories.certificate.getViewById,
             getCard: repositories.certificate.getCardById,
             listCards: repositories.certificate.getCards,
             softDelete: services.certificate.softDelete,
             recover: services.certificate.recover,
             archive: services.certificate.archive,
             restoreArchived: services.certificate.restoreArchived,
             setFavorite: services.certificate.setFavorite,
             setPinned: services.certificate.setPinned,
             deletePermanently: repositories.certificate.deletePermanently,
           ),
       contacts =
           VaultEntityTypeApi<
             CreateContactDto,
             PatchContactDto,
             ContactViewDto,
             ContactCardDto
           >(
             create: services.contact.create,
             update: services.contact.update,
             getView: repositories.contact.getViewById,
             getCard: repositories.contact.getCardById,
             listCards: repositories.contact.getCards,
             softDelete: services.contact.softDelete,
             recover: services.contact.recover,
             archive: services.contact.archive,
             restoreArchived: services.contact.restoreArchived,
             setFavorite: services.contact.setFavorite,
             setPinned: services.contact.setPinned,
             deletePermanently: repositories.contact.deletePermanently,
           ),
       cryptoWallets =
           VaultEntityTypeApi<
             CreateCryptoWalletDto,
             PatchCryptoWalletDto,
             CryptoWalletViewDto,
             CryptoWalletCardDto
           >(
             create: services.cryptoWallet.create,
             update: services.cryptoWallet.update,
             getView: repositories.cryptoWallet.getViewById,
             getCard: repositories.cryptoWallet.getCardById,
             listCards: repositories.cryptoWallet.getCards,
             softDelete: services.cryptoWallet.softDelete,
             recover: services.cryptoWallet.recover,
             archive: services.cryptoWallet.archive,
             restoreArchived: services.cryptoWallet.restoreArchived,
             setFavorite: services.cryptoWallet.setFavorite,
             setPinned: services.cryptoWallet.setPinned,
             deletePermanently: repositories.cryptoWallet.deletePermanently,
           ),
       documents =
           VaultEntityTypeApi<
             CreateDocumentDto,
             PatchDocumentDto,
             DocumentViewDto,
             DocumentCardDto
           >(
             create: services.document.create,
             update: services.document.update,
             getView: repositories.document.getViewById,
             getCard: repositories.document.getCardById,
             listCards: repositories.document.getCards,
             softDelete: services.document.softDelete,
             recover: services.document.recover,
             archive: services.document.archive,
             restoreArchived: services.document.restoreArchived,
             setFavorite: services.document.setFavorite,
             setPinned: services.document.setPinned,
             deletePermanently: repositories.document.deletePermanently,
           ),
       files =
           VaultEntityTypeApi<
             CreateFileDto,
             PatchFileDto,
             FileViewDto,
             FileCardDto
           >(
             create: services.file.create,
             update: services.file.update,
             getView: repositories.file.getViewById,
             getCard: repositories.file.getCardById,
             listCards: repositories.file.getCards,
             softDelete: services.file.softDelete,
             recover: services.file.recover,
             archive: services.file.archive,
             restoreArchived: services.file.restoreArchived,
             setFavorite: services.file.setFavorite,
             setPinned: services.file.setPinned,
             deletePermanently: repositories.file.deletePermanently,
           ),
       identities =
           VaultEntityTypeApi<
             CreateIdentityDto,
             PatchIdentityDto,
             IdentityViewDto,
             IdentityCardDto
           >(
             create: services.identity.create,
             update: services.identity.update,
             getView: repositories.identity.getViewById,
             getCard: repositories.identity.getCardById,
             listCards: repositories.identity.getCards,
             softDelete: services.identity.softDelete,
             recover: services.identity.recover,
             archive: services.identity.archive,
             restoreArchived: services.identity.restoreArchived,
             setFavorite: services.identity.setFavorite,
             setPinned: services.identity.setPinned,
             deletePermanently: repositories.identity.deletePermanently,
           ),
       licenseKeys =
           VaultEntityTypeApi<
             CreateLicenseKeyDto,
             PatchLicenseKeyDto,
             LicenseKeyViewDto,
             LicenseKeyCardDto
           >(
             create: services.licenseKey.create,
             update: services.licenseKey.update,
             getView: repositories.licenseKey.getViewById,
             getCard: repositories.licenseKey.getCardById,
             listCards: repositories.licenseKey.getCards,
             softDelete: services.licenseKey.softDelete,
             recover: services.licenseKey.recover,
             archive: services.licenseKey.archive,
             restoreArchived: services.licenseKey.restoreArchived,
             setFavorite: services.licenseKey.setFavorite,
             setPinned: services.licenseKey.setPinned,
             deletePermanently: repositories.licenseKey.deletePermanently,
           ),
       loyaltyCards =
           VaultEntityTypeApi<
             CreateLoyaltyCardDto,
             PatchLoyaltyCardDto,
             LoyaltyCardViewDto,
             LoyaltyCardCardDto
           >(
             create: services.loyaltyCard.create,
             update: services.loyaltyCard.update,
             getView: repositories.loyaltyCard.getViewById,
             getCard: repositories.loyaltyCard.getCardById,
             listCards: repositories.loyaltyCard.getCards,
             softDelete: services.loyaltyCard.softDelete,
             recover: services.loyaltyCard.recover,
             archive: services.loyaltyCard.archive,
             restoreArchived: services.loyaltyCard.restoreArchived,
             setFavorite: services.loyaltyCard.setFavorite,
             setPinned: services.loyaltyCard.setPinned,
             deletePermanently: repositories.loyaltyCard.deletePermanently,
           ),
       notes =
           VaultEntityTypeApi<
             CreateNoteDto,
             PatchNoteDto,
             NoteViewDto,
             NoteCardDto
           >(
             create: services.note.create,
             update: services.note.update,
             getView: repositories.note.getViewById,
             getCard: repositories.note.getCardById,
             listCards: repositories.note.getCards,
             softDelete: services.note.softDelete,
             recover: services.note.recover,
             archive: services.note.archive,
             restoreArchived: services.note.restoreArchived,
             setFavorite: services.note.setFavorite,
             setPinned: services.note.setPinned,
             deletePermanently: repositories.note.deletePermanently,
           ),
       otps =
           VaultEntityTypeApi<
             CreateOtpDto,
             PatchOtpDto,
             OtpViewDto,
             OtpCardDto
           >(
             create: services.otp.create,
             update: services.otp.update,
             getView: repositories.otp.getViewById,
             getCard: repositories.otp.getCardById,
             listCards: repositories.otp.getCards,
             softDelete: services.otp.softDelete,
             recover: services.otp.recover,
             archive: services.otp.archive,
             restoreArchived: services.otp.restoreArchived,
             setFavorite: services.otp.setFavorite,
             setPinned: services.otp.setPinned,
             deletePermanently: repositories.otp.deletePermanently,
           ),
       passwords =
           VaultEntityTypeApi<
             CreatePasswordDto,
             PatchPasswordDto,
             PasswordViewDto,
             PasswordCardDto
           >(
             create: services.password.create,
             update: services.password.update,
             getView: repositories.password.getViewById,
             getCard: repositories.password.getCardById,
             listCards: repositories.password.getCards,
             softDelete: services.password.softDelete,
             recover: services.password.recover,
             archive: services.password.archive,
             restoreArchived: services.password.restoreArchived,
             setFavorite: services.password.setFavorite,
             setPinned: services.password.setPinned,
             deletePermanently: repositories.password.deletePermanently,
           ),
       recoveryCodes =
           VaultEntityTypeApi<
             CreateRecoveryCodesDto,
             PatchRecoveryCodesDto,
             RecoveryCodesViewDto,
             RecoveryCodesCardDto
           >(
             create: services.recoveryCodes.create,
             update: services.recoveryCodes.update,
             getView: repositories.recoveryCodes.getViewById,
             getCard: repositories.recoveryCodes.getCardById,
             listCards: repositories.recoveryCodes.getCards,
             softDelete: services.recoveryCodes.softDelete,
             recover: services.recoveryCodes.recover,
             archive: services.recoveryCodes.archive,
             restoreArchived: services.recoveryCodes.restoreArchived,
             setFavorite: services.recoveryCodes.setFavorite,
             setPinned: services.recoveryCodes.setPinned,
             deletePermanently: repositories.recoveryCodes.deletePermanently,
           ),
       sshKeys =
           VaultEntityTypeApi<
             CreateSshKeyDto,
             PatchSshKeyDto,
             SshKeyViewDto,
             SshKeyCardDto
           >(
             create: services.sshKey.create,
             update: services.sshKey.update,
             getView: repositories.sshKey.getViewById,
             getCard: repositories.sshKey.getCardById,
             listCards: repositories.sshKey.getCards,
             softDelete: services.sshKey.softDelete,
             recover: services.sshKey.recover,
             archive: services.sshKey.archive,
             restoreArchived: services.sshKey.restoreArchived,
             setFavorite: services.sshKey.setFavorite,
             setPinned: services.sshKey.setPinned,
             deletePermanently: repositories.sshKey.deletePermanently,
           ),
       wifis =
           VaultEntityTypeApi<
             CreateWifiDto,
             PatchWifiDto,
             WifiViewDto,
             WifiCardDto
           >(
             create: services.wifi.create,
             update: services.wifi.update,
             getView: repositories.wifi.getViewById,
             getCard: repositories.wifi.getCardById,
             listCards: repositories.wifi.getCards,
             softDelete: services.wifi.softDelete,
             recover: services.wifi.recover,
             archive: services.wifi.archive,
             restoreArchived: services.wifi.restoreArchived,
             setFavorite: services.wifi.setFavorite,
             setPinned: services.wifi.setPinned,
             deletePermanently: repositories.wifi.deletePermanently,
           );

  final VaultEntityTypeApi<
    CreateApiKeyDto,
    PatchApiKeyDto,
    ApiKeyViewDto,
    ApiKeyCardDto
  >
  apiKeys;
  final VaultEntityTypeApi<
    CreateBankCardDto,
    PatchBankCardDto,
    BankCardViewDto,
    BankCardCardDto
  >
  bankCards;
  final VaultEntityTypeApi<
    CreateCertificateDto,
    PatchCertificateDto,
    CertificateViewDto,
    CertificateCardDto
  >
  certificates;
  final VaultEntityTypeApi<
    CreateContactDto,
    PatchContactDto,
    ContactViewDto,
    ContactCardDto
  >
  contacts;
  final VaultEntityTypeApi<
    CreateCryptoWalletDto,
    PatchCryptoWalletDto,
    CryptoWalletViewDto,
    CryptoWalletCardDto
  >
  cryptoWallets;
  final VaultEntityTypeApi<
    CreateDocumentDto,
    PatchDocumentDto,
    DocumentViewDto,
    DocumentCardDto
  >
  documents;
  final VaultEntityTypeApi<
    CreateFileDto,
    PatchFileDto,
    FileViewDto,
    FileCardDto
  >
  files;
  final VaultEntityTypeApi<
    CreateIdentityDto,
    PatchIdentityDto,
    IdentityViewDto,
    IdentityCardDto
  >
  identities;
  final VaultEntityTypeApi<
    CreateLicenseKeyDto,
    PatchLicenseKeyDto,
    LicenseKeyViewDto,
    LicenseKeyCardDto
  >
  licenseKeys;
  final VaultEntityTypeApi<
    CreateLoyaltyCardDto,
    PatchLoyaltyCardDto,
    LoyaltyCardViewDto,
    LoyaltyCardCardDto
  >
  loyaltyCards;
  final VaultEntityTypeApi<
    CreateNoteDto,
    PatchNoteDto,
    NoteViewDto,
    NoteCardDto
  >
  notes;
  final VaultEntityTypeApi<CreateOtpDto, PatchOtpDto, OtpViewDto, OtpCardDto>
  otps;
  final VaultEntityTypeApi<
    CreatePasswordDto,
    PatchPasswordDto,
    PasswordViewDto,
    PasswordCardDto
  >
  passwords;
  final VaultEntityTypeApi<
    CreateRecoveryCodesDto,
    PatchRecoveryCodesDto,
    RecoveryCodesViewDto,
    RecoveryCodesCardDto
  >
  recoveryCodes;
  final VaultEntityTypeApi<
    CreateSshKeyDto,
    PatchSshKeyDto,
    SshKeyViewDto,
    SshKeyCardDto
  >
  sshKeys;
  final VaultEntityTypeApi<
    CreateWifiDto,
    PatchWifiDto,
    WifiViewDto,
    WifiCardDto
  >
  wifis;
}
