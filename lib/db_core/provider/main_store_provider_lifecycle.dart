part of 'main_store_provider.dart';

Future<bool> _createStoreImpl(
  MainStoreAsyncNotifier notifier,
  CreateStoreDto dto,
) async {
  await notifier._acquireLock();

  try {
    logInfo('Creating store: ${dto.name}', tag: MainStoreAsyncNotifier._logTag);

    notifier._setState(
      notifier._currentState.copyWith(
        status: DatabaseStatus.loading,
        error: null,
      ),
    );

    final result = await notifier._manager.createStore(dto);

    return result.fold(
      (storeInfo) {
        notifier._setState(
          DatabaseState(
            path: notifier._manager.currentStorePath,
            name: storeInfo.name,
            status: DatabaseStatus.open,
            modifiedAt: storeInfo.modifiedAt,
          ),
        );
        notifier._startSnapshotCloseTracking(
          initialModifiedAt: storeInfo.modifiedAt,
          forceUpload: true,
        );

        logInfo(
          'Store created successfully: ${storeInfo.name}',
          tag: MainStoreAsyncNotifier._logTag,
        );
        unawaited(notifier._runStartupCleanup());
        return true;
      },
      (error) {
        notifier._setErrorState(
          DatabaseState(status: DatabaseStatus.error, error: error),
        );

        logError(
          'Failed to create store: ${error.message}',
          tag: MainStoreAsyncNotifier._logTag,
        );
        return false;
      },
    );
  } catch (e, stackTrace) {
    logError(
      'Unexpected error creating store: $e',
      stackTrace: stackTrace,
      tag: MainStoreAsyncNotifier._logTag,
    );

    notifier._setErrorState(
      DatabaseState(
        status: DatabaseStatus.error,
        error: DatabaseError.unknown(
          message: 'Неожиданная ошибка при создании хранилища: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      ),
    );

    return false;
  } finally {
    notifier._releaseLock();
  }
}

Future<bool> _openStoreImpl(
  MainStoreAsyncNotifier notifier,
  OpenStoreDto dto,
) async {
  notifier._ref.read(mainStoreOpeningOverlayProvider.notifier).show();
  await notifier._acquireLock();

  try {
    logInfo(
      'Opening store at: ${dto.path}',
      tag: MainStoreAsyncNotifier._logTag,
    );

    notifier._setState(
      notifier._currentState.copyWith(
        status: DatabaseStatus.loading,
        error: null,
      ),
    );

    final result = await notifier._manager.openStore(dto);

    return result.fold(notifier._handleOpenStoreSuccess, (error) {
      notifier._handleOpenStoreFailure(error);
      return false;
    });
  } catch (e, stackTrace) {
    logError(
      'Unexpected error opening store: $e',
      stackTrace: stackTrace,
      tag: MainStoreAsyncNotifier._logTag,
    );

    notifier._setErrorState(
      notifier._buildOpenFailureState(
        DatabaseError.unknown(
          message: 'Неожиданная ошибка при открытии хранилища: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      ),
    );

    return false;
  } finally {
    notifier._ref.read(mainStoreOpeningOverlayProvider.notifier).hide();
    notifier._releaseLock();
  }
}

Future<bool> _backupAndMigrateStoreImpl(
  MainStoreAsyncNotifier notifier,
  OpenStoreDto dto, {
  String? outputDirPath,
  required int maxBackupsPerStore,
}) async {
  notifier._ref.read(mainStoreOpeningOverlayProvider.notifier).show();
  await notifier._acquireLock();

  try {
    logInfo(
      'Creating backup and migrating store at: ${dto.path}',
      tag: MainStoreAsyncNotifier._logTag,
    );

    notifier._setState(
      notifier._currentState.copyWith(
        status: DatabaseStatus.loading,
        error: null,
      ),
    );

    final actualStoragePath = await notifier._manager.resolveStoragePath(
      dto.path,
    );
    final manifest = await StoreManifestService.readFrom(actualStoragePath);
    final storeName = manifest?.storeName.trim().isNotEmpty == true
        ? manifest!.storeName
        : notifier._currentState.name ?? 'store';

    final backupData = await notifier._backupService.createBackup(
      storeDirPath: actualStoragePath,
      storeName: storeName,
      includeDatabase: true,
      includeEncryptedFiles: true,
      attachmentsPath: notifier._maintenanceService.getAttachmentsPath(
        actualStoragePath,
      ),
      outputDirPath: outputDirPath,
      periodic: false,
      maxBackupsPerStore: maxBackupsPerStore,
    );

    logInfo(
      'Backup created before migration: ${backupData.backupPath}',
      tag: MainStoreAsyncNotifier._logTag,
    );

    final result = await notifier._manager.openStore(dto, allowMigration: true);
    return result.fold(notifier._handleOpenStoreSuccess, (error) {
      notifier._handleOpenStoreFailure(error);
      return false;
    });
  } catch (e, stackTrace) {
    logError(
      'Failed to backup and migrate store: $e',
      stackTrace: stackTrace,
      tag: MainStoreAsyncNotifier._logTag,
    );

    final error = DatabaseError.archiveFailed(
      message: 'Не удалось создать backup перед миграцией: $e',
      timestamp: DateTime.now(),
      stackTrace: stackTrace,
    );
    notifier._setErrorState(notifier._buildOpenFailureState(error));
    return false;
  } finally {
    notifier._ref.read(mainStoreOpeningOverlayProvider.notifier).hide();
    notifier._releaseLock();
  }
}

Future<bool> _closeStoreImpl(MainStoreAsyncNotifier notifier) async {
  await notifier._acquireLock();
  DatabaseState? openStateBeforeClose;

  try {
    notifier._ref.read(closeStoreSyncStatusProvider.notifier).clear();
    logInfo('Closing store', tag: MainStoreAsyncNotifier._logTag);

    if (!notifier._currentState.isOpen) {
      logWarning(
        'Store is not open, cannot close',
        tag: MainStoreAsyncNotifier._logTag,
      );
      return false;
    }

    openStateBeforeClose = notifier._currentState;
    final decryptedPathBeforeClose = await notifier
        .getDecryptedAttachmentsPath();

    try {
      await notifier._tryUploadSnapshotBeforeClose(
        onCloseFlowRequired: () {
          notifier._setState(
            openStateBeforeClose!.copyWith(
              status: DatabaseStatus.closingSync,
              error: null,
            ),
          );
        },
      );
    } catch (error, stackTrace) {
      final closeSyncError = notifier._buildCloseSyncFailure(
        error,
        stackTrace: stackTrace,
      );
      notifier._setState(
        openStateBeforeClose.copyWith(
          status: DatabaseStatus.open,
          error: closeSyncError,
        ),
      );
      notifier._ref.read(closeStoreSyncStatusProvider.notifier).clear();
      return false;
    }

    final result = await notifier._manager.closeStore();

    final isClosed = result.fold((_) => true, (error) {
      notifier._setState(
        openStateBeforeClose!.copyWith(
          status: DatabaseStatus.open,
          error: error,
        ),
      );

      logError(
        'Failed to close store: ${error.message}',
        tag: MainStoreAsyncNotifier._logTag,
      );
      return false;
    });

    if (!isClosed) {
      notifier._ref.read(closeStoreSyncStatusProvider.notifier).clear();
      return false;
    }

    await notifier._maintenanceService.cleanupDecryptedAttachmentsDir(
      decryptedPathBeforeClose,
    );
    notifier._resetSnapshotCloseTracking();

    notifier._setState(const DatabaseState(status: DatabaseStatus.closed));
    notifier._setState(const DatabaseState(status: DatabaseStatus.idle));
    notifier._ref.read(closeStoreSyncStatusProvider.notifier).clear();

    logInfo('Store closed successfully', tag: MainStoreAsyncNotifier._logTag);
    return true;
  } catch (e, stackTrace) {
    logError(
      'Unexpected error closing store: $e',
      stackTrace: stackTrace,
      tag: MainStoreAsyncNotifier._logTag,
    );

    notifier._setState(
      (openStateBeforeClose ?? notifier._currentState).copyWith(
        status: openStateBeforeClose != null
            ? DatabaseStatus.open
            : DatabaseStatus.error,
        error: DatabaseError.unknown(
          message: 'Неожиданная ошибка при закрытии хранилища: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      ),
    );
    notifier._ref.read(closeStoreSyncStatusProvider.notifier).clear();

    return false;
  } finally {
    notifier._releaseLock();
  }
}

Future<void> _lockStoreImpl(
  MainStoreAsyncNotifier notifier, {
  required bool skipSnapshotSync,
}) async {
  if (!notifier._currentState.isOpen) {
    logWarning(
      'Store is not open, cannot lock',
      tag: MainStoreAsyncNotifier._logTag,
    );
    return;
  }

  notifier._ref.read(closeStoreSyncStatusProvider.notifier).clear();
  logInfo('Locking store', tag: MainStoreAsyncNotifier._logTag);

  final currentPath = notifier._currentState.path;
  final currentName = notifier._currentState.name;
  final decryptedPathBeforeLock = await notifier.getDecryptedAttachmentsPath();

  if (!skipSnapshotSync) {
    await notifier._tryUploadSnapshotBeforeClose();
  }

  final closeResult = await notifier._manager.closeStore();
  closeResult.fold((_) => null, (error) {
    logError(
      'Failed to close store during lock: ${error.message}',
      tag: MainStoreAsyncNotifier._logTag,
    );
    return null;
  });

  await notifier._maintenanceService.cleanupDecryptedAttachmentsDir(
    decryptedPathBeforeLock,
  );
  notifier._resetSnapshotCloseTracking();

  notifier._setState(
    notifier._currentState.copyWith(
      status: DatabaseStatus.locked,
      error: null,
      path: currentPath,
      name: currentName,
    ),
  );
  notifier._ref.read(closeStoreSyncStatusProvider.notifier).clear();

  logInfo('Store locked successfully', tag: MainStoreAsyncNotifier._logTag);
}

void _resetStateImpl(MainStoreAsyncNotifier notifier) {
  logInfo('Resetting state to idle', tag: MainStoreAsyncNotifier._logTag);
  notifier._setState(const DatabaseState(status: DatabaseStatus.idle));
}

Future<bool> _unlockStoreImpl(
  MainStoreAsyncNotifier notifier,
  String password,
) async {
  try {
    if (!notifier._currentState.isLocked) {
      logWarning(
        'Store is not locked, cannot unlock',
        tag: MainStoreAsyncNotifier._logTag,
      );
      return false;
    }

    logInfo('Unlocking store', tag: MainStoreAsyncNotifier._logTag);

    notifier._setState(
      notifier._currentState.copyWith(
        status: DatabaseStatus.loading,
        error: null,
      ),
    );

    final currentPath = notifier._currentState.path;
    if (currentPath == null) {
      notifier._setState(
        notifier._currentState.copyWith(
          status: DatabaseStatus.error,
          error: DatabaseError.notInitialized(
            message: 'Путь к хранилищу не найден',
            timestamp: DateTime.now(),
          ),
        ),
      );
      return false;
    }

    await notifier._manager.closeStore();

    final result = await notifier._manager.openStore(
      OpenStoreDto(path: currentPath, password: password),
    );

    return result.fold(
      (storeInfo) {
        notifier._setState(
          notifier._currentState.copyWith(
            status: DatabaseStatus.open,
            modifiedAt: storeInfo.modifiedAt,
          ),
        );

        logInfo(
          'Store unlocked successfully',
          tag: MainStoreAsyncNotifier._logTag,
        );
        unawaited(notifier._runStartupCleanup());
        return true;
      },
      (error) {
        notifier._setState(
          notifier._currentState.copyWith(
            status: DatabaseStatus.locked,
            error: error,
          ),
        );

        logError(
          'Failed to unlock store: ${error.message}',
          tag: MainStoreAsyncNotifier._logTag,
        );
        return false;
      },
    );
  } catch (e, stackTrace) {
    logError(
      'Unexpected error unlocking store: $e',
      stackTrace: stackTrace,
      tag: MainStoreAsyncNotifier._logTag,
    );

    notifier._setState(
      notifier._currentState.copyWith(
        status: DatabaseStatus.locked,
        error: DatabaseError.unknown(
          message: 'Неожиданная ошибка при разблокировке: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      ),
    );

    return false;
  }
}

Future<bool> _updateStoreImpl(
  MainStoreAsyncNotifier notifier,
  UpdateStoreDto dto,
) async {
  try {
    if (!notifier._currentState.isOpen) {
      logWarning(
        'Store is not open, cannot update',
        tag: MainStoreAsyncNotifier._logTag,
      );
      return false;
    }

    logInfo('Updating store metadata', tag: MainStoreAsyncNotifier._logTag);

    notifier._setState(
      notifier._currentState.copyWith(
        status: DatabaseStatus.loading,
        error: null,
      ),
    );

    final result = await notifier._manager.updateStore(dto);

    return result.fold(
      (storeInfo) {
        notifier._setState(
          notifier._currentState.copyWith(
            name: storeInfo.name,
            status: DatabaseStatus.open,
            modifiedAt: storeInfo.modifiedAt,
          ),
        );

        logInfo(
          'Store updated successfully',
          tag: MainStoreAsyncNotifier._logTag,
        );
        return true;
      },
      (error) {
        notifier._setState(
          notifier._currentState.copyWith(
            status: DatabaseStatus.open,
            error: error,
          ),
        );

        logError(
          'Failed to update store: ${error.message}',
          tag: MainStoreAsyncNotifier._logTag,
        );
        return false;
      },
    );
  } catch (e, stackTrace) {
    logError(
      'Unexpected error updating store: $e',
      stackTrace: stackTrace,
      tag: MainStoreAsyncNotifier._logTag,
    );

    notifier._setErrorState(
      notifier._currentState.copyWith(
        status: DatabaseStatus.error,
        error: DatabaseError.unknown(
          message: 'Неожиданная ошибка при обновлении хранилища: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      ),
    );

    return false;
  }
}

bool _handleOpenStoreSuccessImpl(
  MainStoreAsyncNotifier notifier,
  StoreInfoDto storeInfo,
) {
  notifier._setState(
    DatabaseState(
      path: notifier._manager.currentStorePath,
      name: storeInfo.name,
      status: DatabaseStatus.open,
      modifiedAt: storeInfo.modifiedAt,
    ),
  );
  notifier._startSnapshotCloseTracking(initialModifiedAt: storeInfo.modifiedAt);

  logInfo(
    'Store opened successfully: ${storeInfo.name}',
    tag: MainStoreAsyncNotifier._logTag,
  );
  unawaited(notifier._runStartupCleanup());
  return true;
}

void _handleOpenStoreFailureImpl(
  MainStoreAsyncNotifier notifier,
  DatabaseError error,
) {
  notifier._setErrorState(notifier._buildOpenFailureState(error));
  logError(
    'Failed to open store: ${error.message}',
    tag: MainStoreAsyncNotifier._logTag,
  );
}

DatabaseState _buildOpenFailureStateImpl(
  MainStoreAsyncNotifier notifier,
  DatabaseError error,
) {
  if (notifier._manager.isStoreOpen) {
    return notifier._currentState.copyWith(
      status: DatabaseStatus.open,
      error: error,
    );
  }

  return DatabaseState(status: DatabaseStatus.error, error: error);
}
