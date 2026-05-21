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

  AsyncDbResult<Unit> maybeCleanup() {
    return ResultUtils.tryCatchAsync(
      () async {
        final enabled =
            await settingsDao.getBool(StoreSettingsKey.historyEnabled) ?? true;
        if (!enabled) return unit;

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
              return unit;
            }
          }
        }

        // Perform cleanup
        final maxAgeDays = await settingsDao.getInt(
          StoreSettingsKey.historyMaxAgeDays,
        );
        if (maxAgeDays != null && maxAgeDays > 0) {
          (await cleanupByMaxAge(maxAgeDays: maxAgeDays)).getOrThrow();
        }

        final historyLimit = await settingsDao.getInt(
          StoreSettingsKey.historyLimit,
        );
        if (historyLimit != null && historyLimit > 0) {
          final groups = await snapshotsHistoryDao.getSnapshotItemGroups();
          for (final group in groups) {
            (await cleanupByItemLimit(
              itemId: group.itemId,
              type: group.type,
              limit: historyLimit,
            )).getOrThrow();
          }
        }

        // Update last cleanup timestamp
        await settingsDao.setString(
          StoreSettingsKey.historyLastCleanupTimestamp,
          DateTime.now().toIso8601String(),
        );

        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при автоматической очистке истории',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> cleanupByItemLimit({
    required String itemId,
    required VaultItemType type,
    required int limit,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        final snapshots = await snapshotsHistoryDao.getSnapshotsForItem(
          itemId: itemId,
          type: type,
        );

        if (snapshots.length <= limit) {
          return unit;
        }

        final snapshotsToDelete = snapshots.skip(limit).toList();

        for (final s in snapshotsToDelete) {
          (await deleteService.deleteRevision(s.id)).getOrThrow();
        }

        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при очистке истории по лимиту элементов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> cleanupByMaxAge({required int maxAgeDays}) {
    return ResultUtils.tryCatchAsync(
      () async {
        if (maxAgeDays <= 0) {
          throw const DBCoreError.validation(
            code: 'history.cleanup.invalid_age',
            message: 'Max age must be greater than 0',
          );
        }

        final threshold = DateTime.now().subtract(Duration(days: maxAgeDays));
        final ids = await snapshotsHistoryDao.getSnapshotIdsOlderThan(
          threshold,
        );

        for (final id in ids) {
          (await deleteService.deleteRevision(id)).getOrThrow();
        }

        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при очистке истории по возрасту',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
