import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/logger/models.dart' as logger_models;
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_store_lock.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

class CloudStoreLockService {
  CloudStoreLockService({
    required CloudStoreLockRemoteStore repository,
    Uuid? uuid,
    String Function()? lockIdGenerator,
    Future<logger_models.DeviceInfo> Function()? deviceInfoLoader,
    Future<PackageInfo> Function()? packageInfoLoader,
    DateTime Function()? now,
    Duration staleLockTtl = const Duration(hours: 24),
  }) : _repository = repository,
       _uuid = uuid ?? const Uuid(),
       _lockIdGenerator = lockIdGenerator,
       _deviceInfoLoader = deviceInfoLoader ?? logger_models.DeviceInfo.collect,
       _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform,
       _now = now ?? (() => DateTime.now().toUtc()),
       _staleLockTtl = staleLockTtl;

  static const String _logTag = 'CloudStoreLockService';
  static const String _feature = 'cloud_sync';

  final CloudStoreLockRemoteStore _repository;
  final Uuid _uuid;
  final String Function()? _lockIdGenerator;
  final Future<logger_models.DeviceInfo> Function() _deviceInfoLoader;
  final Future<PackageInfo> Function() _packageInfoLoader;
  final DateTime Function() _now;
  final Duration _staleLockTtl;

  AsyncResultDart<CloudStoreLockAcquireResult, AppError> acquireLock({
    required String tokenId,
    required String storeUuid,
    required bool syncEnabled,
  }) async {
    if (!syncEnabled) {
      logDebug(
        'Skipping cloud store lock because sync is disabled.',
        tag: _logTag,
        data: <String, dynamic>{'storeUuid': storeUuid},
      );
      return const Success(
        CloudStoreLockAcquireResult(
          status: CloudStoreLockAcquireStatus.syncDisabled,
        ),
      );
    }

    try {
      final localLock = await _buildLocalLock(storeUuid);
      final remoteLock = await _repository.readStoreLockFile(
        tokenId,
        storeUuid: storeUuid,
      );

      if (remoteLock == null) {
        await _repository.writeStoreLockFile(
          tokenId,
          storeUuid: storeUuid,
          lock: localLock,
        );
        logInfo(
          'Cloud store lock acquired.',
          tag: _logTag,
          data: _lockLogData(localLock),
        );
        return Success(
          CloudStoreLockAcquireResult(
            status: CloudStoreLockAcquireStatus.acquired,
            currentLock: localLock,
          ),
        );
      }

      if (_isOwnedByCurrentInstance(remoteLock, localLock)) {
        final refreshedLock = remoteLock.copyWith(
          updatedAt: _now().toIso8601String(),
        );
        await _repository.writeStoreLockFile(
          tokenId,
          storeUuid: storeUuid,
          lock: refreshedLock,
        );
        logInfo(
          'Cloud store lock already belongs to this app instance.',
          tag: _logTag,
          data: _lockLogData(refreshedLock),
        );
        return Success(
          CloudStoreLockAcquireResult(
            status: CloudStoreLockAcquireStatus.alreadyOwned,
            currentLock: refreshedLock,
          ),
        );
      }

      if (_isStale(remoteLock)) {
        await _repository.writeStoreLockFile(
          tokenId,
          storeUuid: storeUuid,
          lock: localLock,
        );
        logWarning(
          'Stale cloud store lock replaced.',
          tag: _logTag,
          data: <String, dynamic>{
            ..._lockLogData(localLock),
            'conflictingDeviceId': remoteLock.deviceId,
            'conflictingAppInstanceId': remoteLock.appInstanceId,
            'conflictingUpdatedAt': remoteLock.updatedAt,
          },
        );
        return Success(
          CloudStoreLockAcquireResult(
            status: CloudStoreLockAcquireStatus.staleReplaced,
            currentLock: localLock,
            conflictingLock: remoteLock,
          ),
        );
      }

      logWarning(
        'Cloud store lock belongs to another device.',
        tag: _logTag,
        data: <String, dynamic>{
          'storeUuid': storeUuid,
          'conflictingDeviceId': remoteLock.deviceId,
          'conflictingDeviceName': remoteLock.deviceName,
          'conflictingAppInstanceId': remoteLock.appInstanceId,
          'conflictingUpdatedAt': remoteLock.updatedAt,
        },
      );
      return Success(
        CloudStoreLockAcquireResult(
          status: CloudStoreLockAcquireStatus.lockedByAnotherDevice,
          conflictingLock: remoteLock,
        ),
      );
    } catch (error, stackTrace) {
      final appError = _mapFailure(
        error,
        stackTrace,
        code: 'acquire_lock_failed',
        message: 'Не удалось проверить cloud lock хранилища',
        storeUuid: storeUuid,
      );
      logError(
        'Failed to acquire cloud store lock: $error',
        stackTrace: stackTrace,
        tag: _logTag,
        data: <String, dynamic>{
          'storeUuid': storeUuid,
          'errorType': error.runtimeType.toString(),
        },
      );
      return Failure(appError);
    }
  }

  AsyncResultDart<Unit, AppError> releaseLock({
    required String tokenId,
    required CloudStoreLockDto lock,
  }) async {
    try {
      final remoteLock = await _repository.readStoreLockFile(
        tokenId,
        storeUuid: lock.storeUuid,
      );
      if (remoteLock == null) {
        logDebug(
          'Cloud store lock file is already absent.',
          tag: _logTag,
          data: _lockLogData(lock),
        );
        return const Success(unit);
      }

      if (!_isSameLock(remoteLock, lock)) {
        logWarning(
          'Skipping cloud store lock release because remote lock is owned by another app instance.',
          tag: _logTag,
          data: <String, dynamic>{
            ..._lockLogData(lock),
            'remoteLockId': remoteLock.lockId,
            'remoteDeviceId': remoteLock.deviceId,
            'remoteAppInstanceId': remoteLock.appInstanceId,
          },
        );
        return const Success(unit);
      }

      await _repository.deleteStoreLockFile(tokenId, storeUuid: lock.storeUuid);
      logInfo(
        'Cloud store lock released.',
        tag: _logTag,
        data: _lockLogData(lock),
      );
      return const Success(unit);
    } catch (error, stackTrace) {
      final appError = _mapFailure(
        error,
        stackTrace,
        code: 'release_lock_failed',
        message: 'Не удалось удалить cloud lock хранилища',
        storeUuid: lock.storeUuid,
      );
      logError(
        'Failed to release cloud store lock: $error',
        stackTrace: stackTrace,
        tag: _logTag,
        data: <String, dynamic>{
          'storeUuid': lock.storeUuid,
          'lockId': lock.lockId,
          'errorType': error.runtimeType.toString(),
        },
      );
      return Failure(appError);
    }
  }

  Future<CloudStoreLockDto> _buildLocalLock(String storeUuid) async {
    final deviceInfo = await _deviceInfoLoader();
    final packageInfo = await _packageInfoLoader();
    final now = _now().toIso8601String();
    return CloudStoreLockDto(
      storeUuid: storeUuid,
      deviceId: deviceInfo.deviceId,
      deviceName: _deviceName(deviceInfo),
      appInstanceId: _buildAppInstanceId(deviceInfo, packageInfo),
      createdAt: now,
      updatedAt: now,
      lockId: _lockIdGenerator?.call() ?? _uuid.v4(),
      appVersion: packageInfo.version,
      platform: deviceInfo.platform,
    );
  }

  bool _isOwnedByCurrentInstance(
    CloudStoreLockDto remoteLock,
    CloudStoreLockDto localLock,
  ) {
    return remoteLock.storeUuid == localLock.storeUuid &&
        remoteLock.deviceId == localLock.deviceId &&
        remoteLock.appInstanceId == localLock.appInstanceId;
  }

  bool _isSameLock(CloudStoreLockDto remoteLock, CloudStoreLockDto localLock) {
    return _isOwnedByCurrentInstance(remoteLock, localLock) &&
        remoteLock.lockId == localLock.lockId;
  }

  bool _isStale(CloudStoreLockDto lock) {
    final updatedAt = DateTime.tryParse(lock.updatedAt);
    if (updatedAt == null) {
      return false;
    }
    return _now().difference(updatedAt.toUtc()) > _staleLockTtl;
  }

  String _deviceName(logger_models.DeviceInfo deviceInfo) {
    final model = deviceInfo.deviceModel.trim();
    if (model.isNotEmpty) {
      return model;
    }
    final manufacturer = deviceInfo.deviceManufacturer.trim();
    if (manufacturer.isNotEmpty) {
      return manufacturer;
    }
    return deviceInfo.platform;
  }

  String _buildAppInstanceId(
    logger_models.DeviceInfo deviceInfo,
    PackageInfo packageInfo,
  ) {
    return '${deviceInfo.deviceId}:${packageInfo.packageName}';
  }

  Map<String, dynamic> _lockLogData(CloudStoreLockDto lock) {
    return <String, dynamic>{
      'storeUuid': lock.storeUuid,
      'deviceId': lock.deviceId,
      'deviceName': lock.deviceName,
      'appInstanceId': lock.appInstanceId,
      'lockId': lock.lockId,
      'updatedAt': lock.updatedAt,
    };
  }

  AppError _mapFailure(
    Object error,
    StackTrace stackTrace, {
    required String code,
    required String message,
    required String storeUuid,
  }) {
    if (error is AppError) {
      return error;
    }
    return AppError.feature(
      feature: _feature,
      code: code,
      message: message,
      data: <String, dynamic>{
        'storeUuid': storeUuid,
        'errorType': error.runtimeType.toString(),
      },
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
