import 'package:hoplixi/core/logger/models.dart' as logger_models;
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_store_lock.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/cloud_store_lock_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:test/test.dart';

void main() {
  group('CloudStoreLockService', () {
    late _FakeRemoteStore remoteStore;
    late DateTime now;
    late CloudStoreLockService service;

    setUp(() {
      remoteStore = _FakeRemoteStore();
      now = DateTime.utc(2026, 5, 8, 10);
      service = CloudStoreLockService(
        repository: remoteStore,
        lockIdGenerator: () => 'local-lock-id',
        deviceInfoLoader: () async => _deviceInfo(
          deviceId: 'device-a',
          deviceName: 'Workstation A',
        ),
        packageInfoLoader: () async => _packageInfo(),
        now: () => now,
      );
    });

    test('returns syncDisabled without touching remote store', () async {
      final result = await service.acquireLock(
        tokenId: 'token-1',
        storeUuid: 'store-1',
        syncEnabled: false,
      );

      expect(result.isSuccess(), isTrue);
      expect(
        result.getOrThrow().status,
        CloudStoreLockAcquireStatus.syncDisabled,
      );
      expect(remoteStore.readCount, 0);
      expect(remoteStore.writeCount, 0);
    });

    test('creates a lock when remote lock file is absent', () async {
      final result = await service.acquireLock(
        tokenId: 'token-1',
        storeUuid: 'store-1',
        syncEnabled: true,
      );

      expect(result.isSuccess(), isTrue);
      final acquire = result.getOrThrow();
      expect(acquire.status, CloudStoreLockAcquireStatus.acquired);
      expect(remoteStore.lock?.lockId, 'local-lock-id');
      expect(remoteStore.lock?.deviceId, 'device-a');
      expect(remoteStore.writeCount, 1);
    });

    test('refreshes an existing lock owned by this app instance', () async {
      remoteStore.lock = _lock(
        storeUuid: 'store-1',
        deviceId: 'device-a',
        appInstanceId: 'device-a:dev.hoplixi.test',
        lockId: 'existing-lock-id',
        updatedAt: DateTime.utc(2026, 5, 8, 9),
      );
      now = DateTime.utc(2026, 5, 8, 11);

      final result = await service.acquireLock(
        tokenId: 'token-1',
        storeUuid: 'store-1',
        syncEnabled: true,
      );

      expect(result.isSuccess(), isTrue);
      final acquire = result.getOrThrow();
      expect(acquire.status, CloudStoreLockAcquireStatus.alreadyOwned);
      expect(remoteStore.lock?.lockId, 'existing-lock-id');
      expect(remoteStore.lock?.updatedAt, now.toIso8601String());
    });

    test('returns lockedByAnotherDevice for active foreign lock', () async {
      remoteStore.lock = _lock(
        storeUuid: 'store-1',
        deviceId: 'device-b',
        appInstanceId: 'device-b:dev.hoplixi.test',
        lockId: 'foreign-lock-id',
        updatedAt: now.subtract(const Duration(hours: 1)),
      );

      final result = await service.acquireLock(
        tokenId: 'token-1',
        storeUuid: 'store-1',
        syncEnabled: true,
      );

      expect(result.isSuccess(), isTrue);
      final acquire = result.getOrThrow();
      expect(acquire.status, CloudStoreLockAcquireStatus.lockedByAnotherDevice);
      expect(acquire.conflictingLock?.lockId, 'foreign-lock-id');
      expect(remoteStore.lock?.lockId, 'foreign-lock-id');
    });

    test('replaces foreign lock older than 24 hours', () async {
      remoteStore.lock = _lock(
        storeUuid: 'store-1',
        deviceId: 'device-b',
        appInstanceId: 'device-b:dev.hoplixi.test',
        lockId: 'stale-lock-id',
        updatedAt: now.subtract(const Duration(hours: 25)),
      );

      final result = await service.acquireLock(
        tokenId: 'token-1',
        storeUuid: 'store-1',
        syncEnabled: true,
      );

      expect(result.isSuccess(), isTrue);
      final acquire = result.getOrThrow();
      expect(acquire.status, CloudStoreLockAcquireStatus.staleReplaced);
      expect(acquire.conflictingLock?.lockId, 'stale-lock-id');
      expect(remoteStore.lock?.lockId, 'local-lock-id');
    });

    test('does not delete lock owned by another app instance', () async {
      final localLock = _lock(
        storeUuid: 'store-1',
        deviceId: 'device-a',
        appInstanceId: 'device-a:dev.hoplixi.test',
        lockId: 'local-lock-id',
        updatedAt: now,
      );
      remoteStore.lock = _lock(
        storeUuid: 'store-1',
        deviceId: 'device-b',
        appInstanceId: 'device-b:dev.hoplixi.test',
        lockId: 'foreign-lock-id',
        updatedAt: now,
      );

      final result = await service.releaseLock(
        tokenId: 'token-1',
        lock: localLock,
      );

      expect(result.isSuccess(), isTrue);
      expect(remoteStore.lock?.lockId, 'foreign-lock-id');
      expect(remoteStore.deleteCount, 0);
    });
  });
}

class _FakeRemoteStore implements CloudStoreLockRemoteStore {
  CloudStoreLockDto? lock;
  int readCount = 0;
  int writeCount = 0;
  int deleteCount = 0;

  @override
  Future<CloudStoreLockDto?> readStoreLockFile(
    String tokenId, {
    required String storeUuid,
  }) async {
    readCount += 1;
    return lock;
  }

  @override
  Future<void> writeStoreLockFile(
    String tokenId, {
    required String storeUuid,
    required CloudStoreLockDto lock,
  }) async {
    writeCount += 1;
    this.lock = lock;
  }

  @override
  Future<void> deleteStoreLockFile(
    String tokenId, {
    required String storeUuid,
  }) async {
    deleteCount += 1;
    lock = null;
  }
}

logger_models.DeviceInfo _deviceInfo({
  required String deviceId,
  required String deviceName,
}) {
  return logger_models.DeviceInfo(
    deviceId: deviceId,
    platform: 'windows',
    platformVersion: '11',
    deviceModel: deviceName,
    deviceManufacturer: 'ACME',
    appName: 'Hoplixi',
    appVersion: '1.2.3',
    buildNumber: '42',
    packageName: 'dev.hoplixi.test',
    additionalInfo: const <String, dynamic>{},
  );
}

PackageInfo _packageInfo() {
  return PackageInfo(
    appName: 'Hoplixi',
    packageName: 'dev.hoplixi.test',
    version: '1.2.3',
    buildNumber: '42',
    buildSignature: '',
    installerStore: null,
  );
}

CloudStoreLockDto _lock({
  required String storeUuid,
  required String deviceId,
  required String appInstanceId,
  required String lockId,
  required DateTime updatedAt,
}) {
  return CloudStoreLockDto(
    storeUuid: storeUuid,
    deviceId: deviceId,
    deviceName: deviceId,
    appInstanceId: appInstanceId,
    createdAt: updatedAt.toIso8601String(),
    updatedAt: updatedAt.toIso8601String(),
    lockId: lockId,
    appVersion: '1.2.3',
    platform: 'windows',
  );
}
