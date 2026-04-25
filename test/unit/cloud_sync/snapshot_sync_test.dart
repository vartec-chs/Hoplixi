import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hoplixi/core/logger/models.dart' as logger_models;
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/store_snapshot_manifest_builder.dart';
import 'package:hoplixi/main_db/core/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_db/old/models/store_manifest.dart';
import 'package:hoplixi/main_db/old/models/store_key_config.dart';
import 'package:hoplixi/main_db/old/services/store_manifest_service.dart';

void main() {
  group('StoreManifest.fromJson', () {
    test('reads legacy manifest shape', () {
      final manifest = StoreManifest.fromJson(<String, dynamic>{
        'version': 1,
        'storeId': 'legacy-store',
        'lastModified': 1735689600000,
      });

      expect(manifest.storeUuid, 'legacy-store');
      expect(manifest.revision, 0);
      expect(manifest.updatedAt.toUtc().year, 2025);
    });
  });

  group('compareStoreManifests', () {
    test('returns remoteMissing when remote manifest is absent', () {
      final local = _manifest(revision: 5);

      expect(
        compareStoreManifests(local: local, remote: null),
        StoreVersionCompareResult.remoteMissing,
      );
    });

    test('returns differentStore when store identifiers differ', () {
      final local = _manifest(revision: 5, storeUuid: 'store-1');
      final remote = _manifest(revision: 5, storeUuid: 'store-2');

      expect(
        compareStoreManifests(local: local, remote: remote),
        StoreVersionCompareResult.differentStore,
      );
    });

    test('returns localNewer when local revision is greater', () {
      final local = _manifest(revision: 6);
      final remote = _manifest(revision: 5, snapshotId: 'snapshot-5');

      expect(
        compareStoreManifests(local: local, remote: remote),
        StoreVersionCompareResult.localNewer,
      );
    });

    test('returns remoteNewer when remote revision is greater', () {
      final local = _manifest(revision: 5);
      final remote = _manifest(revision: 6, snapshotId: 'snapshot-6');

      expect(
        compareStoreManifests(local: local, remote: remote),
        StoreVersionCompareResult.remoteNewer,
      );
    });

    test('returns same when snapshot identifiers match', () {
      final local = _manifest(revision: 5, snapshotId: 'shared-snapshot');
      final remote = _manifest(
        revision: 5,
        snapshotId: 'shared-snapshot',
        dbHash: 'different-db',
      );

      expect(
        compareStoreManifests(local: local, remote: remote),
        StoreVersionCompareResult.same,
      );
    });

    test('returns same when content signatures match', () {
      final local = _manifest(revision: 5, snapshotId: 'local-snapshot');
      final remote = _manifest(revision: 5, snapshotId: 'remote-snapshot');

      expect(
        compareStoreManifests(local: local, remote: remote),
        StoreVersionCompareResult.same,
      );
    });

    test('returns conflict when revision matches but content differs', () {
      final local = _manifest(revision: 5, snapshotId: 'local-snapshot');
      final remote = _manifest(
        revision: 5,
        snapshotId: 'remote-snapshot',
        dbHash: 'different-db',
      );

      expect(
        compareStoreManifests(local: local, remote: remote),
        StoreVersionCompareResult.conflict,
      );
    });
  });

  group('StoreSnapshotManifestBuilder', () {
    test('ignores attachments_decrypted and persists manifests', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'hoplixi_sync_test_',
      );
      final storeDir = Directory('${tempDir.path}/demo_store')..createSync();
      final attachmentsDir = Directory('${storeDir.path}/attachments')
        ..createSync(recursive: true);
      final decryptedDir = Directory('${storeDir.path}/attachments_decrypted')
        ..createSync(recursive: true);

      final dbFile = File('${storeDir.path}/demo_store.hplxdb')
        ..writeAsStringSync('encrypted_db');
      final attachmentFile = File('${attachmentsDir.path}/file-1.enc')
        ..writeAsStringSync('encrypted_attachment');
      final ignoredFile = File('${decryptedDir.path}/plain.txt')
        ..writeAsStringSync('plain_attachment');
      await StoreManifestService.writeTo(storeDir.path, _manifest(revision: 0));

      final builder = StoreSnapshotManifestBuilder(
        deviceInfoLoader: () async => logger_models.DeviceInfo(
          deviceId: 'device-1',
          platform: 'test',
          platformVersion: '1',
          deviceModel: 'model',
          deviceManufacturer: 'manufacturer',
          appName: 'Hoplixi',
          appVersion: '1.0.0',
          buildNumber: '1',
          packageName: 'hoplixi',
          additionalInfo: const <String, dynamic>{},
        ),
        packageInfoLoader: () async => PackageInfo(
          appName: 'Hoplixi',
          packageName: 'hoplixi',
          version: '1.0.0',
          buildNumber: '1',
        ),
      );

      final snapshot = await builder.buildAndPersist(
        storePath: storeDir.path,
        storeInfo: StoreInfoDto(
          id: 'store-1',
          name: 'Demo Store',
          createdAt: DateTime.utc(2025, 1, 1),
          modifiedAt: DateTime.utc(2025, 1, 2),
          lastOpenedAt: DateTime.utc(2025, 1, 2),
          version: '1',
        ),
      );

      expect(dbFile.existsSync(), isTrue);
      expect(attachmentFile.existsSync(), isTrue);
      expect(ignoredFile.existsSync(), isTrue);
      expect(snapshot.attachmentsManifest.files, hasLength(1));
      expect(snapshot.attachmentsManifest.files.first.fileName, 'file-1.enc');
      expect(snapshot.storeManifest.content.attachments.count, 1);
      expect(snapshot.storeManifest.revision, 1);
      expect(snapshot.storeManifest.lastMigrationVersion, 2);
      expect(snapshot.storeManifest.appVersion, '1.0.0');
      expect(snapshot.storeManifest.keyConfig?.argon2Salt, 'salt');
      expect(File('${storeDir.path}/store_manifest.json').existsSync(), isTrue);
      expect(
        File('${storeDir.path}/attachments_manifest.json').existsSync(),
        isTrue,
      );

      await tempDir.delete(recursive: true);
    });
  });
}

StoreManifest _manifest({
  required int revision,
  String storeUuid = 'store-1',
  String snapshotId = '',
  String dbHash = 'db-hash',
  String filesHash = 'files-hash',
  String? manifestSha256,
}) {
  return StoreManifest(
    storeUuid: storeUuid,
    storeName: 'Store',
    revision: revision,
    updatedAt: DateTime.utc(2025, 1, 1),
    snapshotId: snapshotId,
    lastModifiedBy: const StoreManifestLastModifiedBy(
      deviceId: 'device',
      clientInstanceId: 'client',
      appVersion: '1.0.0',
    ),
    keyConfig: const StoreKeyConfig(argon2Salt: 'salt', useDeviceKey: false),
    content: StoreManifestContent(
      dbFile: StoreManifestDbFileContent(
        fileName: 'store.hplxdb',
        size: 10,
        sha256: dbHash,
      ),
      attachments: StoreManifestAttachmentsContent(
        count: 1,
        totalSize: 2,
        manifestSha256: manifestSha256 ?? filesHash,
        filesHash: filesHash,
      ),
    ),
  );
}
