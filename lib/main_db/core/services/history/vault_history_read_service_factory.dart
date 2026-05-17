import '../../main_store.dart';
import 'readers/readers.dart';
import 'vault_history_read_service.dart';

class VaultHistoryReadServiceFactory {
  static VaultHistoryReadService create(MainStore db) {
    final readerRegistry = VaultHistoryCardReaderRegistry([
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

    return VaultHistoryReadService(
      snapshotFilterDao: db.vaultSnapshotHistoryFilterDao,
      snapshotsHistoryDao: db.vaultSnapshotsHistoryDao,
      readerRegistry: readerRegistry,
      genericReader: GenericHistoryCardReader(),
    );
  }
}
