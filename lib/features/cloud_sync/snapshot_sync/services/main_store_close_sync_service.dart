import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_exception.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';
import 'package:hoplixi/main_db/core/old/models/dto/main_store_dto.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/close_sync_state.dart';

class CloseSyncService {
  const CloseSyncService();

  bool hasLogicalChanges({
    required DateTime? openedModifiedAt,
    required bool forceUpload,
    required bool pendingPrompt,
    required DateTime currentModifiedAt,
  }) {
    final currentModifiedAtUtc = currentModifiedAt.toUtc();
    return forceUpload ||
        pendingPrompt ||
        openedModifiedAt == null ||
        !openedModifiedAt.isAtSameMomentAs(currentModifiedAtUtc);
  }

  StoreSyncStatus? reusableStatus({
    required StoreSyncStatus? cachedStatus,
    required String storePath,
    required StoreInfoDto storeInfo,
  }) {
    if (cachedStatus == null) {
      return null;
    }

    final hasSameStoreIdentity =
        cachedStatus.isStoreOpen &&
        cachedStatus.storePath == storePath &&
        cachedStatus.storeUuid == storeInfo.id;
    if (!hasSameStoreIdentity) {
      return null;
    }

    if (cachedStatus.binding == null || cachedStatus.token == null) {
      return null;
    }

    if (cachedStatus.remoteCheckSkippedOffline ||
        cachedStatus.isSyncInProgress) {
      return null;
    }

    return cachedStatus;
  }

  StoreSyncStatus closePromptStatus(StoreSyncStatus status) {
    return status.copyWith(
      clearSyncProgress: true,
      isSyncInProgress: false,
      lastResultType: SnapshotSyncResultType.idle,
    );
  }

  StoreSyncStatus closeSyncBaseStatus({
    required StoreSyncStatus status,
    required String storePath,
    required StoreInfoDto storeInfo,
    required StoreSyncBinding binding,
    required AuthTokenEntry token,
  }) {
    return status.copyWith(
      isStoreOpen: true,
      storePath: storePath,
      storeUuid: binding.storeUuid,
      storeName: status.storeName ?? storeInfo.name,
      binding: binding,
      token: token,
      clearPendingConflict: true,
      clearSyncProgress: true,
      isSyncInProgress: false,
      isApplyingRemoteUpdate: false,
      requiresUnlockToApply: false,
    );
  }

  MainStoreCloseSyncOutcome skipped(MainStoreCloseSyncOutcomeType type) {
    return MainStoreCloseSyncOutcome(type);
  }

  MainStoreCloseSyncOutcome uploaded(SnapshotSyncResultType resultType) {
    return MainStoreCloseSyncOutcome(
      MainStoreCloseSyncOutcomeType.uploaded,
      resultType: resultType,
    );
  }

  bool shouldAllowCloseWithoutSyncFailure({
    required bool autoUploadEnabled,
    required Object error,
  }) {
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
          'Хранилище закрыто, но не удалось отправить изменения в облако из-за проблем с интернет-соединением.',
        CloudStorageExceptionType.timeout =>
          'Хранилище закрыто, но не удалось отправить изменения в облако: сервер не ответил вовремя.',
        CloudStorageExceptionType.unauthorized =>
          'Хранилище закрыто, но не удалось отправить изменения в облако: требуется повторно подключить аккаунт синхронизации.',
        _ when message.trim().isNotEmpty =>
          'Хранилище закрыто, но не удалось отправить изменения в облако. $message',
        _ =>
          'Хранилище закрыто, но не удалось отправить изменения в облако.',
      };
    }

    if (error case CloudSyncHttpException(:final type)) {
      return switch (type) {
        CloudSyncHttpExceptionType.network =>
          'Хранилище закрыто, но не удалось отправить изменения в облако из-за проблем с интернет-соединением.',
        CloudSyncHttpExceptionType.timeout =>
          'Хранилище закрыто, но не удалось отправить изменения в облако: сервер не ответил вовремя.',
        CloudSyncHttpExceptionType.refreshFailed ||
        CloudSyncHttpExceptionType.unauthorized =>
          'Хранилище закрыто, но не удалось отправить изменения в облако: требуется повторно подключить аккаунт синхронизации.',
        _ =>
          'Хранилище закрыто, но не удалось отправить изменения в облако.',
      };
    }

    if (error is AppError) {
      return 'Хранилище закрыто, но не удалось завершить синхронизацию. ${error.message}';
    }

    return 'Хранилище закрыто, но не удалось отправить изменения в облако.';
  }
}
