import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/models/filters/base/base.dart';
import 'package:hoplixi/vault_db/core/services/entities/vault_card_filter_service.dart';

/// Public read-only API boundary for vault item cards and counters.
class VaultItemsApi {
  const VaultItemsApi({required VaultCardFilterService cardFilters})
    : _cardFilters = cardFilters;

  final VaultCardFilterService _cardFilters;

  AsyncDBResult<List<FilteredCardDto<ApiKeyCardDto>>> getApiKeys(
    ApiKeyFilter filter,
  ) {
    return _cardFilters.getApiKeys(filter);
  }

  AsyncDBResult<int> countApiKeys(ApiKeyFilter filter) {
    return _cardFilters.countApiKeys(filter);
  }

  AsyncDBResult<List<FilteredCardDto<BankCardCardDto>>> getBankCards(
    BankCardFilter filter,
  ) {
    return _cardFilters.getBankCards(filter);
  }

  AsyncDBResult<int> countBankCards(BankCardFilter filter) {
    return _cardFilters.countBankCards(filter);
  }

  AsyncDBResult<List<FilteredCardDto<CertificateCardDto>>> getCertificates(
    CertificateFilter filter,
  ) {
    return _cardFilters.getCertificates(filter);
  }

  AsyncDBResult<int> countCertificates(CertificateFilter filter) {
    return _cardFilters.countCertificates(filter);
  }

  AsyncDBResult<List<FilteredCardDto<ContactCardDto>>> getContacts(
    ContactFilter filter,
  ) {
    return _cardFilters.getContacts(filter);
  }

  AsyncDBResult<int> countContacts(ContactFilter filter) {
    return _cardFilters.countContacts(filter);
  }

  AsyncDBResult<List<FilteredCardDto<CryptoWalletCardDto>>> getCryptoWallets(
    CryptoWalletFilter filter,
  ) {
    return _cardFilters.getCryptoWallets(filter);
  }

  AsyncDBResult<int> countCryptoWallets(CryptoWalletFilter filter) {
    return _cardFilters.countCryptoWallets(filter);
  }

  AsyncDBResult<List<FilteredCardDto<DocumentCardDto>>> getDocuments(
    DocumentFilter filter,
  ) {
    return _cardFilters.getDocuments(filter);
  }

  AsyncDBResult<int> countDocuments(DocumentFilter filter) {
    return _cardFilters.countDocuments(filter);
  }

  AsyncDBResult<List<FilteredCardDto<FileCardDto>>> getFiles(
    FileFilter filter,
  ) {
    return _cardFilters.getFiles(filter);
  }

  AsyncDBResult<int> countFiles(FileFilter filter) {
    return _cardFilters.countFiles(filter);
  }

  AsyncDBResult<List<FilteredCardDto<IdentityCardDto>>> getIdentities(
    IdentityFilter filter,
  ) {
    return _cardFilters.getIdentities(filter);
  }

  AsyncDBResult<int> countIdentities(IdentityFilter filter) {
    return _cardFilters.countIdentities(filter);
  }

  AsyncDBResult<List<FilteredCardDto<LicenseKeyCardDto>>> getLicenseKeys(
    LicenseKeyFilter filter,
  ) {
    return _cardFilters.getLicenseKeys(filter);
  }

  AsyncDBResult<int> countLicenseKeys(LicenseKeyFilter filter) {
    return _cardFilters.countLicenseKeys(filter);
  }

  AsyncDBResult<List<FilteredCardDto<LoyaltyCardCardDto>>> getLoyaltyCards(
    LoyaltyCardFilter filter,
  ) {
    return _cardFilters.getLoyaltyCards(filter);
  }

  AsyncDBResult<int> countLoyaltyCards(LoyaltyCardFilter filter) {
    return _cardFilters.countLoyaltyCards(filter);
  }

  AsyncDBResult<List<FilteredCardDto<NoteCardDto>>> getNotes(
    NoteFilter filter,
  ) {
    return _cardFilters.getNotes(filter);
  }

  AsyncDBResult<int> countNotes(NoteFilter filter) {
    return _cardFilters.countNotes(filter);
  }

  AsyncDBResult<List<FilteredCardDto<OtpCardDto>>> getOtps(OtpFilter filter) {
    return _cardFilters.getOtps(filter);
  }

  AsyncDBResult<int> countOtps(OtpFilter filter) {
    return _cardFilters.countOtps(filter);
  }

  AsyncDBResult<List<FilteredCardDto<PasswordCardDto>>> getPasswords(
    PasswordFilter filter,
  ) {
    return _cardFilters.getPasswords(filter);
  }

  AsyncDBResult<int> countPasswords(PasswordFilter filter) {
    return _cardFilters.countPasswords(filter);
  }

  AsyncDBResult<List<FilteredCardDto<RecoveryCodesCardDto>>> getRecoveryCodes(
    RecoveryCodesFilter filter,
  ) {
    return _cardFilters.getRecoveryCodes(filter);
  }

  AsyncDBResult<int> countRecoveryCodes(RecoveryCodesFilter filter) {
    return _cardFilters.countRecoveryCodes(filter);
  }

  AsyncDBResult<List<FilteredCardDto<SshKeyCardDto>>> getSshKeys(
    SshKeyFilter filter,
  ) {
    return _cardFilters.getSshKeys(filter);
  }

  AsyncDBResult<int> countSshKeys(SshKeyFilter filter) {
    return _cardFilters.countSshKeys(filter);
  }

  AsyncDBResult<List<FilteredCardDto<WifiCardDto>>> getWifis(
    WifiFilter filter,
  ) {
    return _cardFilters.getWifis(filter);
  }

  AsyncDBResult<int> countWifis(WifiFilter filter) {
    return _cardFilters.countWifis(filter);
  }
}
