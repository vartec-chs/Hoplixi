import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/attachments_manifest.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/snapshot_sync_repository.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_file.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_folder.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_list_page.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_move_copy_target.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_kind.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_metadata.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_ref.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';
import 'package:hoplixi/features/cloud_sync/storage/services/cloud_storage_provider.dart';
import 'package:hoplixi/features/cloud_sync/storage/services/cloud_storage_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  late List<Directory> tempDirs;

  setUp(() {
    tempDirs = <Directory>[];
  });

  tearDown(() async {
    for (final directory in tempDirs) {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  });

  test(
    'reconcileAttachmentsDownload lists remote files once, downloads expected files and removes stale locals',
    () async {
      final storage = _FakeCloudStorageRepository();
      storage.seedFiles('/Hoplixi/stores/store-1/attachments', <CloudResource>[
        _fileResource('keep.enc', sizeBytes: 4),
        _fileResource('download.enc', sizeBytes: 8),
      ]);
      final repository = SnapshotSyncRepository(storage);
      final localDir = await Directory.systemTemp.createTemp(
        'hoplixi_snapshot_repo_download_',
      );
      tempDirs.add(localDir);
      await File(p.join(localDir.path, 'stale.enc')).writeAsString('stale');
      final progressEvents = <SnapshotSyncTransferProgress>[];

      await repository.reconcileAttachmentsDownload(
        'token-1',
        storeUuid: 'store-1',
        localAttachmentsDir: localDir,
        remoteManifest: _attachmentsManifest(
          files: <AttachmentManifestEntry>[
            _entry('keep.enc'),
            _entry('download.enc'),
          ],
        ),
        onProgress: progressEvents.add,
      );

      expect(storage.listFolderCalls, 1);
      expect(storage.getResourceCalls, 0);
      expect(storage.downloadedFileNames, <String>['keep.enc', 'download.enc']);
      expect(File(p.join(localDir.path, 'stale.enc')).existsSync(), isFalse);
      expect(File(p.join(localDir.path, 'keep.enc')).existsSync(), isTrue);
      expect(File(p.join(localDir.path, 'download.enc')).existsSync(), isTrue);
      expect(progressEvents.last.completedFiles, 2);
      expect(progressEvents.last.totalFiles, 2);
      expect(progressEvents.last.transferredBytes, 12);
    },
  );

  test(
    'reconcileAttachmentsUpload lists remote files once, uploads changed files and deletes stale remote files',
    () async {
      final storage = _FakeCloudStorageRepository();
      storage.seedFiles('/Hoplixi/stores/store-1/attachments', <CloudResource>[
        _fileResource('keep.enc', sizeBytes: 4),
        _fileResource('stale.enc', sizeBytes: 5),
      ]);
      final repository = SnapshotSyncRepository(storage);
      final localDir = await Directory.systemTemp.createTemp(
        'hoplixi_snapshot_repo_upload_',
      );
      tempDirs.add(localDir);
      await File(p.join(localDir.path, 'keep.enc')).writeAsString('keep');
      await File(p.join(localDir.path, 'upload.enc')).writeAsString('upload');
      final progressEvents = <SnapshotSyncTransferProgress>[];

      await repository.reconcileAttachmentsUpload(
        'token-1',
        storeUuid: 'store-1',
        localAttachmentsDir: localDir,
        localManifest: _attachmentsManifest(
          files: <AttachmentManifestEntry>[
            _entry('keep.enc', sha256: 'same-sha'),
            _entry('upload.enc', sha256: 'new-sha'),
          ],
        ),
        remoteManifest: _attachmentsManifest(
          files: <AttachmentManifestEntry>[
            _entry('keep.enc', sha256: 'same-sha'),
            _entry('stale.enc', sha256: 'old-sha'),
          ],
        ),
        onProgress: progressEvents.add,
      );

      expect(storage.listFolderCalls, 1);
      expect(storage.getResourceCalls, 0);
      expect(storage.uploadedFileNames, <String>['upload.enc']);
      expect(storage.deletedPaths, <String>[
        '/Hoplixi/stores/store-1/attachments/stale.enc',
      ]);
      expect(progressEvents.last.completedFiles, 1);
      expect(progressEvents.last.totalFiles, 1);
      expect(progressEvents.last.transferredBytes, 6);
    },
  );

  test(
    'uploadStoreFiles reports aggregate progress for primary files',
    () async {
      final storage = _FakeCloudStorageRepository();
      final repository = SnapshotSyncRepository(storage);
      final localDir = await Directory.systemTemp.createTemp(
        'hoplixi_snapshot_repo_store_upload_',
      );
      tempDirs.add(localDir);
      final dbFile = await File(
        p.join(localDir.path, 'store.hplxdb'),
      ).writeAsString('1234');
      final progressEvents = <SnapshotSyncTransferProgress>[];

      await repository.uploadStoreFiles(
        'token-1',
        storeUuid: 'store-1',
        dbFile: dbFile,
        onProgress: progressEvents.add,
      );

      expect(storage.uploadedFileNames, <String>['store.hplxdb']);
      expect(progressEvents.last.completedFiles, 1);
      expect(progressEvents.last.totalFiles, 1);
      expect(progressEvents.last.transferredBytes, 4);
      expect(progressEvents.last.totalBytes, 4);
    },
  );

  test(
    'downloadRemoteStoreFiles reports aggregate progress for primary files',
    () async {
      final storage = _FakeCloudStorageRepository();
      storage.seedFiles('/Hoplixi/stores/store-1', <CloudResource>[
        _fileResource(
          'store.hplxdb',
          path: '/Hoplixi/stores/store-1/store.hplxdb',
          sizeBytes: 5,
        ),
        _fileResource(
          'store_manifest.json',
          path: '/Hoplixi/stores/store-1/store_manifest.json',
          sizeBytes: 10,
        ),
      ]);
      final repository = SnapshotSyncRepository(storage);
      final localDir = await Directory.systemTemp.createTemp(
        'hoplixi_snapshot_repo_store_download_',
      );
      tempDirs.add(localDir);
      final progressEvents = <SnapshotSyncTransferProgress>[];

      await repository.downloadRemoteStoreFiles(
        'token-1',
        storeUuid: 'store-1',
        localStorePath: localDir.path,
        onProgress: progressEvents.add,
      );

      expect(storage.downloadedFileNames, <String>['store.hplxdb']);
      expect(progressEvents.last.completedFiles, 1);
      expect(progressEvents.last.totalFiles, 1);
      expect(progressEvents.last.transferredBytes, 5);
      expect(progressEvents.last.totalBytes, 5);
    },
  );

  test(
    'readCloudManifest falls back to folder listing when Dropbox direct lookup reports network error',
    () async {
      final storage = _FakeCloudStorageRepository();
      storage.failGetResource(
        '/Hoplixi/cloud_manifest.json',
        CloudStorageException(
          type: CloudStorageExceptionType.network,
          message: 'Cloud request failed due to a network error.',
          provider: CloudSyncProvider.dropbox,
          requestUri: Uri.parse(
            'https://api.dropboxapi.com/2/files/get_metadata',
          ),
        ),
      );
      final repository = SnapshotSyncRepository(storage);

      final manifest = await repository.readCloudManifest('token-1');

      expect(manifest, isNull);
      expect(storage.getResourceCalls, 2);
      expect(storage.listFolderCalls, 1);
    },
  );
}

class _FakeCloudStorageRepository implements CloudStorageRepository {
  final _provider = const _StaticCloudStorageProvider();
  final Map<String, CloudResource> _resources = <String, CloudResource>{};
  final Map<String, List<CloudResource>> _children =
      <String, List<CloudResource>>{};
  final Map<String, CloudStorageException> _getResourceFailures =
      <String, CloudStorageException>{};

  int listFolderCalls = 0;
  int getResourceCalls = 0;
  final List<String> downloadedFileNames = <String>[];
  final List<String> uploadedFileNames = <String>[];
  final List<String> deletedPaths = <String>[];

  void seedFiles(String parentPath, List<CloudResource> files) {
    _children[parentPath] = List<CloudResource>.from(files);
    for (final file in files) {
      _resources[file.ref.path!] = file;
    }
  }

  void failGetResource(String path, CloudStorageException error) {
    _getResourceFailures[path] = error;
  }

  @override
  Future<CloudStorageProvider> providerForToken(String tokenId) async =>
      _provider;

  @override
  Future<CloudResource> getResource(
    String tokenId,
    CloudResourceRef ref,
  ) async {
    getResourceCalls += 1;
    final failure = ref.path == null ? null : _getResourceFailures[ref.path!];
    if (failure != null) {
      throw failure;
    }
    final resource = _resources[ref.path];
    if (resource == null) {
      final path = ref.path;
      if (path != null) {
        return CloudResource(
          ref: CloudResourceRef(
            provider: CloudSyncProvider.dropbox,
            path: path,
            resourceId: path,
          ),
          provider: CloudSyncProvider.dropbox,
          kind: CloudResourceKind.folder,
          name: p.posix.basename(path),
        );
      }
      throw StateError('Missing resource for ${ref.path}.');
    }
    return resource;
  }

  @override
  Future<CloudListPage> listFolder(
    String tokenId,
    CloudResourceRef folderRef, {
    String? cursor,
    int? pageSize,
  }) async {
    listFolderCalls += 1;
    return CloudListPage(
      items: _children[folderRef.path] ?? const <CloudResource>[],
    );
  }

  @override
  Future<CloudFolder> createFolder(
    String tokenId, {
    required CloudResourceRef parentRef,
    required String name,
  }) async {
    final parentPath = parentRef.path ?? '';
    final path = parentPath.isEmpty ? '/$name' : '$parentPath/$name';
    final resource =
        _resources[path] ??
        CloudResource(
          ref: CloudResourceRef(
            provider: CloudSyncProvider.dropbox,
            path: path,
            resourceId: path,
          ),
          provider: CloudSyncProvider.dropbox,
          kind: CloudResourceKind.folder,
          name: name,
        );
    _resources[path] = resource;
    _children.putIfAbsent(path, () => <CloudResource>[]);
    return CloudFolder(resource);
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
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    await dataStream.drain<void>();
    uploadedFileNames.add(name);
    onProgress?.call(contentLength, contentLength);
    final parentPath = parentRef.path ?? '';
    final path = '$parentPath/$name';
    final resource = _fileResource(name, path: path, sizeBytes: contentLength);
    _resources[path] = resource;
    _children.putIfAbsent(parentPath, () => <CloudResource>[]);
    _children[parentPath]!.removeWhere((entry) => entry.name == name);
    _children[parentPath]!.add(resource);
    return CloudFile(resource);
  }

  @override
  Future<void> downloadFile(
    String tokenId, {
    required CloudResourceRef fileRef,
    String? savePath,
    StreamConsumer<List<int>>? responseSink,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    downloadedFileNames.add(p.basename(fileRef.path ?? ''));
    final resource = fileRef.path == null ? null : _resources[fileRef.path!];
    final fileSize =
        resource?.metadata.sizeBytes ?? p.basename(fileRef.path ?? '').length;
    onProgress?.call(fileSize, fileSize);
    if (savePath != null) {
      await File(savePath).writeAsString(p.basename(savePath));
    }
    if (responseSink != null) {
      await responseSink.addStream(
        Stream<List<int>>.value(p.basename(fileRef.path ?? '').codeUnits),
      );
      await responseSink.close();
    }
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
  }) async {
    deletedPaths.add(ref.path ?? '');
    final path = ref.path;
    if (path == null) {
      return;
    }
    _resources.remove(path);
    final parentPath = p.posix.dirname(path);
    _children[parentPath]?.removeWhere((entry) => entry.ref.path == path);
  }
}

class _StaticCloudStorageProvider implements CloudStorageProvider {
  const _StaticCloudStorageProvider();

  @override
  CloudSyncProvider get provider => CloudSyncProvider.dropbox;

  @override
  Future<CloudResource> getResource(CloudResourceRef ref) {
    throw UnimplementedError();
  }

  @override
  Future<CloudListPage> listFolder(
    CloudResourceRef folderRef, {
    String? cursor,
    int? pageSize,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CloudFolder> createFolder({
    required CloudResourceRef parentRef,
    required String name,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CloudFile> uploadFile({
    required CloudResourceRef parentRef,
    required String name,
    required Stream<List<int>> dataStream,
    required int contentLength,
    String? contentType,
    bool overwrite = false,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> downloadFile({
    required CloudResourceRef fileRef,
    String? savePath,
    StreamConsumer<List<int>>? responseSink,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CloudResource> copyResource({
    required CloudResourceRef sourceRef,
    required CloudMoveCopyTarget target,
    bool overwrite = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CloudResource> moveResource({
    required CloudResourceRef sourceRef,
    required CloudMoveCopyTarget target,
    bool overwrite = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteResource(CloudResourceRef ref, {bool permanent = true}) {
    throw UnimplementedError();
  }
}

CloudResource _fileResource(String name, {String? path, int? sizeBytes}) {
  final resolvedPath = path ?? '/Hoplixi/stores/store-1/attachments/$name';
  return CloudResource(
    ref: CloudResourceRef(
      provider: CloudSyncProvider.dropbox,
      path: resolvedPath,
      resourceId: resolvedPath,
    ),
    provider: CloudSyncProvider.dropbox,
    kind: CloudResourceKind.file,
    name: name,
    metadata: CloudResourceMetadata(sizeBytes: sizeBytes),
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

AttachmentManifestEntry _entry(String fileName, {String sha256 = 'sha'}) {
  return AttachmentManifestEntry(
    fileName: fileName,
    size: 1,
    sha256: sha256,
    updatedAt: DateTime.utc(2025, 1, 1),
  );
}
