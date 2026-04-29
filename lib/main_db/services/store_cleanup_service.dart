import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/core/dao/index.dart';
import 'package:hoplixi/main_db/config/store_settings_keys.dart';
import 'package:hoplixi/main_db/services/other/file_storage_service.dart';

class StoreCleanupService {
  const StoreCleanupService(this._settingsDao, this._fileStorageService);

  final StoreSettingsDao _settingsDao;
  final FileStorageService _fileStorageService;

  Future<void> performFullCleanup({bool ignoreInterval = false}) async {
    try {
      if (!ignoreInterval && !await _isCleanupDue()) {
        return;
      }

      logInfo('Starting full store cleanup...', tag: 'StoreCleanupService');

      final historyEnabledStr = await _settingsDao.getSetting(
        StoreSettingsKeys.historyEnabled,
      );
      final isHistoryEnabled =
          historyEnabledStr == null || historyEnabledStr == 'true';

      if (isHistoryEnabled) {
        final limitStr = await _settingsDao.getSetting(
          StoreSettingsKeys.historyLimit,
        );
        final ageStr = await _settingsDao.getSetting(
          StoreSettingsKeys.historyMaxAgeDays,
        );

        await _settingsDao.cleanupHistory(
          maxAgeDays: int.tryParse(ageStr ?? '') ?? 30,
          maxRecordsPerItem: int.tryParse(limitStr ?? '') ?? 100,
        );
      } else {
        await _settingsDao.cleanupHistory(maxAgeDays: 0, maxRecordsPerItem: 0);
      }

      final deletedFilesCount = await _fileStorageService
          .cleanupOrphanedFiles();
      logInfo(
        'Orphaned files cleanup completed. Deleted $deletedFilesCount files.',
        tag: 'StoreCleanupService',
      );

      await _settingsDao.setSetting(
        StoreSettingsKeys.historyLastCleanupTimestamp,
        DateTime.now().toIso8601String(),
      );

      logInfo(
        'Full store cleanup finished successfully.',
        tag: 'StoreCleanupService',
      );
    } catch (error, stackTrace) {
      logError(
        'Error during store cleanup: $error',
        stackTrace: stackTrace,
        tag: 'StoreCleanupService',
      );
    }
  }

  Future<bool> _isCleanupDue() async {
    final lastCleanupStr = await _settingsDao.getSetting(
      StoreSettingsKeys.historyLastCleanupTimestamp,
    );
    final intervalStr = await _settingsDao.getSetting(
      StoreSettingsKeys.historyCleanupIntervalDays,
    );
    final intervalDays = int.tryParse(intervalStr ?? '') ?? 7;

    final lastCleanup = lastCleanupStr == null
        ? null
        : DateTime.tryParse(lastCleanupStr);
    if (lastCleanup == null) {
      return true;
    }

    final isDue = DateTime.now().difference(lastCleanup).inDays >= intervalDays;
    if (!isDue) {
      logInfo(
        'Skip cleanup: interval ($intervalDays days) not reached yet.',
        tag: 'StoreCleanupService',
      );
    }
    return isDue;
  }
}
