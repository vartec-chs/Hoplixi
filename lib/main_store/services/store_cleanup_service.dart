import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/dao/index.dart';
import 'package:hoplixi/main_store/models/store_settings_keys.dart';
import 'package:hoplixi/main_store/services/file_storage_service.dart';

/// Сервис для глобальной очистки хранилища (базы данных и файлов)
class StoreCleanupService {
  final StoreSettingsDao _settingsDao;
  final FileStorageService _fileStorageService;

  StoreCleanupService(this._settingsDao, this._fileStorageService);

  /// Выполнить полную очистку хранилища в соответствии с текущими настройками.
  /// Включает:
  /// - чистку устаревших записей истории в БД
  /// - удаление сиротских файлов и их метаданных, ссылки на которые пропали из базы
  /// [ignoreInterval] - игнорировать проверку периода очистки (по умолчанию false)
  Future<void> performFullCleanup({bool ignoreInterval = false}) async {
    try {
      if (!ignoreInterval) {
        final lastCleanupStr = await _settingsDao.getSetting(
          StoreSettingsKeys.historyLastCleanupTimestamp,
        );
        final intervalStr = await _settingsDao.getSetting(
          StoreSettingsKeys.historyCleanupIntervalDays,
        );

        final intervalDays = intervalStr != null
            ? int.tryParse(intervalStr) ?? 7
            : 7;

        if (lastCleanupStr != null) {
          final lastCleanup = DateTime.tryParse(lastCleanupStr);
          if (lastCleanup != null) {
            final diff = DateTime.now().difference(lastCleanup);
            if (diff.inDays < intervalDays) {
              logInfo(
                'Skip cleanup: interval ($intervalDays days) not reached yet (last cleanup: $lastCleanup).',
                tag: 'StoreCleanupService',
              );
              return;
            }
          }
        }
      }

      logInfo('Starting full store cleanup...', tag: 'StoreCleanupService');

      // 1. Очистка истории
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

        final limit = limitStr != null ? int.tryParse(limitStr) ?? 100 : 100;
        final maxAgeDays = ageStr != null ? int.tryParse(ageStr) ?? 30 : 30;

        await _settingsDao.cleanupHistory(
          maxAgeDays: maxAgeDays,
          maxRecordsPerItem: limit,
        );
        logInfo(
          'History cleanup completed. (limit: $limit, max_age: $maxAgeDays days)',
          tag: 'StoreCleanupService',
        );
      } else {
        // Если история выключена, удаляем всю историю
        await _settingsDao.cleanupHistory(maxAgeDays: 0, maxRecordsPerItem: 0);
        logInfo(
          'History disabled. All history records cleared.',
          tag: 'StoreCleanupService',
        );
      }

      // 2. Очистка файлов-сирот
      final deletedFilesCount = await _fileStorageService
          .cleanupOrphanedFiles();
      logInfo(
        'Orphaned files cleanup completed. Deleted $deletedFilesCount files.',
        tag: 'StoreCleanupService',
      );

      // Обновляем метку времени последней очистки
      await _settingsDao.setSetting(
        StoreSettingsKeys.historyLastCleanupTimestamp,
        DateTime.now().toIso8601String(),
      );

      logInfo(
        'Full store cleanup finished successfully.',
        tag: 'StoreCleanupService',
      );
    } catch (e, s) {
      logError(
        'Error during store cleanup: $e',
        stackTrace: s,
        tag: 'StoreCleanupService',
      );
    }
  }
}
