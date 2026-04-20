import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hoplixi/core/app_prefs/settings_prefs.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/db_core/main_store.dart';
import 'package:hoplixi/db_core/main_store_manager.dart';
import 'package:hoplixi/db_core/models/db_errors.dart';
import 'package:hoplixi/db_core/models/db_state.dart';
import 'package:hoplixi/db_core/models/dto/main_store_dto.dart';
import 'package:hoplixi/db_core/provider/db_history_provider.dart';
import 'package:hoplixi/db_core/services/db_key_derivation_service.dart';
import 'package:hoplixi/db_core/services/main_store_backup_service.dart';
import 'package:hoplixi/db_core/services/main_store_maintenance_service.dart';
import 'package:hoplixi/db_core/services/store_manifest_service.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_exception.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/snapshot_sync_services_provider.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:typed_prefs/typed_prefs.dart';

part 'main_store_provider_backup.dart';
part 'main_store_provider_lifecycle.dart';
part 'main_store_provider_snapshot_sync.dart';
part 'main_store_provider_storage.dart';

enum BackupScope { databaseOnly, encryptedFilesOnly, full }

class BackupResult {
  final String backupPath;
  final BackupScope scope;
  final DateTime createdAt;
  final bool periodic;

  const BackupResult({
    required this.backupPath,
    required this.scope,
    required this.createdAt,
    required this.periodic,
  });
}

final _mainStoreManagerProvider = FutureProvider<MainStoreManager>((ref) async {
  final dbHistoryService = await ref.read(dbHistoryProvider.future);
  final keyService = DbKeyDerivationService(getIt<FlutterSecureStorage>());
  final manager = MainStoreManager(dbHistoryService, keyService);

  ref.onDispose(() {
    logInfo(
      'Освобождение ресурсов databaseManagerProvider',
      tag: 'DatabaseProviders',
    );
  });

  return manager;
});

final mainStoreProvider =
    AsyncNotifierProvider<MainStoreAsyncNotifier, DatabaseState>(
      MainStoreAsyncNotifier.new,
    );

final mainStoreOpeningOverlayProvider =
    NotifierProvider<MainStoreOpeningOverlayNotifier, bool>(
      MainStoreOpeningOverlayNotifier.new,
    );

class MainStoreOpeningOverlayNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void show() => state = true;

  void hide() => state = false;
}

final mainStoreStateProvider = FutureProvider<DatabaseState>((ref) async {
  return ref.watch(mainStoreProvider.future);
});

final mainStoreManagerProvider = FutureProvider<MainStoreManager?>((ref) async {
  final asyncState = await ref.watch(mainStoreProvider.future);

  return asyncState.isOpen
      ? ref.read(mainStoreProvider.notifier).currentMainStoreManager
      : null;
});

final dataUpdateStreamProvider = Provider<Stream<void>>((ref) {
  final managerAsync = ref.watch(mainStoreManagerProvider);

  return managerAsync.maybeWhen(
    data: (manager) {
      if (manager != null && manager.currentStore != null) {
        return manager.currentStore!.watchDataChanged().skip(1);
      }
      return const Stream.empty();
    },
    orElse: () => const Stream.empty(),
  );
});

class MainStoreAsyncNotifier extends AsyncNotifier<DatabaseState> {
  static const String _logTag = 'MainStoreAsyncNotifier';
  static const Duration _errorResetDelay = Duration(seconds: 10);

  late final MainStoreManager _manager;
  Timer? _errorResetTimer;
  Timer? _periodicBackupTimer;
  Duration? _periodicBackupInterval;
  BackupScope _periodicBackupScope = BackupScope.full;
  String? _periodicBackupOutputDirPath;
  int _periodicBackupMaxPerStore = 10;
  DateTime? _openedStoreModifiedAt;
  bool _forceSnapshotUploadOnClose = false;
  bool _pendingSnapshotUploadPromptOnClose = false;
  Completer<bool>? _closeStoreUploadDecision;
  Completer<void>? _operationLock;
  final MainStoreBackupService _backupService = MainStoreBackupService();
  final MainStoreMaintenanceService _maintenanceService =
      MainStoreMaintenanceService();

  DatabaseState get _currentState {
    return state.value ?? const DatabaseState(status: DatabaseStatus.idle);
  }

  void _setState(DatabaseState newState) {
    state = AsyncValue.data(newState);
  }

  void _setErrorState(DatabaseState errorState) {
    _cancelErrorResetTimer();
    _setState(errorState);
    _scheduleErrorReset();
  }

  void _scheduleErrorReset() {
    _errorResetTimer = Timer(_errorResetDelay, () {
      if (_currentState.hasError &&
          _currentState.status == DatabaseStatus.error) {
        logInfo('Автоматический сброс состояния ошибки до idle', tag: _logTag);
        _setState(const DatabaseState(status: DatabaseStatus.idle));
      }
    });
  }

  void _cancelErrorResetTimer() {
    _errorResetTimer?.cancel();
    _errorResetTimer = null;
  }

  Future<void> _acquireLock() async {
    while (_operationLock != null) {
      logInfo('Ожидание завершения предыдущей операции...', tag: _logTag);
      await _operationLock!.future;
    }
    _operationLock = Completer<void>();
  }

  void _releaseLock() {
    _operationLock?.complete();
    _operationLock = null;
  }

  Ref get _ref => ref;

  @override
  Future<DatabaseState> build() async {
    logInfo('MainStoreAsyncNotifier initialized', tag: _logTag);
    _manager = await ref.read(_mainStoreManagerProvider.future);

    ref.onDispose(() {
      _periodicBackupTimer?.cancel();
      _periodicBackupTimer = null;
      _resetSnapshotCloseTracking();
    });

    return const DatabaseState(status: DatabaseStatus.idle);
  }

  Future<BackupResult?> createBackup({
    BackupScope scope = BackupScope.full,
    String? outputDirPath,
    bool periodic = false,
    int maxBackupsPerStore = 10,
  }) => _createBackupImpl(
    this,
    scope: scope,
    outputDirPath: outputDirPath,
    periodic: periodic,
    maxBackupsPerStore: maxBackupsPerStore,
  );

  void startPeriodicBackup({
    required Duration interval,
    BackupScope scope = BackupScope.full,
    String? outputDirPath,
    bool runImmediately = false,
    int maxBackupsPerStore = 10,
  }) => _startPeriodicBackupImpl(
    this,
    interval: interval,
    scope: scope,
    outputDirPath: outputDirPath,
    runImmediately: runImmediately,
    maxBackupsPerStore: maxBackupsPerStore,
  );

  Future<void> _runPeriodicBackupTick() => _runPeriodicBackupTickImpl(this);

  void stopPeriodicBackup() => _stopPeriodicBackupImpl(this);

  bool get isPeriodicBackupActive => _periodicBackupTimer != null;

  Future<bool> createStore(CreateStoreDto dto) => _createStoreImpl(this, dto);

  Future<bool> openStore(OpenStoreDto dto) => _openStoreImpl(this, dto);

  Future<bool> backupAndMigrateStore(
    OpenStoreDto dto, {
    String? outputDirPath,
    int maxBackupsPerStore = 10,
  }) => _backupAndMigrateStoreImpl(
    this,
    dto,
    outputDirPath: outputDirPath,
    maxBackupsPerStore: maxBackupsPerStore,
  );

  Future<bool> closeStore() => _closeStoreImpl(this);

  Future<void> lockStore({bool skipSnapshotSync = false}) =>
      _lockStoreImpl(this, skipSnapshotSync: skipSnapshotSync);

  void resetState() => _resetStateImpl(this);

  Future<void> _runStartupCleanup() => _runStartupCleanupImpl(this);

  Future<void> _tryUploadSnapshotBeforeClose({
    FutureOr<void> Function()? onCloseFlowRequired,
  }) => _tryUploadSnapshotBeforeCloseImpl(
    this,
    onCloseFlowRequired: onCloseFlowRequired,
  );

  DatabaseError _buildCloseSyncFailure(
    Object error, {
    required StackTrace stackTrace,
  }) => _buildCloseSyncFailureImpl(this, error, stackTrace: stackTrace);

  String _formatCloseSyncFailureMessage(Object error) =>
      _formatCloseSyncFailureMessageImpl(error);

  Future<bool> _promptCloseStoreUploadDecision(
    StoreSyncStatus status, {
    FutureOr<void> Function()? onCloseFlowRequired,
  }) => _promptCloseStoreUploadDecisionImpl(
    this,
    status,
    onCloseFlowRequired: onCloseFlowRequired,
  );

  void resolveCloseStoreUploadDecision(bool shouldUpload) =>
      _resolveCloseStoreUploadDecisionImpl(this, shouldUpload);

  void markSnapshotUploadOnCloseRequired() =>
      _markSnapshotUploadOnCloseRequiredImpl(this);

  void syncPendingSnapshotUploadPrompt({
    required String? storeUuid,
    required bool hasBinding,
    required StoreVersionCompareResult? compareResult,
  }) => _syncPendingSnapshotUploadPromptImpl(
    this,
    storeUuid: storeUuid,
    hasBinding: hasBinding,
    compareResult: compareResult,
  );

  Future<bool> unlockStore(String password) => _unlockStoreImpl(this, password);

  Future<bool> updateStore(UpdateStoreDto dto) => _updateStoreImpl(this, dto);

  Future<bool> deleteStore(String path, {bool deleteFromDisk = true}) =>
      _deleteStoreImpl(this, path, deleteFromDisk: deleteFromDisk);

  Future<bool> deleteStoreFromDisk(String path) =>
      _deleteStoreFromDiskImpl(this, path);

  Future<String?> getAttachmentsPath() => _getAttachmentsPathImpl(this);

  Future<String?> getDecryptedAttachmentsPath() =>
      _getDecryptedAttachmentsPathImpl(this);

  Future<String?> createSubfolder(String folderName) =>
      _createSubfolderImpl(this, folderName);

  void clearError() => _clearErrorImpl(this);

  bool _handleOpenStoreSuccess(StoreInfoDto storeInfo) =>
      _handleOpenStoreSuccessImpl(this, storeInfo);

  void _handleOpenStoreFailure(DatabaseError error) =>
      _handleOpenStoreFailureImpl(this, error);

  DatabaseState _buildOpenFailureState(DatabaseError error) =>
      _buildOpenFailureStateImpl(this, error);

  void _startSnapshotCloseTracking({
    required DateTime initialModifiedAt,
    bool forceUpload = false,
  }) => _startSnapshotCloseTrackingImpl(
    this,
    initialModifiedAt: initialModifiedAt,
    forceUpload: forceUpload,
  );

  void _resetSnapshotCloseTracking() => _resetSnapshotCloseTrackingImpl(this);

  MainStoreManager? get currentMainStoreManager => _manager;

  MainStore get currentDatabase {
    final db = _manager.currentStore;
    if (db == null) {
      logError(
        'Попытка доступа к базе данных, когда она не открыта',
        tag: 'DatabaseAsyncNotifier',
        data: {'state': state.toString()},
      );
      throw DatabaseError.unknown(
        message: 'Database must be opened before accessing it',
        stackTrace: StackTrace.current,
      );
    }
    return db;
  }
}
