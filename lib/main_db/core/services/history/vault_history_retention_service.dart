import 'package:result_dart/result_dart.dart';
import '../../errors/db_result.dart';
import '../../errors/db_error.dart';
import '../../daos/daos.dart';
import '../../tables/vault_items/vault_items.dart';
import 'vault_history_delete_service.dart';
import 'package:drift/drift.dart';

class VaultHistoryRetentionService {
  VaultHistoryRetentionService({
    required this.snapshotsHistoryDao,
    required this.deleteService,
  });

  final VaultSnapshotsHistoryDao snapshotsHistoryDao;
  final VaultHistoryDeleteService deleteService;

  Future<DbResult<Unit>> maybeCleanup() async {
    // TODO: Implement global retention policy logic
    return Success(unit);
  }

  Future<DbResult<Unit>> cleanupByItemLimit({
    required String itemId,
    required VaultItemType type,
    required int limit,
  }) async {
    try {
      final snapshots = await (snapshotsHistoryDao.select(snapshotsHistoryDao.vaultSnapshotsHistory)
            ..where((t) => t.itemId.equals(itemId))
            ..orderBy([(t) => OrderingTerm.desc(t.historyCreatedAt)]))
          .get();

      if (snapshots.length <= limit) {
        return Success(unit);
      }

      final snapshotsToDelete = snapshots.skip(limit).toList();

      for (final s in snapshotsToDelete) {
        final res = await deleteService.deleteRevision(s.id);
        if (res.isError()) {
          return Failure(res.exceptionOrNull() as DBCoreError);
        }
      }

      return Success(unit);
    } catch (e, s) {
      return Failure(DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s));
    }
  }
}
