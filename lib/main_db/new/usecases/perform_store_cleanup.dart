import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/core/dao/index.dart';
import 'package:hoplixi/main_db/new/config/store_settings_keys.dart';
import 'package:hoplixi/main_db/new/services/other/file_storage_service.dart';

enum StoreCleanupStatus { completed, skippedByInterval, failed }

class StoreCleanupResult {
  static const int _zeroDeletedFilesCount = 0;

  final StoreCleanupStatus status;
  final String message;
  final bool historyCleanupPerformed;
  final bool historyWasDisabled;
  final int? historyLimit;
  final int? historyMaxAgeDays;
  final int orphanedFilesDeleted;
  final String? errorMessage;

  const StoreCleanupResult({
    required this.status,
    required this.message,
    required this.historyCleanupPerformed,
    required this.historyWasDisabled,
    required this.historyLimit,
    required this.historyMaxAgeDays,
    required this.orphanedFilesDeleted,
    this.errorMessage,
  });

  bool get isSuccess =>
      status == StoreCleanupStatus.completed ||
      status == StoreCleanupStatus.skippedByInterval;

  factory StoreCleanupResult.skippedByInterval({
    required String message,
    required int intervalDays,
    required DateTime lastCleanup,
  }) {
    return StoreCleanupResult(
      status: StoreCleanupStatus.skippedByInterval,
      message: message,
      historyCleanupPerformed: false,
      historyWasDisabled: false,
      historyLimit: null,
      historyMaxAgeDays: null,
      orphanedFilesDeleted: _zeroDeletedFilesCount,
      errorMessage:
          'Interval not reached yet (intervalDays: $intervalDays, lastCleanup: $lastCleanup)',
    );
  }

  factory StoreCleanupResult.completed({
    required String message,
    required bool historyCleanupPerformed,
    required bool historyWasDisabled,
    required int? historyLimit,
    required int? historyMaxAgeDays,
    required int orphanedFilesDeleted,
  }) {
    return StoreCleanupResult(
      status: StoreCleanupStatus.completed,
      message: message,
      historyCleanupPerformed: historyCleanupPerformed,
      historyWasDisabled: historyWasDisabled,
      historyLimit: historyLimit,
      historyMaxAgeDays: historyMaxAgeDays,
      orphanedFilesDeleted: orphanedFilesDeleted,
    );
  }

  factory StoreCleanupResult.failed({
    required String message,
    required String errorMessage,
  }) {
    return StoreCleanupResult(
      status: StoreCleanupStatus.failed,
      message: message,
      historyCleanupPerformed: false,
      historyWasDisabled: false,
      historyLimit: null,
      historyMaxAgeDays: null,
      orphanedFilesDeleted: _zeroDeletedFilesCount,
      errorMessage: errorMessage,
    );
  }
}

/// Сервис для глобальной очистки хранилища (базы данных и файлов)
class PerformStoreCleanup {
  static const int _defaultCleanupIntervalDays = 7;
  static const int _defaultHistoryLimit = 100;
  static const int _defaultHistoryMaxAgeDays = 30;
  static const int _disabledHistoryValue = 0;

  final StoreSettingsDao _settingsDao;
  final FileStorageService _fileStorageService;

  PerformStoreCleanup(this._settingsDao, this._fileStorageService);

  /// Выполнить полную очистку хранилища в соответствии с текущими настройками.
  /// Включает:
  /// - чистку устаревших записей истории в БД
  /// - удаление сиротских файлов и их метаданных, ссылки на которые пропали из базы
  /// [ignoreInterval] - игнорировать проверку периода очистки (по умолчанию false)
  Future<StoreCleanupResult> call({bool ignoreInterval = false}) async {
    try {
      if (!ignoreInterval) {
        final lastCleanupStr = await _settingsDao.getSetting(
          StoreSettingsKeys.historyLastCleanupTimestamp,
        );
        final intervalStr = await _settingsDao.getSetting(
          StoreSettingsKeys.historyCleanupIntervalDays,
        );

        final intervalDays = intervalStr != null
            ? int.tryParse(intervalStr) ?? _defaultCleanupIntervalDays
            : _defaultCleanupIntervalDays;

        if (lastCleanupStr != null) {
          final lastCleanup = DateTime.tryParse(lastCleanupStr);
          if (lastCleanup != null) {
            final diff = DateTime.now().difference(lastCleanup);
            if (diff.inDays < intervalDays) {
              final message =
                  'Skip cleanup: interval ($intervalDays days) not reached yet (last cleanup: $lastCleanup).';
              logInfo(message, tag: 'StoreCleanupService');
              return StoreCleanupResult.skippedByInterval(
                message: message,
                intervalDays: intervalDays,
                lastCleanup: lastCleanup,
              );
            }
          }
        }
      }

      logInfo('Starting full store cleanup...', tag: 'StoreCleanupService');

      var historyCleanupPerformed = false;
      var historyWasDisabled = false;
      int? historyLimit;
      int? historyMaxAgeDays;

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

        historyLimit = limitStr != null
            ? int.tryParse(limitStr) ?? _defaultHistoryLimit
            : _defaultHistoryLimit;
        historyMaxAgeDays = ageStr != null
            ? int.tryParse(ageStr) ?? _defaultHistoryMaxAgeDays
            : _defaultHistoryMaxAgeDays;

        await _settingsDao.cleanupHistory(
          maxAgeDays: historyMaxAgeDays,
          maxRecordsPerItem: historyLimit,
        );
        historyCleanupPerformed = true;
        logInfo(
          'History cleanup completed. (limit: $historyLimit, max_age: $historyMaxAgeDays days)',
          tag: 'StoreCleanupService',
        );
      } else {
        // Если история выключена, удаляем всю историю
        await _settingsDao.cleanupHistory(
          maxAgeDays: _disabledHistoryValue,
          maxRecordsPerItem: _disabledHistoryValue,
        );
        historyCleanupPerformed = true;
        historyWasDisabled = true;
        historyLimit = _disabledHistoryValue;
        historyMaxAgeDays = _disabledHistoryValue;
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

      return StoreCleanupResult.completed(
        message: 'Full store cleanup finished successfully.',
        historyCleanupPerformed: historyCleanupPerformed,
        historyWasDisabled: historyWasDisabled,
        historyLimit: historyLimit,
        historyMaxAgeDays: historyMaxAgeDays,
        orphanedFilesDeleted: deletedFilesCount,
      );
    } catch (e, s) {
      logError(
        'Error during store cleanup: $e',
        stackTrace: s,
        tag: 'StoreCleanupService',
      );

      return StoreCleanupResult.failed(
        message: 'Store cleanup failed.',
        errorMessage: e.toString(),
      );
    }
  }
}
