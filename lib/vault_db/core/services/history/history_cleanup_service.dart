import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/vault_db/core/config/store_settings_keys.dart';
import 'package:hoplixi/vault_db/core/daos/base/system/store_settings_dao.dart';
import 'package:hoplixi/vault_db/services/other/file_storage_service.dart';

enum HistoryCleanupStatus { completed, skippedByInterval, failed }

class HistoryCleanupResult {
  static const int _zeroDeletedFilesCount = 0;

  final HistoryCleanupStatus status;
  final String message;
  final bool historyCleanupPerformed;
  final bool historyWasDisabled;
  final int? historyLimit;
  final int? historyMaxAgeDays;
  final int orphanedFilesDeleted;
  final String? errorMessage;

  const HistoryCleanupResult({
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
      status == HistoryCleanupStatus.completed ||
      status == HistoryCleanupStatus.skippedByInterval;

  factory HistoryCleanupResult.skippedByInterval({
    required String message,
    required int intervalDays,
    required DateTime lastCleanup,
  }) {
    return HistoryCleanupResult(
      status: HistoryCleanupStatus.skippedByInterval,
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

  factory HistoryCleanupResult.completed({
    required String message,
    required bool historyCleanupPerformed,
    required bool historyWasDisabled,
    required int? historyLimit,
    required int? historyMaxAgeDays,
    required int orphanedFilesDeleted,
  }) {
    return HistoryCleanupResult(
      status: HistoryCleanupStatus.completed,
      message: message,
      historyCleanupPerformed: historyCleanupPerformed,
      historyWasDisabled: historyWasDisabled,
      historyLimit: historyLimit,
      historyMaxAgeDays: historyMaxAgeDays,
      orphanedFilesDeleted: orphanedFilesDeleted,
    );
  }

  factory HistoryCleanupResult.failed({
    required String message,
    required String errorMessage,
  }) {
    return HistoryCleanupResult(
      status: HistoryCleanupStatus.failed,
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

/// Сервис ядра для очистки истории и обслуживания целостности данных хранилища.
class HistoryCleanupService {
  static const String _logTag = 'HistoryCleanupService';
  static const int _defaultCleanupIntervalDays = 7;
  static const int _defaultHistoryLimit = 100;
  static const int _defaultHistoryMaxAgeDays = 30;
  static const int _disabledHistoryValue = 0;

  final StoreSettingsDao _settingsDao;
  final FileStorageService _fileStorageService;

  HistoryCleanupService(this._settingsDao, this._fileStorageService);

  /// Проверить необходимость и выполнить очистку истории и сиротских файлов.
  /// 
  /// [ignoreInterval] - если true, проверка интервала пропускается.
  Future<HistoryCleanupResult> performCleanup({bool ignoreInterval = false}) async {
    try {
      if (!ignoreInterval) {
        final lastCleanupStr = await _settingsDao.getString(
          StoreSettingsKey.historyLastCleanupTimestamp,
        );
        final intervalDays = await _settingsDao.getInt(
          StoreSettingsKey.historyCleanupIntervalDays,
        ) ?? _defaultCleanupIntervalDays;

        if (lastCleanupStr != null) {
          final lastCleanup = DateTime.tryParse(lastCleanupStr);
          if (lastCleanup != null) {
            final diff = DateTime.now().difference(lastCleanup);
            if (diff.inDays < intervalDays) {
              final message =
                  'Skip cleanup: interval ($intervalDays days) not reached yet (last cleanup: $lastCleanup).';
              logInfo(message, tag: _logTag);
              return HistoryCleanupResult.skippedByInterval(
                message: message,
                intervalDays: intervalDays,
                lastCleanup: lastCleanup,
              );
            }
          }
        }
      }

      logInfo('Starting history and orphaned files cleanup...', tag: _logTag);

      var historyCleanupPerformed = false;
      var historyWasDisabled = false;
      int? historyLimit;
      int? historyMaxAgeDays;

      // 1. Очистка истории в БД
      final isHistoryEnabled = await _settingsDao.getBool(
        StoreSettingsKey.historyEnabled,
      ) ?? true;

      if (isHistoryEnabled) {
        historyLimit = await _settingsDao.getInt(
          StoreSettingsKey.historyLimit,
        ) ?? _defaultHistoryLimit;
        
        historyMaxAgeDays = await _settingsDao.getInt(
          StoreSettingsKey.historyMaxAgeDays,
        ) ?? _defaultHistoryMaxAgeDays;

        await _settingsDao.cleanupHistory(
          maxAgeDays: historyMaxAgeDays,
          maxRecordsPerItem: historyLimit,
        );
        historyCleanupPerformed = true;
        logInfo(
          'History cleanup completed. (limit: $historyLimit, max_age: $historyMaxAgeDays days)',
          tag: _logTag,
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
        logInfo('History disabled. All history records cleared.', tag: _logTag);
      }

      // 2. Очистка файлов-сирот (core maintenance task)
      final deletedFilesCount = await _fileStorageService
          .cleanupOrphanedFiles();
      logInfo(
        'Orphaned files cleanup completed. Deleted $deletedFilesCount files.',
        tag: _logTag,
      );

      // Обновляем метку времени последней очистки
      await _settingsDao.setString(
        StoreSettingsKey.historyLastCleanupTimestamp,
        DateTime.now().toIso8601String(),
      );

      logInfo('Cleanup finished successfully.', tag: _logTag);

      return HistoryCleanupResult.completed(
        message: 'Cleanup finished successfully.',
        historyCleanupPerformed: historyCleanupPerformed,
        historyWasDisabled: historyWasDisabled,
        historyLimit: historyLimit,
        historyMaxAgeDays: historyMaxAgeDays,
        orphanedFilesDeleted: deletedFilesCount,
      );
    } catch (e, s) {
      logError('Error during cleanup: $e', stackTrace: s, tag: _logTag);

      return HistoryCleanupResult.failed(
        message: 'Cleanup failed.',
        errorMessage: e.toString(),
      );
    }
  }
}
