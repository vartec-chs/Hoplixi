import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/old/main_store_manager.dart';
import 'package:hoplixi/main_db/old/models/db_state.dart';
import 'package:hoplixi/main_db/old/provider/main_store_backup_models.dart';
import 'package:hoplixi/main_db/old/provider/main_store_runtime_provider.dart';
import 'package:hoplixi/main_db/old/provider/main_store_storage_controller.dart';
import 'package:hoplixi/main_db/old/services/main_store_backup_service.dart';
import 'package:hoplixi/main_db/old/services/main_store_maintenance_service.dart';

final mainStoreBackupControllerProvider = Provider<MainStoreBackupController>((
  ref,
) {
  final controller = MainStoreBackupController(
    backupService: ref.read(mainStoreBackupServiceProvider),
    storageController: ref.read(mainStoreStorageControllerProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

class MainStoreBackupController {
  MainStoreBackupController({
    required MainStoreBackupService backupService,
    required MainStoreStorageController storageController,
  }) : _backupService = backupService,
       _storageController = storageController;

  final MainStoreBackupService _backupService;
  final MainStoreStorageController _storageController;

  Timer? _periodicBackupTimer;
  Duration? _periodicBackupInterval;
  BackupScope _periodicBackupScope = BackupScope.full;
  String? _periodicBackupOutputDirPath;
  int _periodicBackupMaxPerStore = 10;

  bool get isPeriodicBackupActive => _periodicBackupTimer != null;

  Future<BackupResult?> createBackup({
    required DatabaseState state,
    required MainStoreManager manager,
    required MainStoreMaintenanceService maintenanceService,
    required BackupScope scope,
    required bool periodic,
    required int maxBackupsPerStore,
    required String logTag,
    String? outputDirPath,
  }) async {
    try {
      if (!state.isOpen) {
        logWarning('Store is not open, cannot create backup', tag: logTag);
        return null;
      }

      final storeDirPath = state.path ?? manager.currentStorePath;
      if (storeDirPath == null || storeDirPath.isEmpty) {
        logError('Store path is null, backup aborted', tag: logTag);
        return null;
      }

      final attachmentsPath =
          scope == BackupScope.encryptedFilesOnly || scope == BackupScope.full
          ? await _storageController.getAttachmentsPath(
              state: state,
              manager: manager,
              maintenanceService: maintenanceService,
              logTag: logTag,
            )
          : null;

      final backupData = await _backupService.createBackup(
        storeDirPath: storeDirPath,
        storeName: state.name ?? 'store',
        includeDatabase:
            scope == BackupScope.databaseOnly || scope == BackupScope.full,
        includeEncryptedFiles:
            scope == BackupScope.encryptedFilesOnly ||
            scope == BackupScope.full,
        attachmentsPath: attachmentsPath,
        outputDirPath: outputDirPath,
        periodic: periodic,
        maxBackupsPerStore: maxBackupsPerStore,
      );

      logInfo(
        'Backup created successfully: ${backupData.backupPath} (scope: ${scope.name})',
        tag: logTag,
      );

      return BackupResult(
        backupPath: backupData.backupPath,
        scope: scope,
        createdAt: backupData.createdAt,
        periodic: periodic,
      );
    } catch (error, stackTrace) {
      logError(
        'Failed to create backup: $error',
        stackTrace: stackTrace,
        tag: logTag,
      );
      return null;
    }
  }

  void startPeriodicBackup({
    required Duration interval,
    required BackupScope scope,
    required bool runImmediately,
    required int maxBackupsPerStore,
    required DatabaseState Function() readState,
    required MainStoreManager Function() readManager,
    required MainStoreMaintenanceService Function() readMaintenanceService,
    required String logTag,
    String? outputDirPath,
  }) {
    if (interval.inSeconds <= 0) {
      logWarning('Invalid backup interval: $interval', tag: logTag);
      return;
    }

    stopPeriodicBackup(logTag: logTag);

    _periodicBackupInterval = interval;
    _periodicBackupScope = scope;
    _periodicBackupOutputDirPath = outputDirPath;
    _periodicBackupMaxPerStore = maxBackupsPerStore <= 0
        ? 1
        : maxBackupsPerStore;

    _periodicBackupTimer = Timer.periodic(interval, (_) {
      unawaited(
        _runPeriodicBackupTick(
          readState: readState,
          readManager: readManager,
          readMaintenanceService: readMaintenanceService,
          logTag: logTag,
        ),
      );
    });

    if (runImmediately) {
      unawaited(
        _runPeriodicBackupTick(
          readState: readState,
          readManager: readManager,
          readMaintenanceService: readMaintenanceService,
          logTag: logTag,
        ),
      );
    }

    logInfo(
      'Periodic backup started (interval: $interval, scope: ${scope.name})',
      tag: logTag,
    );
  }

  void stopPeriodicBackup({required String logTag}) {
    _periodicBackupTimer?.cancel();
    _periodicBackupTimer = null;
    _periodicBackupInterval = null;
    _periodicBackupOutputDirPath = null;

    logInfo('Periodic backup stopped', tag: logTag);
  }

  Future<void> _runPeriodicBackupTick({
    required DatabaseState Function() readState,
    required MainStoreManager Function() readManager,
    required MainStoreMaintenanceService Function() readMaintenanceService,
    required String logTag,
  }) async {
    final state = readState();
    if (!state.isOpen) {
      return;
    }

    await createBackup(
      state: state,
      manager: readManager(),
      maintenanceService: readMaintenanceService(),
      scope: _periodicBackupScope,
      outputDirPath: _periodicBackupOutputDirPath,
      periodic: true,
      maxBackupsPerStore: _periodicBackupMaxPerStore,
      logTag: logTag,
    );
  }

  void dispose() {
    _periodicBackupTimer?.cancel();
    _periodicBackupTimer = null;
  }
}
