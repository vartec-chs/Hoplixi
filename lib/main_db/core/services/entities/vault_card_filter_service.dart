import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/models/filters/base/base.dart';

class VaultCardFilterService {
  VaultCardFilterService(this.db);

  final MainStore db;

  Future<List<FilteredCardDto<ApiKeyCardDto>>> getApiKeys(ApiKeyFilter filter) {
    return db.apiKeyFilterDao.getFiltered(filter);
  }

  Future<int> countApiKeys(ApiKeyFilter filter) {
    return db.apiKeyFilterDao.countFiltered(filter);
  }

  Future<List<FilteredCardDto<BankCardCardDto>>> getBankCards(
    BankCardFilter filter,
  ) {
    return db.bankCardFilterDao.getFiltered(filter);
  }

  Future<int> countBankCards(BankCardFilter filter) {
    return db.bankCardFilterDao.countFiltered(filter);
  }

  Future<List<FilteredCardDto<CertificateCardDto>>> getCertificates(
    CertificateFilter filter,
  ) {
    return db.certificateFilterDao.getFiltered(filter);
  }

  Future<int> countCertificates(CertificateFilter filter) {
    return db.certificateFilterDao.countFiltered(filter);
  }

  Future<List<FilteredCardDto<ContactCardDto>>> getContacts(
    ContactFilter filter,
  ) {
    return db.contactFilterDao.getFiltered(filter);
  }

  Future<int> countContacts(ContactFilter filter) {
    return db.contactFilterDao.countFiltered(filter);
  }

  Future<List<FilteredCardDto<CryptoWalletCardDto>>> getCryptoWallets(
    CryptoWalletFilter filter,
  ) {
    return db.cryptoWalletFilterDao.getFiltered(filter);
  }

  Future<int> countCryptoWallets(CryptoWalletFilter filter) {
    return db.cryptoWalletFilterDao.countFiltered(filter);
  }

  Future<List<FilteredCardDto<DocumentCardDto>>> getDocuments(
    DocumentFilter filter,
  ) {
    return db.documentFilterDao.getFiltered(filter);
  }

  Future<int> countDocuments(DocumentFilter filter) {
    return db.documentFilterDao.countFiltered(filter);
  }

  Future<List<FilteredCardDto<FileCardDto>>> getFiles(FileFilter filter) {
    return db.fileFilterDao.getFiltered(filter);
  }

  Future<int> countFiles(FileFilter filter) {
    return db.fileFilterDao.countFiltered(filter);
  }

  Future<List<FilteredCardDto<IdentityCardDto>>> getIdentities(
    IdentityFilter filter,
  ) {
    return db.identityFilterDao.getFiltered(filter);
  }

  Future<int> countIdentities(IdentityFilter filter) {
    return db.identityFilterDao.countFiltered(filter);
  }

  Future<List<FilteredCardDto<LicenseKeyCardDto>>> getLicenseKeys(
    LicenseKeyFilter filter,
  ) {
    return db.licenseKeyFilterDao.getFiltered(filter);
  }

  Future<int> countLicenseKeys(LicenseKeyFilter filter) {
    return db.licenseKeyFilterDao.countFiltered(filter);
  }

  Future<List<FilteredCardDto<LoyaltyCardCardDto>>> getLoyaltyCards(
    LoyaltyCardFilter filter,
  ) {
    return db.loyaltyCardFilterDao.getFiltered(filter);
  }

  Future<int> countLoyaltyCards(LoyaltyCardFilter filter) {
    return db.loyaltyCardFilterDao.countFiltered(filter);
  }

  Future<List<FilteredCardDto<NoteCardDto>>> getNotes(NoteFilter filter) {
    return db.noteFilterDao.getFiltered(filter);
  }

  Future<int> countNotes(NoteFilter filter) {
    return db.noteFilterDao.countFiltered(filter);
  }

  Future<List<FilteredCardDto<OtpCardDto>>> getOtps(OtpFilter filter) {
    return db.otpFilterDao.getFiltered(filter);
  }

  Future<int> countOtps(OtpFilter filter) {
    return db.otpFilterDao.countFiltered(filter);
  }

  Future<List<FilteredCardDto<PasswordCardDto>>> getPasswords(
    PasswordFilter filter,
  ) {
    return db.passwordFilterDao.getFiltered(filter);
  }

  Future<int> countPasswords(PasswordFilter filter) {
    return db.passwordFilterDao.countFiltered(filter);
  }

  Future<List<FilteredCardDto<RecoveryCodesCardDto>>> getRecoveryCodes(
    RecoveryCodesFilter filter,
  ) {
    return db.recoveryCodesFilterDao.getFiltered(filter);
  }

  Future<int> countRecoveryCodes(RecoveryCodesFilter filter) {
    return db.recoveryCodesFilterDao.countFiltered(filter);
  }

  Future<List<FilteredCardDto<SshKeyCardDto>>> getSshKeys(SshKeyFilter filter) {
    return db.sshKeyFilterDao.getFiltered(filter);
  }

  Future<int> countSshKeys(SshKeyFilter filter) {
    return db.sshKeyFilterDao.countFiltered(filter);
  }

  Future<List<FilteredCardDto<WifiCardDto>>> getWifis(WifiFilter filter) {
    return db.wifiFilterDao.getFiltered(filter);
  }

  Future<int> countWifis(WifiFilter filter) {
    return db.wifiFilterDao.countFiltered(filter);
  }
}
