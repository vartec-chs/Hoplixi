import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/attachments_manifest.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_manifest.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_ref.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';
import 'package:hoplixi/features/cloud_sync/storage/services/cloud_storage_repository.dart';
import 'package:hoplixi/main_store/models/store_manifest.dart';

class RemoteStoreLayout {
  const RemoteStoreLayout({
    required this.rootFolder,
    required this.storesFolder,
    required this.storeFolder,
    required this.attachmentsFolder,
  });

  final CloudResource rootFolder;
  final CloudResource storesFolder;
  final CloudResource storeFolder;
  final CloudResource attachmentsFolder;
}

class SnapshotSyncRepository {
  SnapshotSyncRepository(this._storageRepository);

  static const String rootFolderName = 'Hoplixi';
  static const String storesFolderName = 'stores';
  static const String cloudManifestFileName = 'cloud_manifest.json';
  static const String storeManifestFileName = 'store_manifest.json';
  static const String attachmentsManifestFileName = 'attachments_manifest.json';
  static const String keyFileName = 'store_key.json';
  static const String attachmentsFolderName = 'attachments';

  final CloudStorageRepository _storageRepository;
  final Map<String, RemoteStoreLayout> _layoutCache =
      <String, RemoteStoreLayout>{};
  final Map<String, CloudResource> _folderCache = <String, CloudResource>{};

  Future<CloudManifest?> readCloudManifest(String tokenId) async {
    try {
      final root = await _ensureRootFolder(tokenId);
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
    final cachedLayout = _layoutCache[_layoutCacheKey(tokenId, storeUuid)];
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
    _layoutCache[_layoutCacheKey(tokenId, storeUuid)] = layout;
    return layout;
  }

  Future<StoreManifest?> readRemoteStoreManifest(
    String tokenId, {
    required String storeUuid,
  }) async {
    final layout = await ensureRemoteStoreLayout(tokenId, storeUuid);
    final file = await _findChildFileByName(
      tokenId,
      parentRef: layout.storeFolder.ref,
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
  }) async {
    final layout = await ensureRemoteStoreLayout(tokenId, storeUuid);
    final file = await _findChildFileByName(
      tokenId,
      parentRef: layout.storeFolder.ref,
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
  }) async {
    final layout = await ensureRemoteStoreLayout(tokenId, storeUuid);
    await _uploadBytes(
      tokenId,
      parentRef: layout.storeFolder.ref,
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
  }) async {
    final layout = await ensureRemoteStoreLayout(tokenId, storeUuid);
    await _uploadBytes(
      tokenId,
      parentRef: layout.storeFolder.ref,
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
    File? keyFile,
  }) async {
    final layout = await ensureRemoteStoreLayout(tokenId, storeUuid);
    await _uploadFile(
      tokenId,
      parentRef: layout.storeFolder.ref,
      file: dbFile,
      name: p.basename(dbFile.path),
    );

    if (keyFile != null && await keyFile.exists()) {
      await _uploadFile(
        tokenId,
        parentRef: layout.storeFolder.ref,
        file: keyFile,
        name: keyFileName,
      );
    }
  }

  Future<void> reconcileAttachmentsUpload(
    String tokenId, {
    required String storeUuid,
    required Directory localAttachmentsDir,
    required AttachmentsManifest localManifest,
    required AttachmentsManifest? remoteManifest,
  }) async {
    final layout = await ensureRemoteStoreLayout(tokenId, storeUuid);
    final remoteFiles = <String, AttachmentManifestEntry>{
      for (final entry
          in remoteManifest?.files ?? const <AttachmentManifestEntry>[])
        entry.fileName: entry,
    };

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

      await _uploadFile(
        tokenId,
        parentRef: layout.attachmentsFolder.ref,
        file: localFile,
        name: entry.fileName,
      );
    }

    for (final stale in remoteFiles.values.where((file) => !file.deleted)) {
      final remoteFile = await _findChildFileByName(
        tokenId,
        parentRef: layout.attachmentsFolder.ref,
        name: stale.fileName,
      );
      if (remoteFile != null) {
        await _storageRepository.deleteResource(tokenId, remoteFile.ref);
      }
    }
  }

  Future<void> downloadRemoteStoreFiles(
    String tokenId, {
    required String storeUuid,
    required String localStorePath,
  }) async {
    final layout = await ensureRemoteStoreLayout(tokenId, storeUuid);
    final items = await _listAll(tokenId, layout.storeFolder.ref);

    for (final resource in items.where((item) => item.isFile)) {
      if (resource.name == attachmentsManifestFileName ||
          resource.name == storeManifestFileName) {
        continue;
      }
      final destination = p.join(localStorePath, resource.name);
      await _storageRepository.downloadFile(
        tokenId,
        fileRef: resource.ref,
        savePath: destination,
      );
    }
  }

  Future<void> reconcileAttachmentsDownload(
    String tokenId, {
    required String storeUuid,
    required Directory localAttachmentsDir,
    required AttachmentsManifest remoteManifest,
  }) async {
    final layout = await ensureRemoteStoreLayout(tokenId, storeUuid);
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

    final remoteFiles = <String>{};
    for (final entry in remoteManifest.files.where((file) => !file.deleted)) {
      remoteFiles.add(entry.fileName);
      final remoteFile = await _findChildFileByName(
        tokenId,
        parentRef: layout.attachmentsFolder.ref,
        name: entry.fileName,
      );
      if (remoteFile == null) {
        continue;
      }
      await _storageRepository.downloadFile(
        tokenId,
        fileRef: remoteFile.ref,
        savePath: p.join(localAttachmentsDir.path, entry.fileName),
      );
    }

    for (final localName in existingLocalNames.difference(remoteFiles)) {
      final localFile = File(p.join(localAttachmentsDir.path, localName));
      if (await localFile.exists()) {
        await localFile.delete();
      }
    }
  }

  Future<CloudResource> _ensureRootFolder(String tokenId) async {
    final provider = await _storageRepository.providerForToken(tokenId);
    final rootRef = _rootRefForProvider(provider.provider);
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
    final cached = _folderCache[_folderCacheKey(tokenId, parentRef, name)];
    if (cached != null) {
      return cached;
    }

    if (_shouldCreateFolderWithoutLookup(parentRef)) {
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

  bool _shouldCreateFolderWithoutLookup(CloudResourceRef parentRef) {
    if (!_usesDirectPathOnly(parentRef.provider)) {
      return false;
    }

    if (parentRef.isRoot) {
      return true;
    }

    final parentPath = parentRef.path?.trim();
    return parentPath != null && parentPath.isNotEmpty;
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
    final direct = await _findChildByDirectPath(
      tokenId,
      parentRef: parentRef,
      name: name,
    );
    if (direct != null) {
      return direct.isFolder ? direct : null;
    }
    if (_usesDirectPathOnly(parentRef.provider)) {
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
    final direct = await _findChildByDirectPath(
      tokenId,
      parentRef: parentRef,
      name: name,
    );
    if (direct != null) {
      return direct.isFile ? direct : null;
    }
    if (_usesDirectPathOnly(parentRef.provider)) {
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
    final childRef = _buildDirectChildRef(parentRef, name);
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
    final sink = _ByteCollectorSink();
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
  }) async {
    await _storageRepository.uploadFile(
      tokenId,
      parentRef: parentRef,
      name: name,
      dataStream: file.openRead(),
      contentLength: await file.length(),
      overwrite: true,
    );
  }

  CloudResourceRef _rootRefForProvider(CloudSyncProvider provider) {
    return switch (provider) {
      CloudSyncProvider.google => const CloudResourceRef.root(
        provider: CloudSyncProvider.google,
        resourceId: 'root',
        path: '',
      ),
      CloudSyncProvider.onedrive => const CloudResourceRef.root(
        provider: CloudSyncProvider.onedrive,
        resourceId: 'root',
        path: '',
      ),
      CloudSyncProvider.yandex => const CloudResourceRef.root(
        provider: CloudSyncProvider.yandex,
        path: 'disk:/',
      ),
      CloudSyncProvider.dropbox => const CloudResourceRef.root(
        provider: CloudSyncProvider.dropbox,
        path: '',
      ),
      CloudSyncProvider.other => const CloudResourceRef.root(
        provider: CloudSyncProvider.other,
        path: '',
      ),
    };
  }

  CloudResourceRef? _buildDirectChildRef(
    CloudResourceRef parentRef,
    String name,
  ) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return null;
    }

    return switch (parentRef.provider) {
      CloudSyncProvider.dropbox => CloudResourceRef(
        provider: CloudSyncProvider.dropbox,
        path: _joinDropboxPath(parentRef.path, trimmedName),
      ),
      CloudSyncProvider.yandex => CloudResourceRef(
        provider: CloudSyncProvider.yandex,
        path: _joinYandexPath(parentRef.path, trimmedName),
      ),
      _ => null,
    };
  }

  String _joinDropboxPath(String? parentPath, String childName) {
    final base = (parentPath ?? '').trim();
    final normalizedBase = base.isEmpty
        ? ''
        : base.replaceFirst(RegExp(r'/+$'), '');
    final normalizedChild = childName.replaceFirst(RegExp(r'^/+'), '');
    return normalizedBase.isEmpty
        ? '/$normalizedChild'
        : '$normalizedBase/$normalizedChild';
  }

  String _joinYandexPath(String? parentPath, String childName) {
    final base = (parentPath ?? 'disk:/').trim();
    final normalizedBase = base == 'disk:/'
        ? 'disk:/'
        : base.replaceFirst(RegExp(r'/+$'), '');
    final normalizedChild = childName.replaceFirst(RegExp(r'^/+'), '');
    return normalizedBase == 'disk:/'
        ? 'disk:/$normalizedChild'
        : '$normalizedBase/$normalizedChild';
  }

  bool _usesDirectPathOnly(CloudSyncProvider provider) {
    return switch (provider) {
      CloudSyncProvider.dropbox => true,
      CloudSyncProvider.yandex => true,
      _ => false,
    };
  }

  String _layoutCacheKey(String tokenId, String storeUuid) {
    return '$tokenId::$storeUuid';
  }

  String _folderCacheKey(
    String tokenId,
    CloudResourceRef parentRef,
    String name,
  ) {
    final parentKey =
        '${parentRef.provider.id}|${parentRef.resourceId ?? ''}|${parentRef.path ?? ''}';
    return '$tokenId::$parentKey::$name';
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
    _folderCache[_folderCacheKey(tokenId, parentRef, name)] = folder;
  }
}

class _ByteCollectorSink implements StreamConsumer<List<int>> {
  final BytesBuilder _builder = BytesBuilder(copy: false);

  List<int> get bytes => _builder.takeBytes();

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      _builder.add(chunk);
    }
  }

  @override
  Future<void> close() async {}
}
