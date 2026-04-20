part of 'main_store_provider.dart';

Future<BackupResult?> _createBackupImpl(
  MainStoreAsyncNotifier notifier, {
  required BackupScope scope,
  String? outputDirPath,
  required bool periodic,
  required int maxBackupsPerStore,
}) async {
  try {
    if (!notifier._currentState.isOpen) {
      logWarning(
        'Store is not open, cannot create backup',
        tag: MainStoreAsyncNotifier._logTag,
      );
      return null;
    }

    final storeDirPath =
        notifier._currentState.path ?? notifier._manager.currentStorePath;
    if (storeDirPath == null || storeDirPath.isEmpty) {
      logError(
        'Store path is null, backup aborted',
        tag: MainStoreAsyncNotifier._logTag,
      );
      return null;
    }

    final attachmentsPath =
        scope == BackupScope.encryptedFilesOnly || scope == BackupScope.full
        ? await notifier.getAttachmentsPath()
        : null;

    final backupData = await notifier._backupService.createBackup(
      storeDirPath: storeDirPath,
      storeName: notifier._currentState.name ?? 'store',
      includeDatabase:
          scope == BackupScope.databaseOnly || scope == BackupScope.full,
      includeEncryptedFiles:
          scope == BackupScope.encryptedFilesOnly || scope == BackupScope.full,
      attachmentsPath: attachmentsPath,
      outputDirPath: outputDirPath,
      periodic: periodic,
      maxBackupsPerStore: maxBackupsPerStore,
    );

    logInfo(
      'Backup created successfully: ${backupData.backupPath} (scope: ${scope.name})',
      tag: MainStoreAsyncNotifier._logTag,
    );

    return BackupResult(
      backupPath: backupData.backupPath,
      scope: scope,
      createdAt: backupData.createdAt,
      periodic: periodic,
    );
  } catch (e, stackTrace) {
    logError(
      'Failed to create backup: $e',
      stackTrace: stackTrace,
      tag: MainStoreAsyncNotifier._logTag,
    );
    return null;
  }
}

void _startPeriodicBackupImpl(
  MainStoreAsyncNotifier notifier, {
  required Duration interval,
  required BackupScope scope,
  String? outputDirPath,
  required bool runImmediately,
  required int maxBackupsPerStore,
}) {
  if (interval.inSeconds <= 0) {
    logWarning(
      'Invalid backup interval: $interval',
      tag: MainStoreAsyncNotifier._logTag,
    );
    return;
  }

  notifier.stopPeriodicBackup();

  notifier._periodicBackupInterval = interval;
  notifier._periodicBackupScope = scope;
  notifier._periodicBackupOutputDirPath = outputDirPath;
  notifier._periodicBackupMaxPerStore = maxBackupsPerStore <= 0
      ? 1
      : maxBackupsPerStore;

  notifier._periodicBackupTimer = Timer.periodic(interval, (_) {
    unawaited(_runPeriodicBackupTickImpl(notifier));
  });

  if (runImmediately) {
    unawaited(_runPeriodicBackupTickImpl(notifier));
  }

  logInfo(
    'Periodic backup started (interval: $interval, scope: ${scope.name})',
    tag: MainStoreAsyncNotifier._logTag,
  );
}

Future<void> _runPeriodicBackupTickImpl(MainStoreAsyncNotifier notifier) async {
  if (!notifier._currentState.isOpen) {
    return;
  }

  await notifier.createBackup(
    scope: notifier._periodicBackupScope,
    outputDirPath: notifier._periodicBackupOutputDirPath,
    periodic: true,
    maxBackupsPerStore: notifier._periodicBackupMaxPerStore,
  );
}

void _stopPeriodicBackupImpl(MainStoreAsyncNotifier notifier) {
  notifier._periodicBackupTimer?.cancel();
  notifier._periodicBackupTimer = null;
  notifier._periodicBackupInterval = null;
  notifier._periodicBackupOutputDirPath = null;

  logInfo('Periodic backup stopped', tag: MainStoreAsyncNotifier._logTag);
}
