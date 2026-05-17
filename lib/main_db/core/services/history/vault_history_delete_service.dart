import 'package:result_dart/result_dart.dart';
import '../../errors/db_result.dart';
import '../../errors/db_error.dart';
import '../../daos/daos.dart';
import '../../tables/vault_items/vault_items.dart';
import '../../main_store.dart';

class VaultHistoryDeleteService {
  VaultHistoryDeleteService({
    required this.db,
    required this.snapshotsHistoryDao,
    required this.apiKeyHistoryDao,
    required this.passwordHistoryDao,
    required this.bankCardHistoryDao,
    required this.certificateHistoryDao,
    required this.cryptoWalletHistoryDao,
    required this.wifiHistoryDao,
    required this.sshKeyHistoryDao,
    required this.licenseKeyHistoryDao,
    required this.otpHistoryDao,
    required this.recoveryCodesHistoryDao,
    required this.recoveryCodeValuesHistoryDao,
    required this.loyaltyCardHistoryDao,
    required this.fileHistoryDao,
    required this.fileMetadataHistoryDao,
    required this.contactHistoryDao,
    required this.identityHistoryDao,
    required this.noteHistoryDao,
  });

  final MainStore db;
  final VaultSnapshotsHistoryDao snapshotsHistoryDao;
  final ApiKeyHistoryDao apiKeyHistoryDao;
  final PasswordHistoryDao passwordHistoryDao;
  final BankCardHistoryDao bankCardHistoryDao;
  final CertificateHistoryDao certificateHistoryDao;
  final CryptoWalletHistoryDao cryptoWalletHistoryDao;
  final WifiHistoryDao wifiHistoryDao;
  final SshKeyHistoryDao sshKeyHistoryDao;
  final LicenseKeyHistoryDao licenseKeyHistoryDao;
  final OtpHistoryDao otpHistoryDao;
  final RecoveryCodesHistoryDao recoveryCodesHistoryDao;
  final RecoveryCodeValuesHistoryDao recoveryCodeValuesHistoryDao;
  final LoyaltyCardHistoryDao loyaltyCardHistoryDao;
  final FileHistoryDao fileHistoryDao;
  final FileMetadataHistoryDao fileMetadataHistoryDao;
  final ContactHistoryDao contactHistoryDao;
  final IdentityHistoryDao identityHistoryDao;
  final NoteHistoryDao noteHistoryDao;

  Future<DbResult<Unit>> deleteRevision(String historyId) async {
    try {
      final snapshot = await snapshotsHistoryDao.getSnapshotById(historyId);
      if (snapshot == null) {
        return Failure(DBCoreError.notFound(entity: 'HistorySnapshot', id: historyId));
      }

      return await db.transaction(() async {
        // Delete type-specific history row
        switch (snapshot.type) {
          case VaultItemType.apiKey:
            await apiKeyHistoryDao.deleteApiKeyHistoryByHistoryId(historyId);
            break;
          case VaultItemType.password:
            await passwordHistoryDao.deletePasswordHistoryByHistoryId(historyId);
            break;
          case VaultItemType.bankCard:
            await bankCardHistoryDao.deleteBankCardHistoryByHistoryId(historyId);
            break;
          case VaultItemType.certificate:
            await certificateHistoryDao.deleteCertificateHistoryByHistoryId(historyId);
            break;
          case VaultItemType.cryptoWallet:
            await cryptoWalletHistoryDao.deleteCryptoWalletHistoryByHistoryId(historyId);
            break;
          case VaultItemType.wifi:
            await wifiHistoryDao.deleteWifiHistoryByHistoryId(historyId);
            break;
          case VaultItemType.sshKey:
            await sshKeyHistoryDao.deleteSshKeyHistoryByHistoryId(historyId);
            break;
          case VaultItemType.licenseKey:
            await licenseKeyHistoryDao.deleteLicenseKeyHistoryByHistoryId(historyId);
            break;
          case VaultItemType.otp:
            await otpHistoryDao.deleteOtpHistoryByHistoryId(historyId);
            break;
          case VaultItemType.recoveryCodes:
            await recoveryCodeValuesHistoryDao.deleteRecoveryCodeValuesHistoryByHistoryId(historyId);
            await recoveryCodesHistoryDao.deleteRecoveryCodesHistoryByHistoryId(historyId);
            break;
          case VaultItemType.loyaltyCard:
            await loyaltyCardHistoryDao.deleteLoyaltyCardHistoryByHistoryId(historyId);
            break;
          case VaultItemType.file:
            await fileMetadataHistoryDao.deleteFileMetadataHistoryByHistoryId(historyId);
            await fileHistoryDao.deleteFileHistoryByHistoryId(historyId);
            break;
          case VaultItemType.contact:
            await contactHistoryDao.deleteContactHistoryByHistoryId(historyId);
            break;
          case VaultItemType.identity:
            await identityHistoryDao.deleteIdentityHistoryByHistoryId(historyId);
            break;
          case VaultItemType.note:
            await noteHistoryDao.deleteNoteHistoryByHistoryId(historyId);
            break;
          case VaultItemType.document:
            // TODO: Delete document history if implemented
            break;
        }

        // Delete snapshot row
        await snapshotsHistoryDao.deleteSnapshotById(historyId);

        return Success(unit);
      });
    } catch (e, s) {
      return Failure(DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s));
    }
  }

  Future<DbResult<Unit>> clearItemHistory({
    required String itemId,
    required VaultItemType type,
  }) async {
    // TODO: Implement clearing all history for an item
    return Success(unit);
  }
}
