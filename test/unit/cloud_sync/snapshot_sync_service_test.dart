import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/attachments_manifest.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_manifest.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/attachments_manifest_file_service.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/snapshot_sync_repository.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/snapshot_sync_service.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/store_snapshot_manifest_builder.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_file.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_folder.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_list_page.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_move_copy_target.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_kind.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_ref.dart';
import 'package:hoplixi/features/cloud_sync/storage/services/cloud_storage_provider.dart';
import 'package:hoplixi/features/cloud_sync/storage/services/cloud_storage_repository.dart';
import 'package:hoplixi/db_core/models/dto/main_store_dto.dart';
import 'package:hoplixi/db_core/models/store_manifest.dart';
import 'package:hoplixi/db_core/services/store_manifest_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late List<Directory> tempDirs;
  late StoreInfoDto storeInfo;
  late StoreSyncBinding binding;

  setUp(() {
    tempDirs = <Directory>[];
    storeInfo = StoreInfoDto(
      id: 'store-1',
      name: 'Demo Store',
      createdAt: DateTime.utc(2025, 1, 1),
      modifiedAt: DateTime.utc(2025, 1, 2),
      lastOpenedAt: DateTime.utc(2025, 1, 2),
      version: '1',
    );
    binding = StoreSyncBinding(
      storeUuid: 'store-1',
      tokenId: 'token-1',
      provider: CloudSyncProvider.dropbox,
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 1, 2),
    );
  });

  tearDown(() async {
    for (final directory in tempDirs) {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  });

  group('SnapshotSyncService.sync', () {
    test(
      'syncWithProgress emits ordered upload stages and terminal result',
      () async {
        final fixture = await _createStoreFixture(tempDirs);
        final localSnapshot = _localSnapshot(
          fixture,
          manifest: _manifest(revision: 2, snapshotId: 'local'),
        );
        final repository = _FakeSnapshotSyncRepository();
        final service = SnapshotSyncService(
          repository: repository,
          manifestBuilder: _FakeManifestBuilder(localSnapshot),
        );

        final events = await service
            .syncWithProgress(
              storePath: fixture.storeDir.path,
              storeInfo: storeInfo,
              binding: binding,
            )
            .toList();

        expect(_orderedStages(events), <SnapshotSyncStage>[
          SnapshotSyncStage.preparingLocalSnapshot,
          SnapshotSyncStage.checkingRemoteVersion,
          SnapshotSyncStage.transferringPrimaryFiles,
          SnapshotSyncStage.syncingAttachments,
          SnapshotSyncStage.updatingMetadata,
          SnapshotSyncStage.completed,
        ]);
        expect(
          (events.last as SnapshotSyncProgressResult).result.type,
          SnapshotSyncResultType.uploaded,
        );
      },
    );

    test(
      'syncWithProgress emits ordered download stages and terminal result',
      () async {
        final fixture = await _createStoreFixture(tempDirs);
        final localSnapshot = _localSnapshot(
          fixture,
          manifest: _manifest(revision: 1, snapshotId: 'local'),
        );
        final repository = _FakeSnapshotSyncRepository()
          ..remoteStoreManifest = _manifest(revision: 2, snapshotId: 'remote')
          ..remoteAttachmentsManifest = _attachmentsManifest(
            files: <AttachmentManifestEntry>[_attachmentEntry('remote.enc')],
          )
          ..onDownloadRemoteStoreFiles = (localStorePath) async {
            await File(
              p.join(localStorePath, 'store.hplxdb'),
            ).writeAsString('db');
          };
        final service = SnapshotSyncService(
          repository: repository,
          manifestBuilder: _FakeManifestBuilder(localSnapshot),
        );

        final events = await service
            .syncWithProgress(
              storePath: fixture.storeDir.path,
              storeInfo: storeInfo,
              binding: binding,
            )
            .toList();

        expect(_orderedStages(events), <SnapshotSyncStage>[
          SnapshotSyncStage.preparingLocalSnapshot,
          SnapshotSyncStage.checkingRemoteVersion,
          SnapshotSyncStage.transferringPrimaryFiles,
          SnapshotSyncStage.syncingAttachments,
          SnapshotSyncStage.updatingMetadata,
          SnapshotSyncStage.completed,
        ]);
        expect(
          (events.last as SnapshotSyncProgressResult).result.type,
          SnapshotSyncResultType.downloaded,
        );
      },
    );

    test(
      'syncWithProgress completes after remote check when there are no changes',
      () async {
        final fixture = await _createStoreFixture(tempDirs);
        final localSnapshot = _localSnapshot(
          fixture,
          manifest: _manifest(revision: 2, snapshotId: 'shared'),
        );
        final repository = _FakeSnapshotSyncRepository()
          ..remoteStoreManifest = _manifest(
            revision: 2,
            snapshotId: 'shared',
            dbHash: 'other-db',
          );
        final service = SnapshotSyncService(
          repository: repository,
          manifestBuilder: _FakeManifestBuilder(localSnapshot),
        );

        final events = await service
            .syncWithProgress(
              storePath: fixture.storeDir.path,
              storeInfo: storeInfo,
              binding: binding,
            )
            .toList();

        expect(_orderedStages(events), <SnapshotSyncStage>[
          SnapshotSyncStage.preparingLocalSnapshot,
          SnapshotSyncStage.checkingRemoteVersion,
          SnapshotSyncStage.completed,
        ]);
        expect(
          (events.last as SnapshotSyncProgressResult).result.type,
          SnapshotSyncResultType.noChanges,
        );
      },
    );

    test(
      'syncWithProgress completes after remote check when conflict is detected',
      () async {
        final fixture = await _createStoreFixture(tempDirs);
        final localSnapshot = _localSnapshot(
          fixture,
          manifest: _manifest(revision: 2, snapshotId: 'local'),
        );
        final repository = _FakeSnapshotSyncRepository()
          ..remoteStoreManifest = _manifest(
            revision: 2,
            snapshotId: 'remote',
            dbHash: 'other-db',
          );
        final service = SnapshotSyncService(
          repository: repository,
          manifestBuilder: _FakeManifestBuilder(localSnapshot),
        );

        final events = await service
            .syncWithProgress(
              storePath: fixture.storeDir.path,
              storeInfo: storeInfo,
              binding: binding,
            )
            .toList();

        expect(_orderedStages(events), <SnapshotSyncStage>[
          SnapshotSyncStage.preparingLocalSnapshot,
          SnapshotSyncStage.checkingRemoteVersion,
          SnapshotSyncStage.completed,
        ]);
        expect(
          (events.last as SnapshotSyncProgressResult).result.type,
          SnapshotSyncResultType.conflict,
        );
      },
    );

    test('uploads when remote manifest is missing', () async {
      final fixture = await _createStoreFixture(tempDirs);
      final localSnapshot = _localSnapshot(
        fixture,
        manifest: _manifest(revision: 2, snapshotId: 'local'),
      );
      final repository = _FakeSnapshotSyncRepository();
      final service = SnapshotSyncService(
        repository: repository,
        manifestBuilder: _FakeManifestBuilder(localSnapshot),
      );

      final result = await service.sync(
        storePath: fixture.storeDir.path,
        storeInfo: storeInfo,
        binding: binding,
      );

      expect(result.type, SnapshotSyncResultType.uploaded);
      expect(repository.uploadStoreFilesCalls, 1);
      expect(repository.reconcileAttachmentsUploadCalls, 1);
      expect(repository.uploadedStoreManifest?.baseRevision, isNull);
      final persistedManifest = await StoreManifestService.readFrom(
        fixture.storeDir.path,
      );
      expect(persistedManifest?.sync?.provider, CloudSyncProvider.dropbox);
      expect(persistedManifest?.sync?.remotePath, isNotEmpty);
    });

    test('uploads when local manifest is newer', () async {
      final fixture = await _createStoreFixture(tempDirs);
      final localSnapshot = _localSnapshot(
        fixture,
        manifest: _manifest(revision: 3, snapshotId: 'local'),
      );
      final repository = _FakeSnapshotSyncRepository()
        ..remoteStoreManifest = _manifest(revision: 2, snapshotId: 'remote');
      final service = SnapshotSyncService(
        repository: repository,
        manifestBuilder: _FakeManifestBuilder(localSnapshot),
      );

      final result = await service.sync(
        storePath: fixture.storeDir.path,
        storeInfo: storeInfo,
        binding: binding,
      );

      expect(result.type, SnapshotSyncResultType.uploaded);
      expect(repository.uploadedStoreManifest?.baseRevision, 2);
      expect(repository.uploadStoreFilesCalls, 1);
    });

    test('downloads when remote manifest is newer', () async {
      final fixture = await _createStoreFixture(tempDirs);
      final localSnapshot = _localSnapshot(
        fixture,
        manifest: _manifest(revision: 1, snapshotId: 'local'),
      );
      final remoteAttachments = _attachmentsManifest(
        files: <AttachmentManifestEntry>[_attachmentEntry('remote.enc')],
      );
      final repository = _FakeSnapshotSyncRepository()
        ..remoteStoreManifest = _manifest(revision: 2, snapshotId: 'remote')
        ..remoteAttachmentsManifest = remoteAttachments
        ..onDownloadRemoteStoreFiles = (localStorePath) async {
          await File(
            p.join(localStorePath, 'store.hplxdb'),
          ).writeAsString('db');
        };
      final service = SnapshotSyncService(
        repository: repository,
        manifestBuilder: _FakeManifestBuilder(localSnapshot),
      );

      final result = await service.sync(
        storePath: fixture.storeDir.path,
        storeInfo: storeInfo,
        binding: binding,
      );

      expect(result.type, SnapshotSyncResultType.downloaded);
      expect(result.localManifest?.sync?.provider, CloudSyncProvider.dropbox);
      expect(repository.downloadRemoteStoreFilesCalls, 1);
      expect(repository.reconcileAttachmentsDownloadCalls, 1);
      final attachmentsManifest = await AttachmentsManifestFileService.readFrom(
        fixture.storeDir.path,
      );
      expect(attachmentsManifest?.files.map((file) => file.fileName), [
        'remote.enc',
      ]);
    });

    test(
      'returns noChanges when manifests match by snapshot identifier',
      () async {
        final fixture = await _createStoreFixture(tempDirs);
        final localSnapshot = _localSnapshot(
          fixture,
          manifest: _manifest(revision: 2, snapshotId: 'shared'),
        );
        final repository = _FakeSnapshotSyncRepository()
          ..remoteStoreManifest = _manifest(
            revision: 2,
            snapshotId: 'shared',
            dbHash: 'other-db',
          );
        final service = SnapshotSyncService(
          repository: repository,
          manifestBuilder: _FakeManifestBuilder(localSnapshot),
        );

        final result = await service.sync(
          storePath: fixture.storeDir.path,
          storeInfo: storeInfo,
          binding: binding,
        );

        expect(result.type, SnapshotSyncResultType.noChanges);
        expect(repository.uploadStoreFilesCalls, 0);
        expect(repository.downloadRemoteStoreFilesCalls, 0);
      },
    );

    test('returns conflict when manifests diverge on same revision', () async {
      final fixture = await _createStoreFixture(tempDirs);
      final localSnapshot = _localSnapshot(
        fixture,
        manifest: _manifest(revision: 2, snapshotId: 'local'),
      );
      final repository = _FakeSnapshotSyncRepository()
        ..remoteStoreManifest = _manifest(
          revision: 2,
          snapshotId: 'remote',
          dbHash: 'other-db',
        );
      final service = SnapshotSyncService(
        repository: repository,
        manifestBuilder: _FakeManifestBuilder(localSnapshot),
      );

      final result = await service.sync(
        storePath: fixture.storeDir.path,
        storeInfo: storeInfo,
        binding: binding,
      );

      expect(result.type, SnapshotSyncResultType.conflict);
      expect(result.conflict, isNotNull);
      expect(repository.uploadStoreFilesCalls, 0);
      expect(repository.downloadRemoteStoreFilesCalls, 0);
    });

    test('throws when compared manifests belong to different stores', () async {
      final fixture = await _createStoreFixture(tempDirs);
      final localSnapshot = _localSnapshot(
        fixture,
        manifest: _manifest(revision: 2, storeUuid: 'store-1'),
      );
      final repository = _FakeSnapshotSyncRepository()
        ..remoteStoreManifest = _manifest(revision: 2, storeUuid: 'store-2');
      final service = SnapshotSyncService(
        repository: repository,
        manifestBuilder: _FakeManifestBuilder(localSnapshot),
      );

      await expectLater(
        () => service.sync(
          storePath: fixture.storeDir.path,
          storeInfo: storeInfo,
          binding: binding,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('SnapshotSyncService.resolveConflict', () {
    test('reuses upload pipeline for uploadLocal resolution', () async {
      final fixture = await _createStoreFixture(tempDirs);
      final localSnapshot = _localSnapshot(
        fixture,
        manifest: _manifest(revision: 2, snapshotId: 'local'),
      );
      final repository = _FakeSnapshotSyncRepository()
        ..remoteStoreManifest = _manifest(
          revision: 2,
          snapshotId: 'remote',
          dbHash: 'other-db',
        );
      final service = SnapshotSyncService(
        repository: repository,
        manifestBuilder: _FakeManifestBuilder(localSnapshot),
      );

      final result = await service.resolveConflict(
        storePath: fixture.storeDir.path,
        storeInfo: storeInfo,
        binding: binding,
        resolution: SnapshotConflictResolution.uploadLocal,
      );

      expect(result.type, SnapshotSyncResultType.uploaded);
      expect(repository.uploadStoreFilesCalls, 1);
      expect(repository.downloadRemoteStoreFilesCalls, 0);
    });

    test('reuses download pipeline for downloadRemote resolution', () async {
      final fixture = await _createStoreFixture(tempDirs);
      final localSnapshot = _localSnapshot(
        fixture,
        manifest: _manifest(revision: 2, snapshotId: 'local'),
      );
      final repository = _FakeSnapshotSyncRepository()
        ..remoteStoreManifest = _manifest(revision: 3, snapshotId: 'remote')
        ..onDownloadRemoteStoreFiles = (localStorePath) async {
          await File(
            p.join(localStorePath, 'store.hplxdb'),
          ).writeAsString('db');
        };
      final service = SnapshotSyncService(
        repository: repository,
        manifestBuilder: _FakeManifestBuilder(localSnapshot),
      );

      final result = await service.resolveConflict(
        storePath: fixture.storeDir.path,
        storeInfo: storeInfo,
        binding: binding,
        resolution: SnapshotConflictResolution.downloadRemote,
        lockBeforeDownload: true,
      );

      expect(result.type, SnapshotSyncResultType.downloaded);
      expect(result.requiresUnlockToApply, isTrue);
      expect(repository.downloadRemoteStoreFilesCalls, 1);
      expect(repository.uploadStoreFilesCalls, 0);
    });
  });

  group('SnapshotSyncService.importRemoteStoreToLocal', () {
    test(
      'cleans temporary directory when import fails after directory creation',
      () async {
        final baseDir = await Directory.systemTemp.createTemp(
          'hoplixi_snapshot_import_',
        );
        tempDirs.add(baseDir);
        final repository = _FakeSnapshotSyncRepository()
          ..remoteStoreManifest = _manifest(
            revision: 3,
            snapshotId: 'remote',
            storeName: 'Imported Store',
          );
        final service = SnapshotSyncService(
          repository: repository,
          manifestBuilder: _FakeManifestBuilder(
            _localSnapshot(
              await _createStoreFixture(tempDirs),
              manifest: _manifest(revision: 1),
            ),
          ),
        );

        await expectLater(
          () => service.importRemoteStoreToLocal(
            tokenId: binding.tokenId,
            storeUuid: binding.storeUuid,
            baseStoragePath: baseDir.path,
          ),
          throwsA(isA<StateError>()),
        );

        expect(await baseDir.list().toList(), isEmpty);
      },
    );
  });

  group('SnapshotSyncService.deleteRemoteSnapshot', () {
    test(
      'deletes remote store folder and marks cloud manifest entry deleted',
      () async {
        final repository = _FakeSnapshotSyncRepository()
          ..cloudManifest = CloudManifest(
            version: 1,
            updatedAt: DateTime.utc(2025, 1, 1),
            stores: <CloudManifestStoreEntry>[
              CloudManifestStoreEntry(
                storeUuid: 'store-1',
                storeName: 'Store',
                revision: 3,
                updatedAt: DateTime.utc(2025, 1, 2),
                snapshotId: 'remote',
                remoteStoreId: 'remote-store-1',
                remotePath: '/Hoplixi/stores/store-1',
              ),
            ],
          );
        final service = SnapshotSyncService(repository: repository);

        await service.deleteRemoteSnapshot(
          tokenId: binding.tokenId,
          entry: repository.cloudManifest!.stores.single,
        );

        expect(repository.deletedRemoteStoreUuid, 'store-1');
        expect(repository.deletedRemoteStorePath, '/Hoplixi/stores/store-1');
        expect(repository.writtenCloudManifest, isNotNull);
        expect(repository.writtenCloudManifest!.stores.single.deleted, isTrue);
      },
    );
  });
}

class _FakeManifestBuilder implements StoreSnapshotManifestBuilder {
  _FakeManifestBuilder(this.snapshot);

  final LocalStoreSnapshot snapshot;
  int buildCalls = 0;

  @override
  Future<LocalStoreSnapshot> buildAndPersist({
    required String storePath,
    required StoreInfoDto storeInfo,
    bool persist = true,
    bool allowRevisionBump = true,
  }) async {
    buildCalls += 1;
    return snapshot;
  }
}

class _FakeSnapshotSyncRepository extends SnapshotSyncRepository {
  _FakeSnapshotSyncRepository() : super(_UnusedCloudStorageRepository());

  StoreManifest? remoteStoreManifest;
  AttachmentsManifest? remoteAttachmentsManifest;
  CloudManifest? cloudManifest;
  CloudManifest? writtenCloudManifest;
  String? deletedRemoteStoreUuid;
  String? deletedRemoteStorePath;
  StoreManifest? uploadedStoreManifest;
  AttachmentsManifest? uploadedAttachmentsManifest;
  int downloadRemoteStoreFilesCalls = 0;
  int reconcileAttachmentsDownloadCalls = 0;
  int uploadStoreFilesCalls = 0;
  int reconcileAttachmentsUploadCalls = 0;
  Future<void> Function(String localStorePath)? onDownloadRemoteStoreFiles;

  @override
  Future<RemoteStoreLayout> ensureRemoteStoreLayout(
    String tokenId,
    String storeUuid,
  ) async {
    return _remoteLayout(storeUuid);
  }

  @override
  Future<StoreManifest?> readRemoteStoreManifest(
    String tokenId, {
    required String storeUuid,
    RemoteStoreLayout? layout,
  }) async {
    return remoteStoreManifest;
  }

  @override
  Future<AttachmentsManifest?> readRemoteAttachmentsManifest(
    String tokenId, {
    required String storeUuid,
    RemoteStoreLayout? layout,
  }) async {
    return remoteAttachmentsManifest;
  }

  @override
  Future<void> downloadRemoteStoreFiles(
    String tokenId, {
    required String storeUuid,
    required String localStorePath,
    RemoteStoreLayout? layout,
    SnapshotSyncTransferProgressCallback? onProgress,
  }) async {
    downloadRemoteStoreFilesCalls += 1;
    onProgress?.call(
      const SnapshotSyncTransferProgress(
        direction: SnapshotSyncTransferDirection.download,
        completedFiles: 0,
        totalFiles: 1,
        transferredBytes: 3,
        totalBytes: 3,
        currentFileName: 'store.hplxdb',
      ),
    );
    await onDownloadRemoteStoreFiles?.call(localStorePath);
  }

  @override
  Future<void> reconcileAttachmentsDownload(
    String tokenId, {
    required String storeUuid,
    required Directory localAttachmentsDir,
    required AttachmentsManifest remoteManifest,
    RemoteStoreLayout? layout,
    SnapshotSyncTransferProgressCallback? onProgress,
  }) async {
    reconcileAttachmentsDownloadCalls += 1;
    await localAttachmentsDir.create(recursive: true);
    onProgress?.call(
      SnapshotSyncTransferProgress(
        direction: SnapshotSyncTransferDirection.download,
        completedFiles: 0,
        totalFiles: remoteManifest.files.length,
        transferredBytes: 1,
        totalBytes: remoteManifest.files.length,
        currentFileName: remoteManifest.files.isEmpty
            ? null
            : remoteManifest.files.first.fileName,
      ),
    );
    for (final entry in remoteManifest.files.where((file) => !file.deleted)) {
      await File(
        p.join(localAttachmentsDir.path, entry.fileName),
      ).writeAsString(entry.fileName);
    }
  }

  @override
  Future<void> uploadStoreFiles(
    String tokenId, {
    required String storeUuid,
    required File dbFile,
    File? keyFile,
    RemoteStoreLayout? layout,
    SnapshotSyncTransferProgressCallback? onProgress,
  }) async {
    uploadStoreFilesCalls += 1;
    onProgress?.call(
      const SnapshotSyncTransferProgress(
        direction: SnapshotSyncTransferDirection.upload,
        completedFiles: 0,
        totalFiles: 1,
        transferredBytes: 2,
        totalBytes: 2,
        currentFileName: 'store.hplxdb',
      ),
    );
  }

  @override
  Future<void> reconcileAttachmentsUpload(
    String tokenId, {
    required String storeUuid,
    required Directory localAttachmentsDir,
    required AttachmentsManifest localManifest,
    required AttachmentsManifest? remoteManifest,
    RemoteStoreLayout? layout,
    SnapshotSyncTransferProgressCallback? onProgress,
  }) async {
    reconcileAttachmentsUploadCalls += 1;
    onProgress?.call(
      SnapshotSyncTransferProgress(
        direction: SnapshotSyncTransferDirection.upload,
        completedFiles: 0,
        totalFiles: localManifest.files.length,
        transferredBytes: 1,
        totalBytes: localManifest.files.length,
        currentFileName: localManifest.files.isEmpty
            ? null
            : localManifest.files.first.fileName,
      ),
    );
  }

  @override
  Future<void> uploadAttachmentsManifest(
    String tokenId, {
    required String storeUuid,
    required AttachmentsManifest manifest,
    RemoteStoreLayout? layout,
  }) async {
    uploadedAttachmentsManifest = manifest;
  }

  @override
  Future<void> uploadStoreManifest(
    String tokenId, {
    required String storeUuid,
    required StoreManifest manifest,
    RemoteStoreLayout? layout,
  }) async {
    uploadedStoreManifest = manifest;
  }

  @override
  Future<CloudManifest?> readCloudManifest(String tokenId) async {
    return cloudManifest;
  }

  @override
  Future<void> writeCloudManifest(
    String tokenId,
    CloudManifest manifest,
  ) async {
    writtenCloudManifest = manifest;
  }

  @override
  Future<void> deleteRemoteStoreFolder(
    String tokenId, {
    required String storeUuid,
    String? remoteStoreId,
    String? remotePath,
    bool permanent = true,
  }) async {
    deletedRemoteStoreUuid = storeUuid;
    deletedRemoteStorePath = remotePath;
  }
}

class _UnusedCloudStorageRepository implements CloudStorageRepository {
  @override
  Future<CloudStorageProvider> providerForToken(String tokenId) {
    throw UnimplementedError();
  }

  @override
  Future<CloudResource> getResource(String tokenId, CloudResourceRef ref) {
    throw UnimplementedError();
  }

  @override
  Future<CloudListPage> listFolder(
    String tokenId,
    CloudResourceRef folderRef, {
    String? cursor,
    int? pageSize,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CloudFolder> createFolder(
    String tokenId, {
    required CloudResourceRef parentRef,
    required String name,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CloudFile> uploadFile(
    String tokenId, {
    required CloudResourceRef parentRef,
    required String name,
    required Stream<List<int>> dataStream,
    required int contentLength,
    String? contentType,
    bool overwrite = false,
    dynamic onProgress,
    dynamic cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> downloadFile(
    String tokenId, {
    required CloudResourceRef fileRef,
    String? savePath,
    StreamConsumer<List<int>>? responseSink,
    dynamic onProgress,
    dynamic cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CloudResource> copyResource(
    String tokenId, {
    required CloudResourceRef sourceRef,
    required CloudMoveCopyTarget target,
    bool overwrite = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CloudResource> moveResource(
    String tokenId, {
    required CloudResourceRef sourceRef,
    required CloudMoveCopyTarget target,
    bool overwrite = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteResource(
    String tokenId,
    CloudResourceRef ref, {
    bool permanent = true,
  }) {
    throw UnimplementedError();
  }
}

Future<_StoreFixture> _createStoreFixture(List<Directory> tempDirs) async {
  final root = await Directory.systemTemp.createTemp(
    'hoplixi_snapshot_service_',
  );
  tempDirs.add(root);
  final storeDir = Directory(p.join(root.path, 'store'))..createSync();
  final attachmentsDir = Directory(p.join(storeDir.path, 'attachments'))
    ..createSync(recursive: true);
  final dbFile = File(p.join(storeDir.path, 'store.hplxdb'))
    ..writeAsStringSync('db');
  final keyFile = File(p.join(storeDir.path, 'store_key.json'))
    ..writeAsStringSync('{}');
  final attachmentFile = File(p.join(attachmentsDir.path, 'local.enc'))
    ..writeAsStringSync('attachment');

  return _StoreFixture(
    root: root,
    storeDir: storeDir,
    attachmentsDir: attachmentsDir,
    dbFile: dbFile,
    keyFile: keyFile,
    attachmentFile: attachmentFile,
  );
}

LocalStoreSnapshot _localSnapshot(
  _StoreFixture fixture, {
  required StoreManifest manifest,
}) {
  return LocalStoreSnapshot(
    storeManifest: manifest,
    attachmentsManifest: _attachmentsManifest(
      files: <AttachmentManifestEntry>[_attachmentEntry('local.enc')],
    ),
    dbFile: fixture.dbFile,
    keyFile: fixture.keyFile,
  );
}

RemoteStoreLayout _remoteLayout(String storeUuid) {
  return RemoteStoreLayout(
    rootFolder: _folder('Hoplixi', '/Hoplixi'),
    storesFolder: _folder('stores', '/Hoplixi/stores'),
    storeFolder: _folder(
      storeUuid,
      '/Hoplixi/stores/$storeUuid',
      resourceId: 'remote-$storeUuid',
    ),
    attachmentsFolder: _folder(
      'attachments',
      '/Hoplixi/stores/$storeUuid/attachments',
    ),
  );
}

CloudResource _folder(String name, String path, {String? resourceId}) {
  return CloudResource(
    ref: CloudResourceRef(
      provider: CloudSyncProvider.dropbox,
      resourceId: resourceId,
      path: path,
    ),
    provider: CloudSyncProvider.dropbox,
    kind: CloudResourceKind.folder,
    name: name,
  );
}

AttachmentsManifest _attachmentsManifest({
  required List<AttachmentManifestEntry> files,
}) {
  return AttachmentsManifest(
    version: 1,
    storeUuid: 'store-1',
    revision: 1,
    updatedAt: DateTime.utc(2025, 1, 1),
    filesHash: 'files-hash',
    files: files,
  );
}

AttachmentManifestEntry _attachmentEntry(
  String fileName, {
  bool deleted = false,
}) {
  return AttachmentManifestEntry(
    fileName: fileName,
    size: 1,
    sha256: 'sha-$fileName',
    updatedAt: DateTime.utc(2025, 1, 1),
    deleted: deleted,
  );
}

List<SnapshotSyncStage> _orderedStages(List<SnapshotSyncProgressEvent> events) {
  return events
      .whereType<SnapshotSyncProgressUpdate>()
      .map((event) => event.progress.stage)
      .fold<List<SnapshotSyncStage>>(<SnapshotSyncStage>[], (stages, stage) {
        if (stages.isEmpty || stages.last != stage) {
          stages.add(stage);
        }
        return stages;
      });
}

StoreManifest _manifest({
  required int revision,
  String storeUuid = 'store-1',
  String storeName = 'Store',
  String snapshotId = '',
  String dbHash = 'db-hash',
  String keyHash = 'key-hash',
  String filesHash = 'files-hash',
}) {
  return StoreManifest(
    storeUuid: storeUuid,
    storeName: storeName,
    revision: revision,
    updatedAt: DateTime.utc(2025, 1, 1),
    snapshotId: snapshotId,
    lastModifiedBy: const StoreManifestLastModifiedBy(
      deviceId: 'device',
      clientInstanceId: 'client',
      appVersion: '1.0.0',
    ),
    content: StoreManifestContent(
      dbFile: StoreManifestDbFileContent(
        fileName: 'store.hplxdb',
        size: 10,
        sha256: dbHash,
      ),
      keyFile: StoreManifestKeyFileContent(sha256: keyHash, size: 5),
      attachments: StoreManifestAttachmentsContent(
        count: 1,
        totalSize: 1,
        manifestSha256: filesHash,
        filesHash: filesHash,
      ),
    ),
  );
}

class _StoreFixture {
  const _StoreFixture({
    required this.root,
    required this.storeDir,
    required this.attachmentsDir,
    required this.dbFile,
    required this.keyFile,
    required this.attachmentFile,
  });

  final Directory root;
  final Directory storeDir;
  final Directory attachmentsDir;
  final File dbFile;
  final File keyFile;
  final File attachmentFile;
}
