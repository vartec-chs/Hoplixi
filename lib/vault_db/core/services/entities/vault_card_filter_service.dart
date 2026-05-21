import 'package:hoplixi/vault_db/core/errors/db_error.dart';
import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/models/filters/base/base.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

class VaultCardFilterService {
  VaultCardFilterService(this.db);

  final VaultDB db;

  AsyncDbResult<List<FilteredCardDto<ApiKeyCardDto>>> getApiKeys(
    ApiKeyFilter filter,
  ) {
    return ResultUtils.tryCatchAsync(
      () => db.apiKeyFilterDao.getFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении отфильтрованных API ключей',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> countApiKeys(ApiKeyFilter filter) {
    return ResultUtils.tryCatchAsync(
      () => db.apiKeyFilterDao.countFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при подсчете API ключей',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<FilteredCardDto<BankCardCardDto>>> getBankCards(
    BankCardFilter filter,
  ) {
    return ResultUtils.tryCatchAsync(
      () => db.bankCardFilterDao.getFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении отфильтрованных банковских карт',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> countBankCards(BankCardFilter filter) {
    return ResultUtils.tryCatchAsync(
      () => db.bankCardFilterDao.countFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при подсчете банковских карт',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<FilteredCardDto<CertificateCardDto>>> getCertificates(
    CertificateFilter filter,
  ) {
    return ResultUtils.tryCatchAsync(
      () => db.certificateFilterDao.getFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении отфильтрованных сертификатов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> countCertificates(CertificateFilter filter) {
    return ResultUtils.tryCatchAsync(
      () => db.certificateFilterDao.countFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при подсчете сертификатов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<FilteredCardDto<ContactCardDto>>> getContacts(
    ContactFilter filter,
  ) {
    return ResultUtils.tryCatchAsync(
      () => db.contactFilterDao.getFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении отфильтрованных контактов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> countContacts(ContactFilter filter) {
    return ResultUtils.tryCatchAsync(
      () => db.contactFilterDao.countFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при подсчете контактов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<FilteredCardDto<CryptoWalletCardDto>>> getCryptoWallets(
    CryptoWalletFilter filter,
  ) {
    return ResultUtils.tryCatchAsync(
      () => db.cryptoWalletFilterDao.getFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении отфильтрованных криптокошельков',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> countCryptoWallets(CryptoWalletFilter filter) {
    return ResultUtils.tryCatchAsync(
      () => db.cryptoWalletFilterDao.countFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при подсчете криптокошельков',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<FilteredCardDto<DocumentCardDto>>> getDocuments(
    DocumentFilter filter,
  ) {
    return ResultUtils.tryCatchAsync(
      () => db.documentFilterDao.getFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении отфильтрованных документов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> countDocuments(DocumentFilter filter) {
    return ResultUtils.tryCatchAsync(
      () => db.documentFilterDao.countFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при подсчете документов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<FilteredCardDto<FileCardDto>>> getFiles(
    FileFilter filter,
  ) {
    return ResultUtils.tryCatchAsync(
      () => db.fileFilterDao.getFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении отфильтрованных файлов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> countFiles(FileFilter filter) {
    return ResultUtils.tryCatchAsync(
      () => db.fileFilterDao.countFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при подсчете файлов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<FilteredCardDto<IdentityCardDto>>> getIdentities(
    IdentityFilter filter,
  ) {
    return ResultUtils.tryCatchAsync(
      () => db.identityFilterDao.getFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении отфильтрованных идентификаторов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> countIdentities(IdentityFilter filter) {
    return ResultUtils.tryCatchAsync(
      () => db.identityFilterDao.countFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при подсчете идентификаторов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<FilteredCardDto<LicenseKeyCardDto>>> getLicenseKeys(
    LicenseKeyFilter filter,
  ) {
    return ResultUtils.tryCatchAsync(
      () => db.licenseKeyFilterDao.getFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message:
                  'Ошибка при получении отфильтрованных лицензионных ключей',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> countLicenseKeys(LicenseKeyFilter filter) {
    return ResultUtils.tryCatchAsync(
      () => db.licenseKeyFilterDao.countFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при подсчете лицензионных ключей',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<FilteredCardDto<LoyaltyCardCardDto>>> getLoyaltyCards(
    LoyaltyCardFilter filter,
  ) {
    return ResultUtils.tryCatchAsync(
      () => db.loyaltyCardFilterDao.getFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении отфильтрованных карт лояльности',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> countLoyaltyCards(LoyaltyCardFilter filter) {
    return ResultUtils.tryCatchAsync(
      () => db.loyaltyCardFilterDao.countFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при подсчете карт лояльности',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<FilteredCardDto<NoteCardDto>>> getNotes(
    NoteFilter filter,
  ) {
    return ResultUtils.tryCatchAsync(
      () => db.noteFilterDao.getFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении отфильтрованных заметок',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> countNotes(NoteFilter filter) {
    return ResultUtils.tryCatchAsync(
      () => db.noteFilterDao.countFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при подсчете заметок',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<FilteredCardDto<OtpCardDto>>> getOtps(OtpFilter filter) {
    return ResultUtils.tryCatchAsync(
      () => db.otpFilterDao.getFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении отфильтрованных OTP',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> countOtps(OtpFilter filter) {
    return ResultUtils.tryCatchAsync(
      () => db.otpFilterDao.countFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при подсчете OTP',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<FilteredCardDto<PasswordCardDto>>> getPasswords(
    PasswordFilter filter,
  ) {
    return ResultUtils.tryCatchAsync(
      () => db.passwordFilterDao.getFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении отфильтрованных паролей',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> countPasswords(PasswordFilter filter) {
    return ResultUtils.tryCatchAsync(
      () => db.passwordFilterDao.countFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при подсчете паролей',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<FilteredCardDto<RecoveryCodesCardDto>>> getRecoveryCodes(
    RecoveryCodesFilter filter,
  ) {
    return ResultUtils.tryCatchAsync(
      () => db.recoveryCodesFilterDao.getFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message:
                  'Ошибка при получении отфильтрованных кодов восстановления',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> countRecoveryCodes(RecoveryCodesFilter filter) {
    return ResultUtils.tryCatchAsync(
      () => db.recoveryCodesFilterDao.countFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при подсчете кодов восстановления',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<FilteredCardDto<SshKeyCardDto>>> getSshKeys(
    SshKeyFilter filter,
  ) {
    return ResultUtils.tryCatchAsync(
      () => db.sshKeyFilterDao.getFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении отфильтрованных SSH ключей',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> countSshKeys(SshKeyFilter filter) {
    return ResultUtils.tryCatchAsync(
      () => db.sshKeyFilterDao.countFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при подсчете SSH ключей',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<FilteredCardDto<WifiCardDto>>> getWifis(
    WifiFilter filter,
  ) {
    return ResultUtils.tryCatchAsync(
      () => db.wifiFilterDao.getFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении отфильтрованных Wi-Fi',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<int> countWifis(WifiFilter filter) {
    return ResultUtils.tryCatchAsync(
      () => db.wifiFilterDao.countFiltered(filter),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при подсчете Wi-Fi',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
