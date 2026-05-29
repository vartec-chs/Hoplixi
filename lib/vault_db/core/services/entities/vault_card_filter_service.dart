import 'package:hoplixi/vault_db/core/errors/db_error.dart';
import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/models/filters/base/base.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

class VaultCardFilterService {
  VaultCardFilterService(this.db);

  final VaultDB db;

  AsyncDBResult<List<FilteredCardDto<ApiKeyCardDto>>> getApiKeys(
    ApiKeyFilter filter,
  ) {
    return tryCatchAsync(
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

  AsyncDBResult<int> countApiKeys(ApiKeyFilter filter) {
    return tryCatchAsync(
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

  AsyncDBResult<List<FilteredCardDto<BankCardCardDto>>> getBankCards(
    BankCardFilter filter,
  ) {
    return tryCatchAsync(
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

  AsyncDBResult<int> countBankCards(BankCardFilter filter) {
    return tryCatchAsync(
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

  AsyncDBResult<List<FilteredCardDto<CertificateCardDto>>> getCertificates(
    CertificateFilter filter,
  ) {
    return tryCatchAsync(
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

  AsyncDBResult<int> countCertificates(CertificateFilter filter) {
    return tryCatchAsync(
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

  AsyncDBResult<List<FilteredCardDto<ContactCardDto>>> getContacts(
    ContactFilter filter,
  ) {
    return tryCatchAsync(
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

  AsyncDBResult<int> countContacts(ContactFilter filter) {
    return tryCatchAsync(
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

  AsyncDBResult<List<FilteredCardDto<CryptoWalletCardDto>>> getCryptoWallets(
    CryptoWalletFilter filter,
  ) {
    return tryCatchAsync(
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

  AsyncDBResult<int> countCryptoWallets(CryptoWalletFilter filter) {
    return tryCatchAsync(
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

  AsyncDBResult<List<FilteredCardDto<DocumentCardDto>>> getDocuments(
    DocumentFilter filter,
  ) {
    return tryCatchAsync(
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

  AsyncDBResult<int> countDocuments(DocumentFilter filter) {
    return tryCatchAsync(
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

  AsyncDBResult<List<FilteredCardDto<FileCardDto>>> getFiles(
    FileFilter filter,
  ) {
    return tryCatchAsync(
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

  AsyncDBResult<int> countFiles(FileFilter filter) {
    return tryCatchAsync(
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

  AsyncDBResult<List<FilteredCardDto<IdentityCardDto>>> getIdentities(
    IdentityFilter filter,
  ) {
    return tryCatchAsync(
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

  AsyncDBResult<int> countIdentities(IdentityFilter filter) {
    return tryCatchAsync(
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

  AsyncDBResult<List<FilteredCardDto<LicenseKeyCardDto>>> getLicenseKeys(
    LicenseKeyFilter filter,
  ) {
    return tryCatchAsync(
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

  AsyncDBResult<int> countLicenseKeys(LicenseKeyFilter filter) {
    return tryCatchAsync(
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

  AsyncDBResult<List<FilteredCardDto<LoyaltyCardCardDto>>> getLoyaltyCards(
    LoyaltyCardFilter filter,
  ) {
    return tryCatchAsync(
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

  AsyncDBResult<int> countLoyaltyCards(LoyaltyCardFilter filter) {
    return tryCatchAsync(
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

  AsyncDBResult<List<FilteredCardDto<NoteCardDto>>> getNotes(
    NoteFilter filter,
  ) {
    return tryCatchAsync(
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

  AsyncDBResult<int> countNotes(NoteFilter filter) {
    return tryCatchAsync(
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

  AsyncDBResult<List<FilteredCardDto<OtpCardDto>>> getOtps(OtpFilter filter) {
    return tryCatchAsync(
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

  AsyncDBResult<int> countOtps(OtpFilter filter) {
    return tryCatchAsync(
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

  AsyncDBResult<List<FilteredCardDto<PasswordCardDto>>> getPasswords(
    PasswordFilter filter,
  ) {
    return tryCatchAsync(
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

  AsyncDBResult<int> countPasswords(PasswordFilter filter) {
    return tryCatchAsync(
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

  AsyncDBResult<List<FilteredCardDto<RecoveryCodesCardDto>>> getRecoveryCodes(
    RecoveryCodesFilter filter,
  ) {
    return tryCatchAsync(
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

  AsyncDBResult<int> countRecoveryCodes(RecoveryCodesFilter filter) {
    return tryCatchAsync(
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

  AsyncDBResult<List<FilteredCardDto<SshKeyCardDto>>> getSshKeys(
    SshKeyFilter filter,
  ) {
    return tryCatchAsync(
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

  AsyncDBResult<int> countSshKeys(SshKeyFilter filter) {
    return tryCatchAsync(
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

  AsyncDBResult<List<FilteredCardDto<WifiCardDto>>> getWifis(
    WifiFilter filter,
  ) {
    return tryCatchAsync(
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

  AsyncDBResult<int> countWifis(WifiFilter filter) {
    return tryCatchAsync(
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
