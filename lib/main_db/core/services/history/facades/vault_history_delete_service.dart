import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../main_store.dart';
import '../../../tables/vault_items/vault_items.dart';

class VaultHistoryDeleteService {
  VaultHistoryDeleteService({required this.db});

  final MainStore db;

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
    final snapshot = await db.vaultSnapshotsHistoryDao.getSnapshotById(
      historyId,
    );
    if (snapshot == null) {
      throw Exception('History snapshot not found: $historyId');
    }

    // 1. Clear event snapshot reference (audit log stays)
    await db.vaultEventsHistoryDao.clearSnapshotReference(historyId);

    // 2. Delete relation history
    await db.vaultItemCustomFieldsHistoryDao
        .deleteCustomFieldsHistoryBySnapshotHistoryId(historyId);
    await db.vaultItemTagHistoryDao.deleteTagsBySnapshotHistoryId(historyId);

    await db.itemLinkHistoryDao.deleteLinksBySnapshotHistoryId(historyId);

    // 3. Delete type-specific history row
    switch (snapshot.type) {
      case VaultItemType.apiKey:
        await db.apiKeyHistoryDao.deleteApiKeyHistoryByHistoryId(historyId);
        break;
      case VaultItemType.password:
        await db.passwordHistoryDao.deletePasswordHistoryByHistoryId(historyId);
        break;
      case VaultItemType.bankCard:
        await db.bankCardHistoryDao.deleteBankCardHistoryByHistoryId(historyId);
        break;
      case VaultItemType.certificate:
        await db.certificateHistoryDao.deleteCertificateHistoryByHistoryId(
          historyId,
        );
        break;
      case VaultItemType.cryptoWallet:
        await db.cryptoWalletHistoryDao.deleteCryptoWalletHistoryByHistoryId(
          historyId,
        );
        break;
      case VaultItemType.wifi:
        await db.wifiHistoryDao.deleteWifiHistoryByHistoryId(historyId);
        break;
      case VaultItemType.sshKey:
        await db.sshKeyHistoryDao.deleteSshKeyHistoryByHistoryId(historyId);
        break;
      case VaultItemType.licenseKey:
        await db.licenseKeyHistoryDao.deleteLicenseKeyHistoryByHistoryId(
          historyId,
        );
        break;
      case VaultItemType.otp:
        await db.otpHistoryDao.deleteOtpHistoryByHistoryId(historyId);
        break;
      case VaultItemType.recoveryCodes:
        await db.recoveryCodeValuesHistoryDao
            .deleteRecoveryCodeValuesHistoryByHistoryId(historyId);
        await db.recoveryCodesHistoryDao.deleteRecoveryCodesHistoryByHistoryId(
          historyId,
        );
        break;
      case VaultItemType.loyaltyCard:
        await db.loyaltyCardHistoryDao.deleteLoyaltyCardHistoryByHistoryId(
          historyId,
        );
        break;
      case VaultItemType.file:
        await db.fileMetadataHistoryDao.deleteFileMetadataHistoryByHistoryId(
          historyId,
        );
        await db.fileHistoryDao.deleteFileHistoryByHistoryId(historyId);
        break;
      case VaultItemType.contact:
        await db.contactHistoryDao.deleteContactHistoryByHistoryId(historyId);
        break;
      case VaultItemType.identity:
        await db.identityHistoryDao.deleteIdentityHistoryByHistoryId(historyId);
        break;
      case VaultItemType.note:
        await db.noteHistoryDao.deleteNoteHistoryByHistoryId(historyId);
        break;
      case VaultItemType.document:
        break;
    }

    // 4. Delete item category history snapshot if it exists
    if (snapshot.categoryHistoryId != null) {
      await db.itemCategoryHistoryDao.deleteCategoryHistoryById(
        snapshot.categoryHistoryId!,
      );
    }

    // 5. Delete vault snapshot row
    await db.vaultSnapshotsHistoryDao.deleteSnapshotById(historyId);
  }

  Future<DbResult<Unit>> clearItemHistory({
    required String itemId,
    required VaultItemType type,
  }) async {
    try {
      await db.transaction(() async {
        final ids = await db.vaultSnapshotsHistoryDao.getSnapshotIdsForItem(
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
