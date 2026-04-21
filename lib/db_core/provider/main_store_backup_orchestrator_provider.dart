import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/db_core/main_store_manager.dart';
import 'package:hoplixi/db_core/models/db_errors.dart';
import 'package:hoplixi/db_core/models/db_state.dart';
import 'package:hoplixi/db_core/models/dto/main_store_dto.dart';
import 'package:hoplixi/db_core/provider/main_store_backup_controller.dart';
import 'package:hoplixi/db_core/provider/main_store_provider.dart';
import 'package:hoplixi/db_core/provider/main_store_runtime_provider.dart';
import 'package:hoplixi/db_core/services/store_manifest_service.dart';

final mainStoreBackupOrchestratorProvider =
    Provider<MainStoreBackupOrchestrator>(
      (ref) => MainStoreBackupOrchestrator(
        ref: ref,
        backupController: ref.read(mainStoreBackupControllerProvider),
      ),
    );

class MainStoreBackupOrchestrator {
  MainStoreBackupOrchestrator({
    required Ref ref,
    required MainStoreBackupController backupController,
  }) : _ref = ref,
       _backupController = backupController;

  static const String _logTag = 'MainStoreBackupOrchestrator';

  final Ref _ref;
  final MainStoreBackupController _backupController;

  MainStoreManager? _managerCache;
  MainStoreRuntime? _runtimeCache;

  bool get isPeriodicBackupActive => _backupController.isPeriodicBackupActive;

  Future<BackupResult?> createBackup({
    BackupScope scope = BackupScope.full,
    String? outputDirPath,
    bool periodic = false,
    int maxBackupsPerStore = 10,
  }) async {
    final runtime = await _readRuntime();

    return _backupController.createBackup(
      state: _readCurrentState(),
      manager: await _readManager(),
      runtime: runtime,
      scope: scope,
      outputDirPath: outputDirPath,
      periodic: periodic,
      maxBackupsPerStore: maxBackupsPerStore,
      logTag: _logTag,
    );
  }

  Future<void> startPeriodicBackup({
    required Duration interval,
    BackupScope scope = BackupScope.full,
    String? outputDirPath,
    bool runImmediately = false,
    int maxBackupsPerStore = 10,
  }) async {
    final manager = await _readManager();
    final runtime = await _readRuntime();

    _backupController.startPeriodicBackup(
      interval: interval,
      scope: scope,
      outputDirPath: outputDirPath,
      runImmediately: runImmediately,
      maxBackupsPerStore: maxBackupsPerStore,
      readState: _readCurrentState,
      readManager: () => manager,
      readRuntime: () => runtime,
      logTag: _logTag,
    );
  }

  void stopPeriodicBackup() {
    _backupController.stopPeriodicBackup(logTag: _logTag);
  }

  Future<bool> backupAndMigrateStore(
    OpenStoreDto dto, {
    String? outputDirPath,
    int maxBackupsPerStore = 10,
  }) async {
    _ref.read(mainStoreProvider.notifier).markOpeningStarted(path: dto.path);

    try {
      logInfo(
        'Creating backup and migrating store at: ${dto.path}',
        tag: _logTag,
      );

      final runtime = await _readRuntime();
      final manager = await _readManager();
      final actualStoragePath = await manager.resolveStoragePath(dto.path);

      final manifest = await StoreManifestService.readFrom(actualStoragePath);
      final state = await _ref.read(mainStoreProvider.future);
      final storeName = manifest?.storeName.trim().isNotEmpty == true
          ? manifest!.storeName
          : state.name ?? 'store';

      final backupData = await runtime.backupService.createBackup(
        storeDirPath: actualStoragePath,
        storeName: storeName,
        includeDatabase: true,
        includeEncryptedFiles: true,
        attachmentsPath: runtime.maintenanceService.getAttachmentsPath(
          actualStoragePath,
        ),
        outputDirPath: outputDirPath,
        periodic: false,
        maxBackupsPerStore: maxBackupsPerStore,
      );

      logInfo(
        'Backup created before migration: ${backupData.backupPath}',
        tag: _logTag,
      );

      return _ref.read(mainStoreProvider.notifier).openStoreWithMigration(dto);
    } catch (error, stackTrace) {
      logError(
        'Failed to backup and migrate store: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      final dbError = DatabaseError.archiveFailed(
        message: 'Не удалось создать backup перед миграцией: $error',
        timestamp: DateTime.now(),
        stackTrace: stackTrace,
      );
      _ref.read(mainStoreProvider.notifier).setOpenFailure(dbError);
      return false;
    }
  }

  DatabaseState _readCurrentState() {
    final asyncState = _ref.read(mainStoreProvider);
    return asyncState.value ?? const DatabaseState(status: DatabaseStatus.idle);
  }

  Future<MainStoreRuntime> _readRuntime() async {
    final cached = _runtimeCache;
    if (cached != null) {
      return cached;
    }

    final runtime = await _ref.read(mainStoreRuntimeProvider.future);
    _runtimeCache = runtime;
    return runtime;
  }

  Future<MainStoreManager> _readManager() async {
    final cached = _managerCache;
    if (cached != null) {
      return cached;
    }

    final manager = await _ref.read(mainStoreManagerRuntimeProvider.future);
    _managerCache = manager;
    return manager;
  }
}
