part of 'main_store_provider.dart';

Future<void> _tryUploadSnapshotBeforeCloseImpl(
  MainStoreAsyncNotifier notifier, {
  FutureOr<void> Function()? onCloseFlowRequired,
}) async {
  final storePath = notifier._manager.currentStorePath;
  if (storePath == null ||
      storePath.isEmpty ||
      !notifier._manager.isStoreOpen) {
    return;
  }

  final storeInfoResult = await notifier._manager.getStoreInfo();
  final storeInfo = storeInfoResult.fold((info) => info, (error) {
    throw error;
  });
  final currentModifiedAt = storeInfo.modifiedAt.toUtc();
  final hasLogicalChanges =
      notifier._forceSnapshotUploadOnClose ||
      notifier._pendingSnapshotUploadPromptOnClose ||
      notifier._openedStoreModifiedAt == null ||
      !notifier._openedStoreModifiedAt!.isAtSameMomentAs(currentModifiedAt);

  if (!hasLogicalChanges) {
    logDebug(
      'Skipping snapshot sync before close because StoreMeta.modifiedAt did not change during the current session.',
      tag: MainStoreAsyncNotifier._logTag,
      data: <String, dynamic>{
        'storePath': storePath,
        'openedStoreModifiedAt': notifier._openedStoreModifiedAt
            ?.toIso8601String(),
        'currentStoreModifiedAt': currentModifiedAt.toIso8601String(),
        'pendingSnapshotUploadPromptOnClose':
            notifier._pendingSnapshotUploadPromptOnClose,
      },
    );
    return;
  }

  final cachedStatus = _getReusableCloseStoreSyncStatus(
    notifier,
    storePath: storePath,
    storeInfo: storeInfo,
  );

  final binding =
      cachedStatus?.binding ??
      await notifier._ref
          .read(storeSyncBindingServiceProvider)
          .getByStoreUuid(storeInfo.id);
  if (binding == null) {
    return;
  }

  final token =
      cachedStatus?.token ??
      await notifier._ref
          .read(authTokensProvider.notifier)
          .getTokenById(binding.tokenId);
  if (token == null) {
    logWarning(
      'Skipping snapshot sync before close because token binding is stale.',
      tag: MainStoreAsyncNotifier._logTag,
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
    final hasInternetAccess = await _hasInternetAccessForCloseSync(notifier);
    if (!hasInternetAccess) {
      logWarning(
        'Skipping snapshot upload before close because device has no internet access and auto-upload is enabled.',
        tag: MainStoreAsyncNotifier._logTag,
        data: <String, dynamic>{'storeUuid': storeInfo.id, 'tokenId': token.id},
      );
      return;
    }
  }

  try {
    final syncService = notifier._ref.read(snapshotSyncServiceProvider);
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
        final shouldUpload = await notifier._promptCloseStoreUploadDecision(
          status,
          onCloseFlowRequired: onCloseFlowRequired,
        );
        if (!shouldUpload) {
          notifier._ref.read(closeStoreSyncStatusProvider.notifier).clear();
          logInfo(
            'Skipping snapshot upload before close by user choice.',
            tag: MainStoreAsyncNotifier._logTag,
            data: <String, dynamic>{'storeUuid': storeInfo.id},
          );
          break;
        }

        await onCloseFlowRequired?.call();
        final result = await notifier._ref
            .read(closeStoreSnapshotSyncCoordinatorProvider)
            .syncBeforeClose(
              status: status,
              storePath: storePath,
              storeInfo: storeInfo,
              binding: binding,
              token: token,
              onStatusChanged: (nextState) {
                notifier._ref
                    .read(closeStoreSyncStatusProvider.notifier)
                    .setStatus(nextState);
              },
            );
        notifier._forceSnapshotUploadOnClose = false;
        notifier._pendingSnapshotUploadPromptOnClose = false;
        logInfo(
          'Snapshot sync before close completed.',
          tag: MainStoreAsyncNotifier._logTag,
          data: <String, dynamic>{
            'storeUuid': storeInfo.id,
            'resultType': result.type.name,
          },
        );
        break;
      case StoreVersionCompareResult.same:
        notifier._forceSnapshotUploadOnClose = false;
        notifier._pendingSnapshotUploadPromptOnClose = false;
        logDebug(
          'Skipping snapshot upload before close because local and remote versions match.',
          tag: MainStoreAsyncNotifier._logTag,
          data: <String, dynamic>{'storeUuid': storeInfo.id},
        );
        break;
      case StoreVersionCompareResult.remoteNewer:
      case StoreVersionCompareResult.conflict:
      case StoreVersionCompareResult.differentStore:
        logWarning(
          'Skipping snapshot upload before close because manual resolution is required.',
          tag: MainStoreAsyncNotifier._logTag,
          data: <String, dynamic>{
            'storeUuid': storeInfo.id,
            'compareResult': status.compareResult.name,
          },
        );
        break;
    }
  } catch (error, stackTrace) {
    notifier._forceSnapshotUploadOnClose = true;
    logError(
      'Snapshot sync before close failed: $error',
      stackTrace: stackTrace,
      tag: MainStoreAsyncNotifier._logTag,
    );
    Error.throwWithStackTrace(error, stackTrace);
  }
}

StoreSyncStatus? _getReusableCloseStoreSyncStatus(
  MainStoreAsyncNotifier notifier, {
  required String storePath,
  required StoreInfoDto storeInfo,
}) {
  final status = notifier._ref.read(currentStoreSyncSnapshotProvider);
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

DatabaseError _buildCloseSyncFailureImpl(
  MainStoreAsyncNotifier notifier,
  Object error, {
  required StackTrace stackTrace,
}) {
  final message = notifier._formatCloseSyncFailureMessage(error);
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

String _formatCloseSyncFailureMessageImpl(Object error) {
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

Future<bool> _shouldAllowCloseWithoutSyncFailureImpl(
  MainStoreAsyncNotifier notifier,
  Object error,
) async {
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

Future<bool> _promptCloseStoreUploadDecisionImpl(
  MainStoreAsyncNotifier notifier,
  StoreSyncStatus status, {
  FutureOr<void> Function()? onCloseFlowRequired,
}) async {
  final existing = notifier._closeStoreUploadDecision;
  if (existing != null) {
    return existing.future;
  }

  final shouldAutoUpload = await getIt<PreferencesService>().settingsPrefs
      .getAutoUploadSnapshotOnCloseEnabled();
  if (shouldAutoUpload) {
    if (onCloseFlowRequired != null) {
      notifier._ref
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
      tag: MainStoreAsyncNotifier._logTag,
      data: <String, dynamic>{
        'storeUuid': status.storeUuid,
        'compareResult': status.compareResult.name,
      },
    );
    return true;
  }

  await onCloseFlowRequired?.call();
  notifier._ref
      .read(closeStoreSyncStatusProvider.notifier)
      .setStatus(
        status.copyWith(
          clearSyncProgress: true,
          isSyncInProgress: false,
          lastResultType: SnapshotSyncResultType.idle,
        ),
      );

  final completer = Completer<bool>();
  notifier._closeStoreUploadDecision = completer;
  return completer.future.whenComplete(() {
    if (identical(notifier._closeStoreUploadDecision, completer)) {
      notifier._closeStoreUploadDecision = null;
    }
  });
}

void _resolveCloseStoreUploadDecisionImpl(
  MainStoreAsyncNotifier notifier,
  bool shouldUpload,
) {
  final decision = notifier._closeStoreUploadDecision;
  if (decision == null || decision.isCompleted) {
    return;
  }
  decision.complete(shouldUpload);
}

void _markSnapshotUploadOnCloseRequiredImpl(MainStoreAsyncNotifier notifier) {
  notifier._forceSnapshotUploadOnClose = true;
}

void _syncPendingSnapshotUploadPromptImpl(
  MainStoreAsyncNotifier notifier, {
  required String? storeUuid,
  required bool hasBinding,
  required StoreVersionCompareResult? compareResult,
}) {
  final currentPath = notifier._manager.currentStorePath;
  final currentState = notifier._currentState;
  final isCurrentStore =
      storeUuid != null &&
      currentPath != null &&
      currentState.isOpen &&
      currentState.path == currentPath;

  notifier._pendingSnapshotUploadPromptOnClose =
      isCurrentStore &&
      hasBinding &&
      (compareResult == StoreVersionCompareResult.remoteMissing ||
          compareResult == StoreVersionCompareResult.localNewer);
}

void _startSnapshotCloseTrackingImpl(
  MainStoreAsyncNotifier notifier, {
  required DateTime initialModifiedAt,
  required bool forceUpload,
}) {
  notifier._openedStoreModifiedAt = initialModifiedAt.toUtc();
  notifier._forceSnapshotUploadOnClose = forceUpload;
  notifier._pendingSnapshotUploadPromptOnClose = false;
}

void _resetSnapshotCloseTrackingImpl(MainStoreAsyncNotifier notifier) {
  notifier._openedStoreModifiedAt = null;
  notifier._forceSnapshotUploadOnClose = false;
  notifier._pendingSnapshotUploadPromptOnClose = false;
}

Future<bool> _hasInternetAccessForCloseSync(
  MainStoreAsyncNotifier notifier,
) async {
  try {
    return await notifier._ref
        .read(internetConnectionProvider)
        .hasInternetAccess;
  } catch (_) {
    return false;
  }
}
