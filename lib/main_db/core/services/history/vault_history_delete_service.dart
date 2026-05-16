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
    // Add other DAOs
  });

  final MainStore db;

  final VaultSnapshotsHistoryDao snapshotsHistoryDao;
  final ApiKeyHistoryDao apiKeyHistoryDao;
  final PasswordHistoryDao passwordHistoryDao;

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
          // Stage 1: Others TODO
          default:
            break;
        }

        // TODO: Delete custom fields history, etc.

        // Delete snapshot row (should be cascade if FK set, but let's be explicit if needed)
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
    try {
      // TODO: Implement clearing all history for an item
      return Success(unit);
    } catch (e, s) {
      return Failure(DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s));
    }
  }
}
