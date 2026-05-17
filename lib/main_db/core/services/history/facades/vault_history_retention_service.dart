import 'package:result_dart/result_dart.dart';
import '../../../errors/db_result.dart';
import '../../../errors/db_error.dart';
import '../../../daos/daos.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../../../config/store_settings_keys.dart';
import 'vault_history_delete_service.dart';

class VaultHistoryRetentionService {
  VaultHistoryRetentionService({
    required this.snapshotsHistoryDao,
    required this.deleteService,
    required this.settingsDao,
  });

  final VaultSnapshotsHistoryDao snapshotsHistoryDao;
  final VaultHistoryDeleteService deleteService;
  final StoreSettingsDao settingsDao;

  Future<DbResult<Unit>> maybeCleanup() async {
    try {
      final enabled =
          await settingsDao.getBool(StoreSettingsKey.historyEnabled) ?? true;
      if (!enabled) return Success(unit);

      final intervalDays =
          await settingsDao.getInt(
            StoreSettingsKey.historyCleanupIntervalDays,
          ) ??
          7;
      final lastCleanupStr = await settingsDao.getString(
        StoreSettingsKey.historyLastCleanupTimestamp,
      );

      if (lastCleanupStr != null) {
        final lastCleanup = DateTime.tryParse(lastCleanupStr);
        if (lastCleanup != null) {
          final nextCleanup = lastCleanup.add(Duration(days: intervalDays));
          if (DateTime.now().isBefore(nextCleanup)) {
            return Success(unit);
          }
        }
      }

      // Perform cleanup
      final maxAgeDays = await settingsDao.getInt(
        StoreSettingsKey.historyMaxAgeDays,
      );
      if (maxAgeDays != null && maxAgeDays > 0) {
        await cleanupByMaxAge(maxAgeDays: maxAgeDays);
      }

      final historyLimit = await settingsDao.getInt(
        StoreSettingsKey.historyLimit,
      );
      if (historyLimit != null && historyLimit > 0) {
        final groups = await snapshotsHistoryDao.getSnapshotItemGroups();
        for (final group in groups) {
          await cleanupByItemLimit(
            itemId: group.itemId,
            type: group.type,
            limit: historyLimit,
          );
        }
      }

      // Update last cleanup timestamp
      await settingsDao.setString(
        StoreSettingsKey.historyLastCleanupTimestamp,
        DateTime.now().toIso8601String(),
      );

      return Success(unit);
    } catch (e, s) {
      return Failure(
        DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s),
      );
    }
  }

  Future<DbResult<Unit>> cleanupByItemLimit({
    required String itemId,
    required VaultItemType type,
    required int limit,
  }) async {
    try {
      final snapshots = await snapshotsHistoryDao.getSnapshotsForItem(
        itemId: itemId,
        type: type,
      );

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
      return Failure(
        DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s),
      );
    }
  }

  Future<DbResult<Unit>> cleanupByMaxAge({required int maxAgeDays}) async {
    if (maxAgeDays <= 0) {
      return const Failure(
        DBCoreError.validation(
          code: 'history.cleanup.invalid_age',
          message: 'Max age must be greater than 0',
        ),
      );
    }

    try {
      final threshold = DateTime.now().subtract(Duration(days: maxAgeDays));
      final ids = await snapshotsHistoryDao.getSnapshotIdsOlderThan(threshold);

      for (final id in ids) {
        final res = await deleteService.deleteRevision(id);
        if (res.isError()) {
          return Failure(res.exceptionOrNull() as DBCoreError);
        }
      }

      return Success(unit);
    } catch (e, s) {
      return Failure(
        DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s),
      );
    }
  }
}
