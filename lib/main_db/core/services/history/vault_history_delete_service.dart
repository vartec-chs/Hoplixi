import 'package:result_dart/result_dart.dart';

import '../../daos/daos.dart';
import '../../errors/db_error.dart';
import '../../errors/db_result.dart';
import '../../main_store.dart';
import '../../tables/vault_items/vault_items.dart';

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
    required this.customFieldsHistoryDao,
    required this.vaultItemTagHistoryDao,
    required this.itemLinkHistoryDao,
    required this.itemCategoryHistoryDao,
    required this.vaultEventsHistoryDao,
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
  final VaultItemCustomFieldsHistoryDao customFieldsHistoryDao;
  final VaultItemTagHistoryDao vaultItemTagHistoryDao;
  final ItemLinkHistoryDao itemLinkHistoryDao;
  final ItemCategoryHistoryDao itemCategoryHistoryDao;
  final VaultEventsHistoryDao vaultEventsHistoryDao;

  Future<DbResult<Unit>> deleteRevision(String historyId) async {
    try {
      await db.transaction(() async {
        await _deleteRevisionUnsafe(historyId);
      });
      return Success(unit);
    } catch (e, s) {
      return Failure(
        DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s),
      );
    }
  }

  Future<void> _deleteRevisionUnsafe(String historyId) async {
    final snapshot = await snapshotsHistoryDao.getSnapshotById(historyId);
    if (snapshot == null) {
      throw Exception('History snapshot not found: $historyId');
    }

    // 1. Clear event snapshot reference (audit log stays)
    await vaultEventsHistoryDao.clearSnapshotReference(historyId);

    // 2. Delete relation history
    await customFieldsHistoryDao.deleteCustomFieldsHistoryBySnapshotHistoryId(
      historyId,
    );
    await vaultItemTagHistoryDao.deleteTagsBySnapshotHistoryId(historyId);

    await itemLinkHistoryDao.deleteLinksBySnapshotHistoryId(historyId);

    // 3. Delete type-specific history row
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
        await certificateHistoryDao.deleteCertificateHistoryByHistoryId(
          historyId,
        );
        break;
      case VaultItemType.cryptoWallet:
        await cryptoWalletHistoryDao.deleteCryptoWalletHistoryByHistoryId(
          historyId,
        );
        break;
      case VaultItemType.wifi:
        await wifiHistoryDao.deleteWifiHistoryByHistoryId(historyId);
        break;
      case VaultItemType.sshKey:
        await sshKeyHistoryDao.deleteSshKeyHistoryByHistoryId(historyId);
        break;
      case VaultItemType.licenseKey:
        await licenseKeyHistoryDao.deleteLicenseKeyHistoryByHistoryId(
          historyId,
        );
        break;
      case VaultItemType.otp:
        await otpHistoryDao.deleteOtpHistoryByHistoryId(historyId);
        break;
      case VaultItemType.recoveryCodes:
        await recoveryCodeValuesHistoryDao
            .deleteRecoveryCodeValuesHistoryByHistoryId(historyId);
        await recoveryCodesHistoryDao.deleteRecoveryCodesHistoryByHistoryId(
          historyId,
        );
        break;
      case VaultItemType.loyaltyCard:
        await loyaltyCardHistoryDao.deleteLoyaltyCardHistoryByHistoryId(
          historyId,
        );
        break;
      case VaultItemType.file:
        await fileMetadataHistoryDao.deleteFileMetadataHistoryByHistoryId(
          historyId,
        );
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
        break;
    }

    // 4. Delete item category history snapshot if it exists
    if (snapshot.categoryHistoryId != null) {
      await itemCategoryHistoryDao.deleteCategoryHistoryById(
        snapshot.categoryHistoryId!,
      );
    }

    // 5. Delete vault snapshot row
    await snapshotsHistoryDao.deleteSnapshotById(historyId);
  }

  Future<DbResult<Unit>> clearItemHistory({
    required String itemId,
    required VaultItemType type,
  }) async {
    try {
      await db.transaction(() async {
        final ids = await snapshotsHistoryDao.getSnapshotIdsForItem(
          itemId: itemId,
          type: type,
        );

        for (final id in ids) {
          await _deleteRevisionUnsafe(id);
        }
      });

      return Success(unit);
    } catch (e, s) {
      return Failure(
        DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s),
      );
    }
  }
}
