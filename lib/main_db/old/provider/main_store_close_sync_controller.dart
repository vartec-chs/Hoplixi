import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_prefs/settings_prefs.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/old/main_store_manager.dart';
import 'package:hoplixi/main_db/old/models/db_errors.dart';
import 'package:hoplixi/main_db/old/models/db_state.dart';
import 'package:hoplixi/main_db/core/models/dto/main_store_dto.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_exception.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/snapshot_sync_services_provider.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:typed_prefs/typed_prefs.dart';

final mainStoreCloseSyncControllerProvider =
    Provider<MainStoreCloseSyncController>((ref) {
      final controller = MainStoreCloseSyncController(ref);
      ref.onDispose(controller.dispose);
      return controller;
    });

class MainStoreCloseSyncController {
  MainStoreCloseSyncController(this._ref);

  final Ref _ref;

  DateTime? _openedStoreModifiedAt;
  bool _forceSnapshotUploadOnClose = false;
  bool _pendingSnapshotUploadPromptOnClose = false;
  Completer<bool>? _closeStoreUploadDecision;

  // 
  Future<void> tryUploadSnapshotBeforeClose({
    required MainStoreManager manager,
    required String logTag,
    FutureOr<void> Function()? onCloseFlowRequired,
  }) async {
    final storePath = manager.currentStorePath;
    if (storePath == null || storePath.isEmpty || !manager.isStoreOpen) {
      return;
    }

    final storeInfoResult = await manager.getStoreInfo();
    final storeInfo = storeInfoResult.fold(
      (info) => info,
      (error) => throw error,
    );
    final currentModifiedAt = storeInfo.modifiedAt.toUtc();
    final hasLogicalChanges =
        _forceSnapshotUploadOnClose ||
        _pendingSnapshotUploadPromptOnClose ||
        _openedStoreModifiedAt == null ||
        !_openedStoreModifiedAt!.isAtSameMomentAs(currentModifiedAt);

    if (!hasLogicalChanges) {
      logDebug(
        'Skipping snapshot sync before close because StoreMeta.modifiedAt did not change during the current session.',
        tag: logTag,
        data: <String, dynamic>{
          'storePath': storePath,
          'openedStoreModifiedAt': _openedStoreModifiedAt?.toIso8601String(),
          'currentStoreModifiedAt': currentModifiedAt.toIso8601String(),
          'pendingSnapshotUploadPromptOnClose':
              _pendingSnapshotUploadPromptOnClose,
        },
      );
      return;
    }

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
      return;
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
      return;
    }

    final autoUploadEnabled = await getIt<PreferencesService>().settingsPrefs
        .getAutoUploadSnapshotOnCloseEnabled();
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
        return;
      }
    }

    try {
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
          final shouldUpload = await promptCloseStoreUploadDecision(
            status,
            logTag: logTag,
            onCloseFlowRequired: onCloseFlowRequired,
          );
          if (!shouldUpload) {
            _ref.read(closeStoreSyncStatusProvider.notifier).clear();
            logInfo(
              'Skipping snapshot upload before close by user choice.',
              tag: logTag,
              data: <String, dynamic>{'storeUuid': storeInfo.id},
            );
            break;
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
                onStatusChanged: (nextState) {
                  _ref
                      .read(closeStoreSyncStatusProvider.notifier)
                      .setStatus(nextState);
                },
              );
          _forceSnapshotUploadOnClose = false;
          _pendingSnapshotUploadPromptOnClose = false;
          logInfo(
            'Snapshot sync before close completed.',
            tag: logTag,
            data: <String, dynamic>{
              'storeUuid': storeInfo.id,
              'resultType': result.type.name,
            },
          );
          break;
        case StoreVersionCompareResult.same:
          _forceSnapshotUploadOnClose = false;
          _pendingSnapshotUploadPromptOnClose = false;
          logDebug(
            'Skipping snapshot upload before close because local and remote versions match.',
            tag: logTag,
            data: <String, dynamic>{'storeUuid': storeInfo.id},
          );
          break;
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
          break;
      }
    } catch (error, stackTrace) {
      _forceSnapshotUploadOnClose = true;
      logError(
        'Snapshot sync before close failed: $error',
        stackTrace: stackTrace,
        tag: logTag,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  DatabaseError buildCloseSyncFailure(
    Object error, {
    required StackTrace stackTrace,
  }) {
    final message = formatCloseSyncFailureMessage(error);
    return DatabaseError.connectionFailed(
      code: 'DB_CLOSE_SYNC_FAILED',
      message: message,
      data: <String, dynamic>{
        'stage': 'close_store_snapshot_sync',
        'errorType': error.runtimeType.toString(),
      },
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

    if (error case DatabaseError(:final message)) {
      return 'Не удалось завершить синхронизацию перед закрытием. $message';
    }

    return 'Не удалось отправить изменения в облако перед закрытием. Хранилище осталось открытым.';
  }

  Future<bool> shouldAllowCloseWithoutSyncFailure(Object error) async {
    final autoUploadEnabled = await getIt<PreferencesService>().settingsPrefs
        .getAutoUploadSnapshotOnCloseEnabled();
    if (!autoUploadEnabled) {
      return false;
    }

    return switch (error) {
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

  Future<bool> promptCloseStoreUploadDecision(
    StoreSyncStatus status, {
    required String logTag,
    FutureOr<void> Function()? onCloseFlowRequired,
  }) async {
    final existing = _closeStoreUploadDecision;
    if (existing != null) {
      return existing.future;
    }

    final shouldAutoUpload = await getIt<PreferencesService>().settingsPrefs
        .getAutoUploadSnapshotOnCloseEnabled();
    if (shouldAutoUpload) {
      if (onCloseFlowRequired != null) {
        _ref
            .read(closeStoreSyncStatusProvider.notifier)
            .setStatus(
              status.copyWith(
                clearSyncProgress: true,
                isSyncInProgress: true,
                lastResultType: SnapshotSyncResultType.idle,
              ),
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
    _ref
        .read(closeStoreSyncStatusProvider.notifier)
        .setStatus(
          status.copyWith(
            clearSyncProgress: true,
            isSyncInProgress: false,
            lastResultType: SnapshotSyncResultType.idle,
          ),
        );

    final completer = Completer<bool>();
    _closeStoreUploadDecision = completer;
    return completer.future.whenComplete(() {
      if (identical(_closeStoreUploadDecision, completer)) {
        _closeStoreUploadDecision = null;
      }
    });
  }

  void resolveCloseStoreUploadDecision(bool shouldUpload) {
    final decision = _closeStoreUploadDecision;
    if (decision == null || decision.isCompleted) {
      return;
    }
    decision.complete(shouldUpload);
  }

  void markSnapshotUploadOnCloseRequired() {
    _forceSnapshotUploadOnClose = true;
  }

  void syncPendingSnapshotUploadPrompt({
    required DatabaseState currentState,
    required String? currentStorePath,
    required String? storeUuid,
    required bool hasBinding,
    required StoreVersionCompareResult? compareResult,
  }) {
    final isCurrentStore =
        storeUuid != null &&
        currentStorePath != null &&
        currentState.isOpen &&
        currentState.path == currentStorePath;

    _pendingSnapshotUploadPromptOnClose =
        isCurrentStore &&
        hasBinding &&
        (compareResult == StoreVersionCompareResult.remoteMissing ||
            compareResult == StoreVersionCompareResult.localNewer);
  }

  void startTracking({
    required DateTime initialModifiedAt,
    bool forceUpload = false,
  }) {
    _openedStoreModifiedAt = initialModifiedAt.toUtc();
    _forceSnapshotUploadOnClose = forceUpload;
    _pendingSnapshotUploadPromptOnClose = false;
  }

  void resetTracking() {
    _openedStoreModifiedAt = null;
    _forceSnapshotUploadOnClose = false;
    _pendingSnapshotUploadPromptOnClose = false;
  }

  void dispose() {
    resetTracking();
    final decision = _closeStoreUploadDecision;
    if (decision != null && !decision.isCompleted) {
      decision.complete(false);
    }
    _closeStoreUploadDecision = null;
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
