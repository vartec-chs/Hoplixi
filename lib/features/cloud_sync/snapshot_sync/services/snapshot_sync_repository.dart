import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/attachments_manifest.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_manifest.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_store_lock.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/utils/remote_store_layout.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/utils/snapshot_sync_utils.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_ref.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';
import 'package:hoplixi/features/cloud_sync/storage/services/cloud_storage_repository.dart';
import 'package:hoplixi/main_db/services/store_manifest_service/model/store_manifest.dart';
import 'package:path/path.dart' as p;

class SnapshotSyncRepository implements CloudStoreLockRemoteStore {
  SnapshotSyncRepository(this._storageRepository);

  static const String rootFolderName = 'Hoplixi';
  static const String storesFolderName = 'stores';
  static const String cloudManifestFileName = 'cloud_manifest.json';
  static const String storeManifestFileName = 'store_manifest.json';
  static const String attachmentsManifestFileName = 'attachments_manifest.json';
  static const String attachmentsFolderName = 'attachments';
  static const String storeLockFileName = '.lock';

  final CloudStorageRepository _storageRepository;
  final Map<String, RemoteStoreLayout> _layoutCache =
      <String, RemoteStoreLayout>{};
  final Map<String, CloudResource> _folderCache = <String, CloudResource>{};

  Future<CloudManifest?> readCloudManifest(String tokenId) async {
    try {
      final provider = await _storageRepository.providerForToken(tokenId);
      final root = await _findChildFolderByName(
        tokenId,
        parentRef: SnapshotSyncUtils.rootRefForProvider(provider.provider),
        name: rootFolderName,
      );
      if (root == null) {
        return null;
      }
      final file = await _findChildFileByName(
        tokenId,
        parentRef: root.ref,
        name: cloudManifestFileName,
      );
      if (file == null) {
        return null;
      }

      final bytes = await _downloadBytes(tokenId, file.ref);
      return CloudManifest.fromJson(
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
      );
    } on CloudStorageException catch (error) {
      if (error.type == CloudStorageExceptionType.notFound) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<CloudStoreLockDto?> readStoreLockFile(
    String tokenId, {
    required String storeUuid,
    RemoteStoreLayout? layout,
  }) async {
    final resolvedLayout = await _resolveLayout(
      tokenId,
      storeUuid: storeUuid,
      layout: layout,
    );
    final file = await _findChildFileByName(
      tokenId,
      parentRef: resolvedLayout.storeFolder.ref,
      name: storeLockFileName,
    );
    if (file == null) {
      return null;
    }

    final bytes = await _downloadBytes(tokenId, file.ref);
    return CloudStoreLockDto.fromJson(
      jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> writeStoreLockFile(
    String tokenId, {
    required String storeUuid,
    required CloudStoreLockDto lock,
    RemoteStoreLayout? layout,
  }) async {
    final resolvedLayout = await _resolveLayout(
      tokenId,
      storeUuid: storeUuid,
      layout: layout,
    );
    await _uploadBytes(
      tokenId,
      parentRef: resolvedLayout.storeFolder.ref,
      name: storeLockFileName,
      bytes: utf8.encode(
        const JsonEncoder.withIndent('  ').convert(lock.toJson()),
      ),
      overwrite: true,
    );
  }

  @override
  Future<void> deleteStoreLockFile(
    String tokenId, {
    required String storeUuid,
    RemoteStoreLayout? layout,
  }) async {
    final resolvedLayout = await _resolveLayout(
      tokenId,
      storeUuid: storeUuid,
      layout: layout,
    );
    final file = await _findChildFileByName(
      tokenId,
      parentRef: resolvedLayout.storeFolder.ref,
      name: storeLockFileName,
    );
    if (file == null) {
      return;
    }
    await _storageRepository.deleteResource(tokenId, file.ref);
  }

  Future<void> writeCloudManifest(
    String tokenId,
    CloudManifest manifest,
  ) async {
    final root = await _ensureRootFolder(tokenId);
    await _uploadBytes(
      tokenId,
      parentRef: root.ref,
      name: cloudManifestFileName,
      bytes: utf8.encode(
        const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      ),
      overwrite: true,
    );
  }

  Future<RemoteStoreLayout> ensureRemoteStoreLayout(
    String tokenId,
    String storeUuid,
  ) async {
    final cachedLayout =
        _layoutCache[SnapshotSyncUtils.layoutCacheKey(tokenId, storeUuid)];
    if (cachedLayout != null) {
      return cachedLayout;
    }

    final rootFolder = await _ensureRootFolder(tokenId);
    final storesFolder = await _ensureChildFolder(
      tokenId,
      parentRef: rootFolder.ref,
      name: storesFolderName,
    );
    final storeFolder = await _ensureChildFolder(
      tokenId,
      parentRef: storesFolder.ref,
      name: storeUuid,
    );
    final attachmentsFolder = await _ensureChildFolder(
      tokenId,
      parentRef: storeFolder.ref,
      name: attachmentsFolderName,
    );

    final layout = RemoteStoreLayout(
      rootFolder: rootFolder,
      storesFolder: storesFolder,
      storeFolder: storeFolder,
      attachmentsFolder: attachmentsFolder,
    );
    _layoutCache[SnapshotSyncUtils.layoutCacheKey(tokenId, storeUuid)] = layout;
    return layout;
  }

  Future<CloudResource?> findRemoteStoreFolder(
    String tokenId, {
    required String storeUuid,
    String? remoteStoreId,
    String? remotePath,
  }) async {
    final provider = await _storageRepository.providerForToken(tokenId);
    final knownRef = SnapshotSyncUtils.remoteStoreRefFromKnownLocation(
      provider.provider,
      remoteStoreId: remoteStoreId,
      remotePath: remotePath,
    );
    if (knownRef != null) {
      try {
        final resource = await _storageRepository.getResource(
          tokenId,
          knownRef,
        );
        return resource.isFolder ? resource : null;
      } on CloudStorageException catch (error) {
        if (error.type != CloudStorageExceptionType.notFound) {
          rethrow;
        }
      }
    }

    final rootFolder = await _ensureRootFolder(tokenId);
    final storesFolder = await _ensureChildFolder(
      tokenId,
      parentRef: rootFolder.ref,
      name: storesFolderName,
    );
    return _findChildFolderByName(
      tokenId,
      parentRef: storesFolder.ref,
      name: storeUuid,
    );
  }

  Future<void> deleteRemoteStoreFolder(
    String tokenId, {
    required String storeUuid,
    String? remoteStoreId,
    String? remotePath,
    bool permanent = true,
  }) async {
    final storeFolder = await findRemoteStoreFolder(
      tokenId,
      storeUuid: storeUuid,
      remoteStoreId: remoteStoreId,
      remotePath: remotePath,
    );
    if (storeFolder == null) {
      _invalidateStoreCaches(tokenId, storeUuid);
      return;
    }

    await _storageRepository.deleteResource(
      tokenId,
      storeFolder.ref,
      permanent: permanent,
    );
    _invalidateStoreCaches(tokenId, storeUuid);
  }

  Future<StoreManifest?> readRemoteStoreManifest(
    String tokenId, {
    required String storeUuid,
    RemoteStoreLayout? layout,
  }) async {
    final resolvedLayout = await _resolveLayout(
      tokenId,
      storeUuid: storeUuid,
      layout: layout,
    );
    final file = await _findChildFileByName(
      tokenId,
      parentRef: resolvedLayout.storeFolder.ref,
      name: storeManifestFileName,
    );
    if (file == null) {
      return null;
    }

    final bytes = await _downloadBytes(tokenId, file.ref);
    return StoreManifest.fromJson(
      jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
    );
  }

  Future<AttachmentsManifest?> readRemoteAttachmentsManifest(
    String tokenId, {
    required String storeUuid,
    RemoteStoreLayout? layout,
  }) async {
    final resolvedLayout = await _resolveLayout(
      tokenId,
      storeUuid: storeUuid,
      layout: layout,
    );
    final file = await _findChildFileByName(
      tokenId,
      parentRef: resolvedLayout.storeFolder.ref,
      name: attachmentsManifestFileName,
    );
    if (file == null) {
      return null;
    }

    final bytes = await _downloadBytes(tokenId, file.ref);
    return AttachmentsManifest.fromJson(
      jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
    );
  }

  Future<void> uploadStoreManifest(
    String tokenId, {
    required String storeUuid,
    required StoreManifest manifest,
    RemoteStoreLayout? layout,
  }) async {
    final resolvedLayout = await _resolveLayout(
      tokenId,
      storeUuid: storeUuid,
      layout: layout,
    );
    await _uploadBytes(
      tokenId,
      parentRef: resolvedLayout.storeFolder.ref,
      name: storeManifestFileName,
      bytes: utf8.encode(
        const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      ),
      overwrite: true,
    );
  }

  Future<void> uploadAttachmentsManifest(
    String tokenId, {
    required String storeUuid,
    required AttachmentsManifest manifest,
    RemoteStoreLayout? layout,
  }) async {
    final resolvedLayout = await _resolveLayout(
      tokenId,
      storeUuid: storeUuid,
      layout: layout,
    );
    await _uploadBytes(
      tokenId,
      parentRef: resolvedLayout.storeFolder.ref,
      name: attachmentsManifestFileName,
      bytes: utf8.encode(
        const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      ),
      overwrite: true,
    );
  }

  Future<void> uploadStoreFiles(
    String tokenId, {
    required String storeUuid,
    required File dbFile,
    RemoteStoreLayout? layout,
    SnapshotSyncTransferProgressCallback? onProgress,
  }) async {
    final resolvedLayout = await _resolveLayout(
      tokenId,
      storeUuid: storeUuid,
      layout: layout,
    );

    final uploads = <({File file, String name, int size})>[
      (
        file: dbFile,
        name: p.basename(dbFile.path),
        size: await dbFile.length(),
      ),
    ];

    final totalBytes = uploads.fold<int>(0, (sum, entry) => sum + entry.size);
    var completedFiles = 0;
    var completedBytes = 0;

    for (final upload in uploads) {
      _emitTransferProgress(
        onProgress,
        direction: SnapshotSyncTransferDirection.upload,
        completedFiles: completedFiles,
        totalFiles: uploads.length,
        transferredBytes: completedBytes,
        totalBytes: totalBytes,
        currentFileName: upload.name,
      );
      await _uploadFile(
        tokenId,
        parentRef: resolvedLayout.storeFolder.ref,
        file: upload.file,
        name: upload.name,
        onProgress: (current, total) {
          _emitTransferProgress(
            onProgress,
            direction: SnapshotSyncTransferDirection.upload,
            completedFiles: completedFiles,
            totalFiles: uploads.length,
            transferredBytes:
                completedBytes +
                SnapshotSyncUtils.resolveTransferredBytes(
                  current,
                  reportedTotal: total,
                  fallbackTotal: upload.size,
                ),
            totalBytes: totalBytes,
            currentFileName: upload.name,
          );
        },
      );
      completedFiles += 1;
      completedBytes += upload.size;
      _emitTransferProgress(
        onProgress,
        direction: SnapshotSyncTransferDirection.upload,
        completedFiles: completedFiles,
        totalFiles: uploads.length,
        transferredBytes: completedBytes,
        totalBytes: totalBytes,
      );
    }
  }

  Future<void> reconcileAttachmentsUpload(
    String tokenId, {
    required String storeUuid,
    required Directory localAttachmentsDir,
    required AttachmentsManifest localManifest,
    required AttachmentsManifest? remoteManifest,
    RemoteStoreLayout? layout,
    SnapshotSyncTransferProgressCallback? onProgress,
  }) async {
    final resolvedLayout = await _resolveLayout(
      tokenId,
      storeUuid: storeUuid,
      layout: layout,
    );
    final remoteFiles = <String, AttachmentManifestEntry>{
      for (final entry
          in remoteManifest?.files ?? const <AttachmentManifestEntry>[])
        entry.fileName: entry,
    };
    final remoteResources = await _listRemoteFilesByName(
      tokenId,
      resolvedLayout.attachmentsFolder.ref,
    );
    final uploads = <({AttachmentManifestEntry entry, File file, int size})>[];

    for (final entry in localManifest.files.where((file) => !file.deleted)) {
      final remote = remoteFiles.remove(entry.fileName);
      if (remote != null &&
          remote.sha256 == entry.sha256 &&
          remote.size == entry.size) {
        continue;
      }

      final localFile = File(p.join(localAttachmentsDir.path, entry.fileName));
      if (!await localFile.exists()) {
        continue;
      }
      uploads.add((
        entry: entry,
        file: localFile,
        size: await localFile.length(),
      ));
    }

    final totalBytes = uploads.fold<int>(0, (sum, item) => sum + item.size);
    var completedFiles = 0;
    var completedBytes = 0;
    for (final upload in uploads) {
      _emitTransferProgress(
        onProgress,
        direction: SnapshotSyncTransferDirection.upload,
        completedFiles: completedFiles,
        totalFiles: uploads.length,
        transferredBytes: completedBytes,
        totalBytes: totalBytes,
        currentFileName: upload.entry.fileName,
      );
      await _uploadFile(
        tokenId,
        parentRef: resolvedLayout.attachmentsFolder.ref,
        file: upload.file,
        name: upload.entry.fileName,
        onProgress: (current, total) {
          _emitTransferProgress(
            onProgress,
            direction: SnapshotSyncTransferDirection.upload,
            completedFiles: completedFiles,
            totalFiles: uploads.length,
            transferredBytes:
                completedBytes +
                SnapshotSyncUtils.resolveTransferredBytes(
                  current,
                  reportedTotal: total,
                  fallbackTotal: upload.size,
                ),
            totalBytes: totalBytes,
            currentFileName: upload.entry.fileName,
          );
        },
      );
      completedFiles += 1;
      completedBytes += upload.size;
      _emitTransferProgress(
        onProgress,
        direction: SnapshotSyncTransferDirection.upload,
        completedFiles: completedFiles,
        totalFiles: uploads.length,
        transferredBytes: completedBytes,
        totalBytes: totalBytes,
      );
    }

    for (final stale in remoteFiles.values.where((file) => !file.deleted)) {
      final remoteFile = remoteResources[stale.fileName];
      if (remoteFile != null) {
        await _storageRepository.deleteResource(tokenId, remoteFile.ref);
      }
    }
  }

  Future<void> downloadRemoteStoreFiles(
    String tokenId, {
    required String storeUuid,
    required String localStorePath,
    RemoteStoreLayout? layout,
    SnapshotSyncTransferProgressCallback? onProgress,
  }) async {
    final resolvedLayout = await _resolveLayout(
      tokenId,
      storeUuid: storeUuid,
      layout: layout,
    );
    final items = await _listAll(tokenId, resolvedLayout.storeFolder.ref);
    final files = items
        .where(
          (item) =>
              item.isFile &&
              item.name != attachmentsManifestFileName &&
              item.name != storeManifestFileName,
        )
        .toList(growable: false);
    final totalBytes = files.any((file) => file.metadata.sizeBytes == null)
        ? null
        : files.fold<int>(0, (sum, file) => sum + file.metadata.sizeBytes!);
    var completedFiles = 0;
    var completedBytes = 0;

    for (final resource in files) {
      final destination = p.join(localStorePath, resource.name);
      var transferredForCurrentFile = 0;
      _emitTransferProgress(
        onProgress,
        direction: SnapshotSyncTransferDirection.download,
        completedFiles: completedFiles,
        totalFiles: files.length,
        transferredBytes: completedBytes,
        totalBytes: totalBytes,
        currentFileName: resource.name,
      );
      await _storageRepository.downloadFile(
        tokenId,
        fileRef: resource.ref,
        savePath: destination,
        onProgress: (current, total) {
          transferredForCurrentFile = SnapshotSyncUtils.resolveTransferredBytes(
            current,
            reportedTotal: total,
            fallbackTotal: resource.metadata.sizeBytes,
          );
          _emitTransferProgress(
            onProgress,
            direction: SnapshotSyncTransferDirection.download,
            completedFiles: completedFiles,
            totalFiles: files.length,
            transferredBytes: completedBytes + transferredForCurrentFile,
            totalBytes: totalBytes,
            currentFileName: resource.name,
          );
        },
      );
      completedFiles += 1;
      completedBytes +=
          resource.metadata.sizeBytes ?? transferredForCurrentFile;
      _emitTransferProgress(
        onProgress,
        direction: SnapshotSyncTransferDirection.download,
        completedFiles: completedFiles,
        totalFiles: files.length,
        transferredBytes: completedBytes,
        totalBytes: totalBytes,
      );
    }
  }

  Future<void> reconcileAttachmentsDownload(
    String tokenId, {
    required String storeUuid,
    required Directory localAttachmentsDir,
    required AttachmentsManifest remoteManifest,
    RemoteStoreLayout? layout,
    SnapshotSyncTransferProgressCallback? onProgress,
  }) async {
    final resolvedLayout = await _resolveLayout(
      tokenId,
      storeUuid: storeUuid,
      layout: layout,
    );
    final existingLocalNames = <String>{};
    if (await localAttachmentsDir.exists()) {
      await for (final entity in localAttachmentsDir.list(followLinks: false)) {
        if (entity is File) {
          existingLocalNames.add(p.basename(entity.path));
        }
      }
    } else {
      await localAttachmentsDir.create(recursive: true);
    }

    final remoteResources = await _listRemoteFilesByName(
      tokenId,
      resolvedLayout.attachmentsFolder.ref,
    );
    final remoteFiles = <String>{};
    final downloads =
        <({AttachmentManifestEntry entry, CloudResource resource})>[];
    for (final entry in remoteManifest.files.where((file) => !file.deleted)) {
      remoteFiles.add(entry.fileName);
      final remoteFile = remoteResources[entry.fileName];
      if (remoteFile == null) {
        continue;
      }
      downloads.add((entry: entry, resource: remoteFile));
    }

    final totalBytes =
        downloads.any((item) => item.resource.metadata.sizeBytes == null)
            ? null
            : downloads.fold<int>(
                0,
                (sum, item) => sum + item.resource.metadata.sizeBytes!,
              );
    var completedFiles = 0;
    var completedBytes = 0;

    for (final download in downloads) {
      var transferredForCurrentFile = 0;
      _emitTransferProgress(
        onProgress,
        direction: SnapshotSyncTransferDirection.download,
        completedFiles: completedFiles,
        totalFiles: downloads.length,
        transferredBytes: completedBytes,
        totalBytes: totalBytes,
        currentFileName: download.entry.fileName,
      );
      await _storageRepository.downloadFile(
        tokenId,
        fileRef: download.resource.ref,
        savePath: p.join(localAttachmentsDir.path, download.entry.fileName),
        onProgress: (current, total) {
          transferredForCurrentFile = SnapshotSyncUtils.resolveTransferredBytes(
            current,
            reportedTotal: total,
            fallbackTotal: download.resource.metadata.sizeBytes,
          );
          _emitTransferProgress(
            onProgress,
            direction: SnapshotSyncTransferDirection.download,
            completedFiles: completedFiles,
            totalFiles: downloads.length,
            transferredBytes: completedBytes + transferredForCurrentFile,
            totalBytes: totalBytes,
            currentFileName: download.entry.fileName,
          );
        },
      );
      completedFiles += 1;
      completedBytes +=
          download.resource.metadata.sizeBytes ?? transferredForCurrentFile;
      _emitTransferProgress(
        onProgress,
        direction: SnapshotSyncTransferDirection.download,
        completedFiles: completedFiles,
        totalFiles: downloads.length,
        transferredBytes: completedBytes,
        totalBytes: totalBytes,
      );
    }

    for (final localName in existingLocalNames.difference(remoteFiles)) {
      final localFile = File(p.join(localAttachmentsDir.path, localName));
      if (await localFile.exists()) {
        await localFile.delete();
      }
    }
  }

  Future<RemoteStoreLayout> _resolveLayout(
    String tokenId, {
    required String storeUuid,
    RemoteStoreLayout? layout,
  }) async {
    return layout ?? await ensureRemoteStoreLayout(tokenId, storeUuid);
  }

  Future<Map<String, CloudResource>> _listRemoteFilesByName(
    String tokenId,
    CloudResourceRef parentRef,
  ) async {
    final items = await _listAll(tokenId, parentRef);
    return <String, CloudResource>{
      for (final item in items.where((entry) => entry.isFile)) item.name: item,
    };
  }

  Future<CloudResource> _ensureRootFolder(String tokenId) async {
    final provider = await _storageRepository.providerForToken(tokenId);
    final rootRef = SnapshotSyncUtils.rootRefForProvider(provider.provider);
    return _ensureChildFolder(
      tokenId,
      parentRef: rootRef,
      name: rootFolderName,
    );
  }

  Future<CloudResource> _ensureChildFolder(
    String tokenId, {
    required CloudResourceRef parentRef,
    required String name,
  }) async {
    final cached = _folderCache[
        SnapshotSyncUtils.folderCacheKey(tokenId, parentRef, name)];
    if (cached != null) {
      return cached;
    }

    if (SnapshotSyncUtils.shouldCreateFolderWithoutLookup(parentRef)) {
      try {
        final created = await _storageRepository.createFolder(
          tokenId,
          parentRef: parentRef,
          name: name,
        );
        _cacheFolder(tokenId, parentRef, name, created.resource);
        return created.resource;
      } on CloudStorageException catch (error) {
        if (error.type != CloudStorageExceptionType.alreadyExists) {
          rethrow;
        }
      }
    }

    final existing = await _findChildFolderByName(
      tokenId,
      parentRef: parentRef,
      name: name,
    );
    if (existing != null) {
      _cacheFolder(tokenId, parentRef, name, existing);
      return existing;
    }

    final folder = await _storageRepository.createFolder(
      tokenId,
      parentRef: parentRef,
      name: name,
    );
    _cacheFolder(tokenId, parentRef, name, folder.resource);
    return folder.resource;
  }

  Future<List<CloudResource>> _listAll(
    String tokenId,
    CloudResourceRef parentRef,
  ) async {
    final items = <CloudResource>[];
    String? cursor;
    do {
      final page = await _storageRepository.listFolder(
        tokenId,
        parentRef,
        cursor: cursor,
      );
      items.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    return items;
  }

  Future<CloudResource?> _findChildFolderByName(
    String tokenId, {
    required CloudResourceRef parentRef,
    required String name,
  }) async {
    CloudResource? direct;
    CloudStorageException? directLookupError;
    try {
      direct = await _findChildByDirectPath(
        tokenId,
        parentRef: parentRef,
        name: name,
      );
    } on CloudStorageException catch (error) {
      if (!SnapshotSyncUtils.shouldFallbackToListAfterDirectLookup(
        parentRef.provider,
        error,
      )) {
        rethrow;
      }
      directLookupError = error;
    }
    if (direct != null) {
      return direct.isFolder ? direct : null;
    }
    if (SnapshotSyncUtils.usesDirectPathOnly(parentRef.provider) &&
        directLookupError == null) {
      return null;
    }

    final items = await _listAll(tokenId, parentRef);
    for (final item in items) {
      if (item.isFolder && item.name == name) {
        return item;
      }
    }
    return null;
  }

  Future<CloudResource?> _findChildFileByName(
    String tokenId, {
    required CloudResourceRef parentRef,
    required String name,
  }) async {
    CloudResource? direct;
    CloudStorageException? directLookupError;
    try {
      direct = await _findChildByDirectPath(
        tokenId,
        parentRef: parentRef,
        name: name,
      );
    } on CloudStorageException catch (error) {
      if (!SnapshotSyncUtils.shouldFallbackToListAfterDirectLookup(
        parentRef.provider,
        error,
      )) {
        rethrow;
      }
      directLookupError = error;
    }
    if (direct != null) {
      return direct.isFile ? direct : null;
    }
    if (SnapshotSyncUtils.usesDirectPathOnly(parentRef.provider) &&
        directLookupError == null) {
      return null;
    }

    final items = await _listAll(tokenId, parentRef);
    for (final item in items) {
      if (item.isFile && item.name == name) {
        return item;
      }
    }
    return null;
  }

  Future<CloudResource?> _findChildByDirectPath(
    String tokenId, {
    required CloudResourceRef parentRef,
    required String name,
  }) async {
    final childRef = SnapshotSyncUtils.buildDirectChildRef(parentRef, name);
    if (childRef == null) {
      return null;
    }

    try {
      final resource = await _storageRepository.getResource(tokenId, childRef);
      if (resource.isFolder) {
        _cacheFolder(tokenId, parentRef, name, resource);
      }
      return resource;
    } on CloudStorageException catch (error) {
      if (error.type == CloudStorageExceptionType.notFound) {
        return null;
      }
      rethrow;
    }
  }

  Future<List<int>> _downloadBytes(
    String tokenId,
    CloudResourceRef fileRef,
  ) async {
    final sink = ByteCollectorSink();
    await _storageRepository.downloadFile(
      tokenId,
      fileRef: fileRef,
      responseSink: sink,
    );
    return sink.bytes;
  }

  Future<void> _uploadBytes(
    String tokenId, {
    required CloudResourceRef parentRef,
    required String name,
    required List<int> bytes,
    bool overwrite = true,
  }) async {
    await _storageRepository.uploadFile(
      tokenId,
      parentRef: parentRef,
      name: name,
      dataStream: Stream<List<int>>.value(bytes),
      contentLength: bytes.length,
      overwrite: overwrite,
      contentType: 'application/json',
    );
  }

  Future<void> _uploadFile(
    String tokenId, {
    required CloudResourceRef parentRef,
    required File file,
    required String name,
    ProgressCallback? onProgress,
  }) async {
    await _storageRepository.uploadFile(
      tokenId,
      parentRef: parentRef,
      name: name,
      dataStream: file.openRead(),
      contentLength: await file.length(),
      overwrite: true,
      onProgress: onProgress,
    );
  }

  void _emitTransferProgress(
    SnapshotSyncTransferProgressCallback? callback, {
    required SnapshotSyncTransferDirection direction,
    required int completedFiles,
    required int totalFiles,
    required int transferredBytes,
    required int? totalBytes,
    String? currentFileName,
  }) {
    callback?.call(
      SnapshotSyncTransferProgress(
        direction: direction,
        completedFiles: completedFiles,
        totalFiles: totalFiles,
        transferredBytes: transferredBytes,
        totalBytes: totalBytes,
        currentFileName: currentFileName,
      ),
    );
  }

  void _cacheFolder(
    String tokenId,
    CloudResourceRef parentRef,
    String name,
    CloudResource folder,
  ) {
    if (!folder.isFolder) {
      return;
    }
    _folderCache[SnapshotSyncUtils.folderCacheKey(tokenId, parentRef, name)] =
        folder;
  }

  void _invalidateStoreCaches(String tokenId, String storeUuid) {
    _layoutCache.remove(SnapshotSyncUtils.layoutCacheKey(tokenId, storeUuid));
    _folderCache.clear();
  }
}
