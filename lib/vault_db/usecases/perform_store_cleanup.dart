import 'package:hoplixi/vault_db/core/daos/base/base.dart';
import 'package:hoplixi/vault_db/core/services/history/history_cleanup_service.dart';
import 'package:hoplixi/vault_db/services/other/file_storage_service.dart';

enum StoreCleanupStatus { completed, skippedByInterval, failed }

class StoreCleanupResult {
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

  factory StoreCleanupResult.fromCore(HistoryCleanupResult result) {
    return StoreCleanupResult(
      status: StoreCleanupStatus.values.byName(result.status.name),
      message: result.message,
      historyCleanupPerformed: result.historyCleanupPerformed,
      historyWasDisabled: result.historyWasDisabled,
      historyLimit: result.historyLimit,
      historyMaxAgeDays: result.historyMaxAgeDays,
      orphanedFilesDeleted: result.orphanedFilesDeleted,
      errorMessage: result.errorMessage,
    );
  }
}

/// Use case для глобальной очистки хранилища (базы данных и файлов).
/// Делегирует системную логику в HistoryCleanupService.
class PerformStoreCleanup {
  PerformStoreCleanup({
    required StoreSettingsDao settingsDao,
    required FileStorageService fileStorageService,
  }) : _historyCleanupService = HistoryCleanupService(
         settingsDao,
         fileStorageService,
       );

  final HistoryCleanupService _historyCleanupService;

  /// Выполнить полную очистку хранилища.
  Future<StoreCleanupResult> call({bool ignoreInterval = false}) async {
    final result = await _historyCleanupService.performCleanup(
      ignoreInterval: ignoreInterval,
    );
    return StoreCleanupResult.fromCore(result);
  }
}
