import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/core/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_db/models/db_state.dart';
import 'package:hoplixi/main_db/models/main_store_backup_models.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';
import 'package:hoplixi/main_db/services/main_store_backup_service.dart';
import 'package:hoplixi/main_db/services/main_store_storage_service.dart';
import 'package:hoplixi/main_db/services/store_manifest_service/store_manifest_service.dart';

export 'package:hoplixi/main_db/models/main_store_backup_models.dart';

final mainStoreBackupServiceProvider = Provider<MainStoreBackupService>(
  (ref) => MainStoreBackupService(),
);

final mainStoreBackupOrchestratorProvider =
    Provider<MainStoreBackupOrchestrator>((ref) {
      final orchestrator = MainStoreBackupOrchestrator(
        ref: ref,
        backupService: ref.read(mainStoreBackupServiceProvider),
      );
      ref.onDispose(orchestrator.dispose);
      return orchestrator;
    });

class MainStoreBackupOrchestrator {
  MainStoreBackupOrchestrator({
    required Ref ref,
    required MainStoreBackupService backupService,
  }) : _ref = ref,
       _backupService = backupService;

  static const String _logTag = 'MainStoreBackupOrchestrator';

  final Ref _ref;
  final MainStoreBackupService _backupService;
  final MainStoreFileService _storageService = const MainStoreFileService();

  Timer? _periodicBackupTimer;
  BackupScope _periodicBackupScope = BackupScope.full;
  String? _periodicBackupOutputDirPath;
  int _periodicBackupMaxPerStore = 10;

  bool get isPeriodicBackupActive => _periodicBackupTimer != null;

  Future<BackupResult?> createBackup({
    BackupScope scope = BackupScope.full,
    String? outputDirPath,
    bool periodic = false,
    int maxBackupsPerStore = 10,
  }) async {
    try {
      final state = _readCurrentState();
      if (!state.isOpen) {
        logWarning('Store is not open, cannot create backup', tag: _logTag);
        return null;
      }

      final manager = await _ref.read(mainStoreManagerProvider.future);
      final storeDirPath = state.path ?? manager.currentStorePath;
      if (storeDirPath == null || storeDirPath.isEmpty) {
        logError('Store path is null, backup aborted', tag: _logTag);
        return null;
      }

      final includeEncryptedFiles =
          scope == BackupScope.encryptedFilesOnly || scope == BackupScope.full;
      final backupData = await _backupService.createBackup(
        storeDirPath: storeDirPath,
        storeName: state.name ?? 'store',
        includeDatabase:
            scope == BackupScope.databaseOnly || scope == BackupScope.full,
        includeEncryptedFiles: includeEncryptedFiles,
        attachmentsPath: includeEncryptedFiles
            ? _storageService.getAttachmentsPath(storeDirPath)
            : null,
        outputDirPath: outputDirPath,
        periodic: periodic,
        maxBackupsPerStore: maxBackupsPerStore,
      );

      logInfo(
        'Backup created successfully: ${backupData.backupPath}',
        tag: _logTag,
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
        tag: _logTag,
      );
      return null;
    }
  }

  Future<void> startPeriodicBackup({
    required Duration interval,
    BackupScope scope = BackupScope.full,
    String? outputDirPath,
    bool runImmediately = false,
    int maxBackupsPerStore = 10,
  }) async {
    if (interval.inSeconds <= 0) {
      logWarning('Invalid backup interval: $interval', tag: _logTag);
      return;
    }

    stopPeriodicBackup();

    _periodicBackupScope = scope;
    _periodicBackupOutputDirPath = outputDirPath;
    _periodicBackupMaxPerStore = maxBackupsPerStore <= 0
        ? 1
        : maxBackupsPerStore;

    _periodicBackupTimer = Timer.periodic(interval, (_) {
      unawaited(_runPeriodicBackupTick());
    });

    if (runImmediately) {
      unawaited(_runPeriodicBackupTick());
    }

    logInfo(
      'Periodic backup started (interval: $interval, scope: ${scope.name})',
      tag: _logTag,
    );
  }

  void stopPeriodicBackup() {
    _periodicBackupTimer?.cancel();
    _periodicBackupTimer = null;
    _periodicBackupOutputDirPath = null;

    logInfo('Periodic backup stopped', tag: _logTag);
  }

  Future<bool> backupAndMigrateStore(
    OpenStoreDto dto, {
    String? outputDirPath,
    int maxBackupsPerStore = 10,
  }) async {
    _ref.read(mainStoreProvider.notifier).markOpeningStarted(path: dto.path);

    try {
      final actualStoragePath = await _storageService.resolveExistingStoragePath(
        dto.path,
      );
      final manifest = await StoreManifestService.readFrom(actualStoragePath);
      final state = await _ref.read(mainStoreProvider.future);
      final storeName = manifest?.storeName.trim().isNotEmpty == true
          ? manifest!.storeName
          : state.name ?? 'store';

      await _backupService.createBackup(
        storeDirPath: actualStoragePath,
        storeName: storeName,
        includeDatabase: true,
        includeEncryptedFiles: true,
        attachmentsPath: _storageService.getAttachmentsPath(actualStoragePath),
        outputDirPath: outputDirPath,
        periodic: false,
        maxBackupsPerStore: maxBackupsPerStore,
      );

      return _ref.read(mainStoreProvider.notifier).openStoreWithMigration(dto);
    } catch (error, stackTrace) {
      logError(
        'Failed to backup and migrate store: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      _ref.read(mainStoreProvider.notifier).setOpenFailure(
        AppError.mainDatabase(
          code: MainDatabaseErrorCode.unknown,
          message: 'Не удалось создать backup перед миграцией: $error',
          cause: error,
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
      return false;
    }
  }

  void dispose() {
    _periodicBackupTimer?.cancel();
    _periodicBackupTimer = null;
  }

  DatabaseState _readCurrentState() {
    return _ref.read(mainStoreProvider).value ??
        const DatabaseState(status: DatabaseStatus.idle);
  }

  Future<void> _runPeriodicBackupTick() async {
    if (!_readCurrentState().isOpen) {
      return;
    }

    await createBackup(
      scope: _periodicBackupScope,
      outputDirPath: _periodicBackupOutputDirPath,
      periodic: true,
      maxBackupsPerStore: _periodicBackupMaxPerStore,
    );
  }
}
