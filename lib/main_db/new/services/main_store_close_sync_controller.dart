import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_prefs/settings_prefs.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_exception.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/snapshot_sync_services_provider.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';
import 'package:hoplixi/main_db/core/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_db/new/providers/close_sync_tracking_provider.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:result_dart/result_dart.dart';
import 'package:typed_prefs/typed_prefs.dart';

final mainStoreCloseSyncServiceProvider = Provider<MainStoreCloseSyncService>(
  (ref) => MainStoreCloseSyncService(ref),
);

final mainStoreCloseSyncProvider =
    AsyncNotifierProvider<MainStoreCloseSyncNotifier, MainStoreCloseSyncState>(
      MainStoreCloseSyncNotifier.new,
    );

enum MainStoreCloseSyncPhase {
  idle,
  checking,
  waitingForDecision,
  syncing,
  completed,
  skipped,
  failed,
}

enum MainStoreCloseSyncOutcomeType {
  noLogicalChanges,
  noBinding,
  staleTokenBinding,
  offlineAutoUpload,
  skippedByUser,
  uploaded,
  alreadySynced,
  manualResolutionRequired,
}

class MainStoreCloseSyncOutcome {
  const MainStoreCloseSyncOutcome(this.type, {this.resultType});

  final MainStoreCloseSyncOutcomeType type;
  final SnapshotSyncResultType? resultType;

  bool get completedUpload => type == MainStoreCloseSyncOutcomeType.uploaded;

  bool get clearsTracking =>
      type == MainStoreCloseSyncOutcomeType.uploaded ||
      type == MainStoreCloseSyncOutcomeType.alreadySynced;
}

class MainStoreCloseSyncState {
  const MainStoreCloseSyncState({
    this.phase = MainStoreCloseSyncPhase.idle,
    this.status,
    this.outcome,
    this.error,
  });

  final MainStoreCloseSyncPhase phase;
  final StoreSyncStatus? status;
  final MainStoreCloseSyncOutcome? outcome;
  final AppError? error;

  bool get isActive =>
      phase == MainStoreCloseSyncPhase.checking ||
      phase == MainStoreCloseSyncPhase.waitingForDecision ||
      phase == MainStoreCloseSyncPhase.syncing;

  MainStoreCloseSyncState copyWith({
    MainStoreCloseSyncPhase? phase,
    StoreSyncStatus? status,
    MainStoreCloseSyncOutcome? outcome,
    AppError? error,
    bool clearStatus = false,
    bool clearOutcome = false,
    bool clearError = false,
  }) {
    return MainStoreCloseSyncState(
      phase: phase ?? this.phase,
      status: clearStatus ? null : status ?? this.status,
      outcome: clearOutcome ? null : outcome ?? this.outcome,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class MainStoreCloseSyncNotifier
    extends AsyncNotifier<MainStoreCloseSyncState> {
  Completer<bool>? _closeStoreUploadDecision;

  MainStoreCloseSyncState get _current =>
      state.value ?? const MainStoreCloseSyncState();

  @override
  Future<MainStoreCloseSyncState> build() async {
    ref.onDispose(_completePendingDecisionAsSkipped);
    return const MainStoreCloseSyncState();
  }

  AsyncResultDart<MainStoreCloseSyncOutcome, AppError>
  tryUploadSnapshotBeforeClose({
    required StoreInfoDto storeInfo,
    required String currentStorePath,
    required String logTag,
    FutureOr<void> Function()? onCloseFlowRequired,
  }) async {
    _setState(
      const MainStoreCloseSyncState(phase: MainStoreCloseSyncPhase.checking),
    );

    final result = await ref
        .read(mainStoreCloseSyncServiceProvider)
        .tryUploadSnapshotBeforeClose(
          storeInfo: storeInfo,
          currentStorePath: currentStorePath,
          tracking: ref.read(closeSyncTrackingProvider),
          logTag: logTag,
          onCloseFlowRequired: onCloseFlowRequired,
          requestUploadDecision: (status) => _promptUploadDecision(
            status,
            logTag: logTag,
            onCloseFlowRequired: onCloseFlowRequired,
          ),
          onCloseSyncStatusChanged: (nextStatus) {
            _setCloseStoreSyncStatus(
              nextStatus,
              phase: nextStatus?.isSyncInProgress ?? false
                  ? MainStoreCloseSyncPhase.syncing
                  : MainStoreCloseSyncPhase.waitingForDecision,
            );
          },
        );

    result.fold(
      (outcome) {
        if (outcome.clearsTracking) {
          ref.read(closeSyncTrackingProvider.notifier).markUploadedOrNotNeeded();
        }
        _setState(
          _current.copyWith(
            phase: outcome.completedUpload
                ? MainStoreCloseSyncPhase.completed
                : MainStoreCloseSyncPhase.skipped,
            outcome: outcome,
            clearError: true,
          ),
        );
      },
      (error) {
        ref.read(closeSyncTrackingProvider.notifier).markUploadRequired();
        _setState(
          _current.copyWith(
            phase: MainStoreCloseSyncPhase.failed,
            error: error,
          ),
        );
      },
    );

    return result;
  }

  Future<bool> shouldAllowCloseWithoutSyncFailure(AppError error) {
    return ref
        .read(mainStoreCloseSyncServiceProvider)
        .shouldAllowCloseWithoutSyncFailure(error);
  }

  void resolveUploadDecision(bool shouldUpload) {
    final decision = _closeStoreUploadDecision;
    if (decision == null || decision.isCompleted) {
      return;
    }
    decision.complete(shouldUpload);
  }

  void resolveCloseStoreUploadDecision(bool shouldUpload) {
    resolveUploadDecision(shouldUpload);
  }

  void markSnapshotUploadOnCloseRequired() {
    ref.read(closeSyncTrackingProvider.notifier).markUploadRequired();
  }

  void syncPendingSnapshotUploadPrompt({
    required bool isStoreOpen,
    required String? currentStorePath,
    required String? storeUuid,
    required String? statusStorePath,
    required bool hasBinding,
    required StoreVersionCompareResult? compareResult,
  }) {
    final isCurrentStore =
        storeUuid != null &&
        currentStorePath != null &&
        statusStorePath != null &&
        isStoreOpen &&
        currentStorePath == statusStorePath;

    ref
        .read(closeSyncTrackingProvider.notifier)
        .setPendingPrompt(
          isCurrentStore &&
              hasBinding &&
              (compareResult == StoreVersionCompareResult.remoteMissing ||
                  compareResult == StoreVersionCompareResult.localNewer),
        );
  }

  void reset() {
    _completePendingDecisionAsSkipped();
    ref.read(closeStoreSyncStatusProvider.notifier).clear();
    _setState(const MainStoreCloseSyncState());
  }

  void clearPublishedStatus() {
    ref.read(closeStoreSyncStatusProvider.notifier).clear();
    _setState(_current.copyWith(clearStatus: true));
  }

  Future<bool> _promptUploadDecision(
    StoreSyncStatus status, {
    required String logTag,
    FutureOr<void> Function()? onCloseFlowRequired,
  }) async {
    final existing = _closeStoreUploadDecision;
    if (existing != null) {
      return existing.future;
    }

    final shouldAutoUpload = await ref
        .read(mainStoreCloseSyncServiceProvider)
        .isAutoUploadEnabled();
    if (shouldAutoUpload) {
      if (onCloseFlowRequired != null) {
        _setCloseStoreSyncStatus(
          status.copyWith(
            clearSyncProgress: true,
            isSyncInProgress: true,
            lastResultType: SnapshotSyncResultType.idle,
          ),
          phase: MainStoreCloseSyncPhase.syncing,
        );
      }
      logInfo(
        'Skipping close-store snapshot upload prompt because auto-upload setting is enabled.',
        tag: logTag,
        data: <String, dynamic>{
          'storeUuid': status.storeUuid,
          'compareResult': status.compareResult.name,
        },
      );
      return true;
    }

    await onCloseFlowRequired?.call();
    ref.read(closeSyncTrackingProvider.notifier).setPendingPrompt(true);
    _setCloseStoreSyncStatus(
      status.copyWith(
        clearSyncProgress: true,
        isSyncInProgress: false,
        lastResultType: SnapshotSyncResultType.idle,
      ),
      phase: MainStoreCloseSyncPhase.waitingForDecision,
    );

    final completer = Completer<bool>();
    _closeStoreUploadDecision = completer;
    return completer.future.whenComplete(() {
      if (identical(_closeStoreUploadDecision, completer)) {
        _closeStoreUploadDecision = null;
      }
    });
  }

  void _setCloseStoreSyncStatus(
    StoreSyncStatus? nextStatus, {
    required MainStoreCloseSyncPhase phase,
  }) {
    ref.read(closeStoreSyncStatusProvider.notifier).setStatus(nextStatus);
    _setState(
      _current.copyWith(
        phase: phase,
        status: nextStatus,
        clearStatus: nextStatus == null,
        clearError: true,
      ),
    );
  }

  void _setState(MainStoreCloseSyncState nextState) {
    state = AsyncData(nextState);
  }

  void _completePendingDecisionAsSkipped() {
    final decision = _closeStoreUploadDecision;
    if (decision != null && !decision.isCompleted) {
      decision.complete(false);
    }
    _closeStoreUploadDecision = null;
  }
}

class MainStoreCloseSyncService {
  const MainStoreCloseSyncService(this._ref);

  final Ref _ref;

  AsyncResultDart<MainStoreCloseSyncOutcome, AppError>
  tryUploadSnapshotBeforeClose({
    required StoreInfoDto storeInfo,
    required String currentStorePath,
    required CloseSyncTrackingState tracking,
    required String logTag,
    required Future<bool> Function(StoreSyncStatus status) requestUploadDecision,
    required void Function(StoreSyncStatus? status) onCloseSyncStatusChanged,
    FutureOr<void> Function()? onCloseFlowRequired,
  }) async {
    final storePath = currentStorePath;
    final currentModifiedAt = storeInfo.modifiedAt.toUtc();

    if (!tracking.hasLogicalChanges(currentModifiedAt)) {
      logDebug(
        'Skipping snapshot sync before close because StoreMeta.modifiedAt did not change during the current session.',
        tag: logTag,
        data: <String, dynamic>{
          'storePath': storePath,
          'openedStoreModifiedAt': tracking.openedModifiedAt?.toIso8601String(),
          'currentStoreModifiedAt': currentModifiedAt.toIso8601String(),
          'pendingSnapshotUploadPromptOnClose': tracking.pendingPrompt,
        },
      );
      return const Success(
        MainStoreCloseSyncOutcome(
          MainStoreCloseSyncOutcomeType.noLogicalChanges,
        ),
      );
    }

    try {
      final cachedStatus = _getReusableCloseStoreSyncStatus(
        storePath: storePath,
        storeInfo: storeInfo,
      );

      final binding =
          cachedStatus?.binding ??
          await _ref
              .read(storeSyncBindingServiceProvider)
              .getByStoreUuid(storeInfo.id);
      if (binding == null) {
        return const Success(
          MainStoreCloseSyncOutcome(MainStoreCloseSyncOutcomeType.noBinding),
        );
      }

      final token =
          cachedStatus?.token ??
          await _ref
              .read(authTokensProvider.notifier)
              .getTokenById(binding.tokenId);
      if (token == null) {
        logWarning(
          'Skipping snapshot sync before close because token binding is stale.',
          tag: logTag,
          data: <String, dynamic>{
            'storeUuid': storeInfo.id,
            'tokenId': binding.tokenId,
          },
        );
        return const Success(
          MainStoreCloseSyncOutcome(
            MainStoreCloseSyncOutcomeType.staleTokenBinding,
          ),
        );
      }

      final autoUploadEnabled = await isAutoUploadEnabled();
      if (autoUploadEnabled) {
        final hasInternetAccess = await _hasInternetAccessForCloseSync();
        if (!hasInternetAccess) {
          logWarning(
            'Skipping snapshot upload before close because device has no internet access and auto-upload is enabled.',
            tag: logTag,
            data: <String, dynamic>{
              'storeUuid': storeInfo.id,
              'tokenId': token.id,
            },
          );
          return const Success(
            MainStoreCloseSyncOutcome(
              MainStoreCloseSyncOutcomeType.offlineAutoUpload,
            ),
          );
        }
      }

      final syncService = _ref.read(snapshotSyncServiceProvider);
      final status = cachedStatus != null
          ? await syncService.rebuildStatusWithKnownRemote(
              storePath: storePath,
              storeInfo: storeInfo,
              binding: binding,
              token: token,
              remoteManifest: cachedStatus.remoteManifest,
              persistLocalSnapshot: true,
              allowLocalRevisionBump: true,
              remoteCheckSkippedOffline: false,
            )
          : await syncService.loadStatus(
              storePath: storePath,
              storeInfo: storeInfo,
              binding: binding,
              token: token,
              persistLocalSnapshot: true,
              allowLocalRevisionBump: true,
            );

      switch (status.compareResult) {
        case StoreVersionCompareResult.remoteMissing:
        case StoreVersionCompareResult.localNewer:
          final shouldUpload = await requestUploadDecision(status);
          if (!shouldUpload) {
            onCloseSyncStatusChanged(null);
            logInfo(
              'Skipping snapshot upload before close by user choice.',
              tag: logTag,
              data: <String, dynamic>{'storeUuid': storeInfo.id},
            );
            return const Success(
              MainStoreCloseSyncOutcome(
                MainStoreCloseSyncOutcomeType.skippedByUser,
              ),
            );
          }

          await onCloseFlowRequired?.call();
          final result = await _ref
              .read(closeStoreSnapshotSyncCoordinatorProvider)
              .syncBeforeClose(
                status: status,
                storePath: storePath,
                storeInfo: storeInfo,
                binding: binding,
                token: token,
                onStatusChanged: onCloseSyncStatusChanged,
              );
          logInfo(
            'Snapshot sync before close completed.',
            tag: logTag,
            data: <String, dynamic>{
              'storeUuid': storeInfo.id,
              'resultType': result.type.name,
            },
          );
          return Success(
            MainStoreCloseSyncOutcome(
              MainStoreCloseSyncOutcomeType.uploaded,
              resultType: result.type,
            ),
          );
        case StoreVersionCompareResult.same:
          logDebug(
            'Skipping snapshot upload before close because local and remote versions match.',
            tag: logTag,
            data: <String, dynamic>{'storeUuid': storeInfo.id},
          );
          return const Success(
            MainStoreCloseSyncOutcome(
              MainStoreCloseSyncOutcomeType.alreadySynced,
            ),
          );
        case StoreVersionCompareResult.remoteNewer:
        case StoreVersionCompareResult.conflict:
        case StoreVersionCompareResult.differentStore:
          logWarning(
            'Skipping snapshot upload before close because manual resolution is required.',
            tag: logTag,
            data: <String, dynamic>{
              'storeUuid': storeInfo.id,
              'compareResult': status.compareResult.name,
            },
          );
          return const Success(
            MainStoreCloseSyncOutcome(
              MainStoreCloseSyncOutcomeType.manualResolutionRequired,
            ),
          );
      }
    } catch (error, stackTrace) {
      logError(
        'Snapshot sync before close failed: $error',
        stackTrace: stackTrace,
        tag: logTag,
      );
      return Failure(buildCloseSyncFailure(error, stackTrace: stackTrace));
    }
  }

  AppError buildCloseSyncFailure(
    Object error, {
    required StackTrace stackTrace,
  }) {
    final message = formatCloseSyncFailureMessage(error);
    return AppError.mainDatabase(
      code: MainDatabaseErrorCode.connectionFailed,
      message: message,
      data: <String, dynamic>{
        'stage': 'close_store_snapshot_sync',
        'errorType': error.runtimeType.toString(),
      },
      cause: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );
  }

  String formatCloseSyncFailureMessage(Object error) {
    if (error case CloudStorageException(:final type, :final message)) {
      return switch (type) {
        CloudStorageExceptionType.network =>
          'Не удалось отправить изменения в облако из-за проблем с интернет-соединением. Хранилище осталось открытым.',
        CloudStorageExceptionType.timeout =>
          'Не удалось отправить изменения в облако: сервер не ответил вовремя. Хранилище осталось открытым.',
        CloudStorageExceptionType.unauthorized =>
          'Не удалось отправить изменения в облако: требуется повторно подключить аккаунт синхронизации. Хранилище осталось открытым.',
        _ when message.trim().isNotEmpty =>
          'Не удалось отправить изменения в облако перед закрытием. $message Хранилище осталось открытым.',
        _ =>
          'Не удалось отправить изменения в облако перед закрытием. Хранилище осталось открытым.',
      };
    }

    if (error case CloudSyncHttpException(:final type)) {
      return switch (type) {
        CloudSyncHttpExceptionType.network =>
          'Не удалось отправить изменения в облако из-за проблем с интернет-соединением. Хранилище осталось открытым.',
        CloudSyncHttpExceptionType.timeout =>
          'Не удалось отправить изменения в облако: сервер не ответил вовремя. Хранилище осталось открытым.',
        CloudSyncHttpExceptionType.refreshFailed ||
        CloudSyncHttpExceptionType.unauthorized =>
          'Не удалось отправить изменения в облако: требуется повторно подключить аккаунт синхронизации. Хранилище осталось открытым.',
        _ =>
          'Не удалось отправить изменения в облако перед закрытием. Хранилище осталось открытым.',
      };
    }

    if (error is AppError) {
      return 'Не удалось завершить синхронизацию перед закрытием. ${error.message}';
    }

    return 'Не удалось отправить изменения в облако перед закрытием. Хранилище осталось открытым.';
  }

  Future<bool> shouldAllowCloseWithoutSyncFailure(Object error) async {
    final autoUploadEnabled = await isAutoUploadEnabled();
    if (!autoUploadEnabled) {
      return false;
    }

    final source = error is AppError && error.cause != null
        ? error.cause!
        : error;
    return switch (source) {
      CloudStorageException(:final type)
          when type == CloudStorageExceptionType.network ||
              type == CloudStorageExceptionType.timeout ||
              type == CloudStorageExceptionType.cancelled =>
        true,
      CloudSyncHttpException(:final type)
          when type == CloudSyncHttpExceptionType.network ||
              type == CloudSyncHttpExceptionType.timeout ||
              type == CloudSyncHttpExceptionType.cancelled =>
        true,
      _ => false,
    };
  }

  Future<bool> isAutoUploadEnabled() {
    return getIt<PreferencesService>().settingsPrefs
        .getAutoUploadSnapshotOnCloseEnabled();
  }

  StoreSyncStatus? _getReusableCloseStoreSyncStatus({
    required String storePath,
    required StoreInfoDto storeInfo,
  }) {
    final status = _ref.read(currentStoreSyncSnapshotProvider);
    if (status == null) {
      return null;
    }

    final hasSameStoreIdentity =
        status.isStoreOpen &&
        status.storePath == storePath &&
        status.storeUuid == storeInfo.id;
    if (!hasSameStoreIdentity) {
      return null;
    }

    if (status.binding == null || status.token == null) {
      return null;
    }

    if (status.remoteCheckSkippedOffline || status.isSyncInProgress) {
      return null;
    }

    return status;
  }

  Future<bool> _hasInternetAccessForCloseSync() async {
    try {
      return await _ref.read(internetConnectionProvider).hasInternetAccess;
    } catch (_) {
      return false;
    }
  }
}
