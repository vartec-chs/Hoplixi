part of 'main_store_provider.dart';

Future<void> _runStartupCleanupImpl(MainStoreAsyncNotifier notifier) async {
  try {
    final store = notifier._manager.currentStore;
    if (store == null) return;

    final storePath = notifier._manager.currentStorePath;
    if (storePath == null || storePath.isEmpty) return;

    await notifier._maintenanceService.runStartupCleanup(
      store: store,
      storePath: storePath,
    );
  } catch (e, s) {
    logError(
      'Startup cleanup failed: $e',
      stackTrace: s,
      tag: MainStoreAsyncNotifier._logTag,
    );
  }
}

Future<bool> _deleteStoreImpl(
  MainStoreAsyncNotifier notifier,
  String path, {
  required bool deleteFromDisk,
}) async {
  try {
    logInfo('Deleting store at: $path', tag: MainStoreAsyncNotifier._logTag);

    notifier._setState(
      notifier._currentState.copyWith(
        status: DatabaseStatus.loading,
        error: null,
      ),
    );

    if (notifier._manager.currentStorePath == path &&
        notifier._manager.isStoreOpen) {
      await notifier._manager.closeStore();
    }

    final dbHistoryService = await notifier._ref.read(dbHistoryProvider.future);
    await dbHistoryService.deleteByPath(path);

    if (deleteFromDisk &&
        await notifier._maintenanceService.storageDirectoryExists(path)) {
      await notifier._maintenanceService.deleteStorageDirectory(path);
    }

    notifier._setState(const DatabaseState(status: DatabaseStatus.idle));

    logInfo('Store deleted successfully', tag: MainStoreAsyncNotifier._logTag);
    return true;
  } catch (e, stackTrace) {
    logError(
      'Unexpected error deleting store: $e',
      stackTrace: stackTrace,
      tag: MainStoreAsyncNotifier._logTag,
    );

    notifier._setErrorState(
      DatabaseState(
        status: DatabaseStatus.error,
        error: DatabaseError.unknown(
          message: 'Неожиданная ошибка при удалении хранилища: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      ),
    );

    return false;
  }
}

Future<bool> _deleteStoreFromDiskImpl(
  MainStoreAsyncNotifier notifier,
  String path,
) async {
  try {
    logInfo(
      'Deleting store from disk at: $path',
      tag: MainStoreAsyncNotifier._logTag,
    );

    notifier._setState(
      notifier._currentState.copyWith(
        status: DatabaseStatus.loading,
        error: null,
      ),
    );

    if (notifier._manager.currentStorePath == path &&
        notifier._manager.isStoreOpen) {
      await notifier._manager.closeStore();
    }

    if (!await notifier._maintenanceService.storageDirectoryExists(path)) {
      notifier._setErrorState(
        DatabaseState(
          status: DatabaseStatus.error,
          error: DatabaseError.recordNotFound(
            message: 'Директория хранилища не найдена',
            data: {'path': path},
            timestamp: DateTime.now(),
          ),
        ),
      );
      return false;
    }

    await notifier._maintenanceService.deleteStorageDirectory(path);

    final dbHistoryService = await notifier._ref.read(dbHistoryProvider.future);
    final historyDeleted = await dbHistoryService.deleteByPath(path);
    if (historyDeleted) {
      logInfo(
        'Store history entry deleted successfully',
        tag: MainStoreAsyncNotifier._logTag,
      );
    } else {
      logWarning(
        'Failed to delete store history entry: $path',
        tag: MainStoreAsyncNotifier._logTag,
      );
    }

    notifier._setState(const DatabaseState(status: DatabaseStatus.idle));

    logInfo(
      'Store deleted from disk successfully',
      tag: MainStoreAsyncNotifier._logTag,
    );
    return true;
  } catch (e, stackTrace) {
    logError(
      'Unexpected error deleting store from disk: $e',
      stackTrace: stackTrace,
      tag: MainStoreAsyncNotifier._logTag,
    );

    notifier._setErrorState(
      DatabaseState(
        status: DatabaseStatus.error,
        error: DatabaseError.unknown(
          message: 'Неожиданная ошибка при удалении хранилища с диска: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      ),
    );

    return false;
  }
}

Future<String?> _getAttachmentsPathImpl(MainStoreAsyncNotifier notifier) async {
  try {
    if (!notifier._currentState.isOpen) {
      logWarning(
        'Store is not open, cannot get attachments path',
        tag: MainStoreAsyncNotifier._logTag,
      );
      return null;
    }

    final storePath = notifier._manager.currentStorePath;
    if (storePath == null || storePath.isEmpty) {
      logError(
        'Failed to get attachments path: store path is null',
        tag: MainStoreAsyncNotifier._logTag,
      );
      return null;
    }

    return notifier._maintenanceService.getAttachmentsPath(storePath);
  } catch (e, stackTrace) {
    logError(
      'Unexpected error getting attachments path: $e',
      stackTrace: stackTrace,
      tag: MainStoreAsyncNotifier._logTag,
    );
    return null;
  }
}

Future<String?> _getDecryptedAttachmentsPathImpl(
  MainStoreAsyncNotifier notifier,
) async {
  try {
    if (!notifier._currentState.isOpen) {
      logWarning(
        'Store is not open, cannot get decrypted attachments path',
        tag: MainStoreAsyncNotifier._logTag,
      );
      return null;
    }

    final storePath = notifier._manager.currentStorePath;
    if (storePath == null || storePath.isEmpty) {
      logError(
        'Failed to get decrypted attachments path: store path is null',
        tag: MainStoreAsyncNotifier._logTag,
      );
      return null;
    }

    return notifier._maintenanceService.getDecryptedAttachmentsPath(storePath);
  } catch (e, stackTrace) {
    logError(
      'Unexpected error getting decrypted attachments path: $e',
      stackTrace: stackTrace,
      tag: MainStoreAsyncNotifier._logTag,
    );
    return null;
  }
}

Future<String?> _createSubfolderImpl(
  MainStoreAsyncNotifier notifier,
  String folderName,
) async {
  try {
    if (!notifier._currentState.isOpen) {
      logWarning(
        'Store is not open, cannot create subfolder',
        tag: MainStoreAsyncNotifier._logTag,
      );
      return null;
    }

    final storePath = notifier._manager.currentStorePath;
    if (storePath == null || storePath.isEmpty) {
      logError(
        'Failed to create subfolder: store path is null',
        tag: MainStoreAsyncNotifier._logTag,
      );
      return null;
    }

    final path = await notifier._maintenanceService.createSubfolder(
      storePath: storePath,
      folderName: folderName,
    );

    logInfo('Subfolder created: $path', tag: MainStoreAsyncNotifier._logTag);
    return path;
  } catch (e, stackTrace) {
    logError(
      'Unexpected error creating subfolder: $e',
      stackTrace: stackTrace,
      tag: MainStoreAsyncNotifier._logTag,
    );
    return null;
  }
}

void _clearErrorImpl(MainStoreAsyncNotifier notifier) {
  notifier._cancelErrorResetTimer();
  notifier._setState(notifier._currentState.copyWith(error: null));
}
