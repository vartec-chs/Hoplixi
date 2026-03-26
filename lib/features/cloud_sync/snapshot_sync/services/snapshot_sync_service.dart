import 'dart:io';

import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_manifest.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/attachments_manifest_file_service.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/snapshot_sync_hash_service.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/snapshot_sync_repository.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/store_snapshot_manifest_builder.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';
import 'package:hoplixi/main_store/models/db_errors.dart';
import 'package:hoplixi/main_store/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_store/models/store_manifest.dart';
import 'package:hoplixi/main_store/services/main_store_storage_service.dart';
import 'package:hoplixi/main_store/services/store_manifest_service.dart';

enum SnapshotConflictResolution { uploadLocal, downloadRemote }

class ImportedRemoteStoreResult {
  const ImportedRemoteStoreResult({
    required this.storagePath,
    required this.normalizedName,
    required this.dbFilePath,
    required this.remoteManifest,
    required this.tokenId,
    required this.storeUuid,
  });

  final String storagePath;
  final String normalizedName;
  final String dbFilePath;
  final StoreManifest remoteManifest;
  final String tokenId;
  final String storeUuid;
}

class SnapshotSyncService {
  SnapshotSyncService({
    required SnapshotSyncRepository repository,
    StoreSnapshotManifestBuilder? manifestBuilder,
    SnapshotSyncHashService? hashService,
  }) : _repository = repository,
       _manifestBuilder = manifestBuilder ?? StoreSnapshotManifestBuilder(),
       _hashService = hashService ?? const SnapshotSyncHashService();

  final SnapshotSyncRepository _repository;
  final StoreSnapshotManifestBuilder _manifestBuilder;
  final SnapshotSyncHashService _hashService;
  final MainStoreStorageService _storageService = MainStoreStorageService();

  Future<void> initializeRemoteLayout({
    required String tokenId,
    required String storeUuid,
  }) async {
    await _repository.ensureRemoteStoreLayout(tokenId, storeUuid);
  }

  Future<StoreSyncStatus> loadStatus({
    required String storePath,
    required StoreInfoDto storeInfo,
    StoreSyncBinding? binding,
    AuthTokenEntry? token,
  }) async {
    final localSnapshot = await _manifestBuilder.buildAndPersist(
      storePath: storePath,
      storeInfo: storeInfo,
    );

    StoreManifest? remoteManifest;
    if (binding != null) {
      try {
        remoteManifest = await _repository.readRemoteStoreManifest(
          binding.tokenId,
          storeUuid: localSnapshot.storeManifest.storeUuid,
        );
      } on CloudStorageException catch (error) {
        if (!_isRecoverableStatusLoadError(error)) {
          rethrow;
        }
      }
    }

    final compareResult = _compareManifests(
      local: localSnapshot.storeManifest,
      remote: remoteManifest,
    );

    return StoreSyncStatus(
      isStoreOpen: true,
      storePath: storePath,
      storeUuid: storeInfo.id,
      storeName: storeInfo.name,
      binding: binding,
      token: token,
      localManifest: localSnapshot.storeManifest,
      remoteManifest: remoteManifest,
      compareResult: compareResult,
      pendingConflict:
          compareResult == StoreVersionCompareResult.conflict &&
              remoteManifest != null
          ? SnapshotSyncConflict(
              localManifest: localSnapshot.storeManifest,
              remoteManifest: remoteManifest,
            )
          : null,
    );
  }

  Future<SnapshotSyncResult> sync({
    required String storePath,
    required StoreInfoDto storeInfo,
    required StoreSyncBinding binding,
    required AuthTokenEntry token,
  }) async {
    final localSnapshot = await _manifestBuilder.buildAndPersist(
      storePath: storePath,
      storeInfo: storeInfo,
    );
    final remoteManifest = await _repository.readRemoteStoreManifest(
      binding.tokenId,
      storeUuid: localSnapshot.storeManifest.storeUuid,
    );

    final compare = _compareManifests(
      local: localSnapshot.storeManifest,
      remote: remoteManifest,
    );
    if (compare == StoreVersionCompareResult.conflict &&
        remoteManifest != null) {
      return SnapshotSyncResult(
        type: SnapshotSyncResultType.conflict,
        localManifest: localSnapshot.storeManifest,
        remoteManifest: remoteManifest,
        conflict: SnapshotSyncConflict(
          localManifest: localSnapshot.storeManifest,
          remoteManifest: remoteManifest,
        ),
      );
    }

    if (compare == StoreVersionCompareResult.same) {
      return SnapshotSyncResult(
        type: SnapshotSyncResultType.noChanges,
        localManifest: localSnapshot.storeManifest,
        remoteManifest: remoteManifest,
      );
    }

    if (compare == StoreVersionCompareResult.remoteMissing ||
        compare == StoreVersionCompareResult.localNewer) {
      final uploadedManifest = await _uploadLocalSnapshot(
        storePath: storePath,
        storeInfo: storeInfo,
        localSnapshot: localSnapshot,
        binding: binding,
        remoteManifest: remoteManifest,
      );
      return SnapshotSyncResult(
        type: SnapshotSyncResultType.uploaded,
        localManifest: uploadedManifest,
        remoteManifest: uploadedManifest,
      );
    }

    final downloadedManifest = await downloadRemoteSnapshot(
      storePath: storePath,
      binding: binding,
      lockBeforeApply: false,
    );
    return SnapshotSyncResult(
      type: SnapshotSyncResultType.downloaded,
      localManifest: downloadedManifest,
      remoteManifest: downloadedManifest,
    );
  }

  Future<SnapshotSyncResult> resolveConflict({
    required String storePath,
    required StoreInfoDto storeInfo,
    required StoreSyncBinding binding,
    required AuthTokenEntry token,
    required SnapshotConflictResolution resolution,
    bool lockBeforeDownload = false,
  }) async {
    if (resolution == SnapshotConflictResolution.uploadLocal) {
      final localSnapshot = await _manifestBuilder.buildAndPersist(
        storePath: storePath,
        storeInfo: storeInfo,
      );
      final uploadedManifest = await _uploadLocalSnapshot(
        storePath: storePath,
        storeInfo: storeInfo,
        localSnapshot: localSnapshot,
        binding: binding,
        remoteManifest: await _repository.readRemoteStoreManifest(
          binding.tokenId,
          storeUuid: storeInfo.id,
        ),
      );
      return SnapshotSyncResult(
        type: SnapshotSyncResultType.uploaded,
        localManifest: uploadedManifest,
        remoteManifest: uploadedManifest,
      );
    }

    final downloadedManifest = await downloadRemoteSnapshot(
      storePath: storePath,
      binding: binding,
      lockBeforeApply: lockBeforeDownload,
    );
    return SnapshotSyncResult(
      type: SnapshotSyncResultType.downloaded,
      localManifest: downloadedManifest,
      remoteManifest: downloadedManifest,
      requiresUnlockToApply: lockBeforeDownload,
    );
  }

  Future<StoreManifest> downloadRemoteSnapshot({
    required String storePath,
    required StoreSyncBinding binding,
    required bool lockBeforeApply,
  }) async {
    final remoteManifest = await _repository.readRemoteStoreManifest(
      binding.tokenId,
      storeUuid: binding.storeUuid,
    );
    if (remoteManifest == null) {
      throw StateError(
        'Remote manifest was not found for ${binding.storeUuid}.',
      );
    }

    await _repository.downloadRemoteStoreFiles(
      binding.tokenId,
      storeUuid: binding.storeUuid,
      localStorePath: storePath,
    );

    final remoteAttachments = await _repository.readRemoteAttachmentsManifest(
      binding.tokenId,
      storeUuid: binding.storeUuid,
    );
    if (remoteAttachments != null) {
      await _repository.reconcileAttachmentsDownload(
        binding.tokenId,
        storeUuid: binding.storeUuid,
        localAttachmentsDir: Directory(
          _storageService.getAttachmentsPath(storePath),
        ),
        remoteManifest: remoteAttachments,
      );
      await AttachmentsManifestFileService.writeTo(
        storePath,
        remoteAttachments,
      );
    }

    await StoreManifestService.writeTo(
      storePath,
      remoteManifest.copyWith(
        sync: (remoteManifest.sync ?? const StoreManifestSyncMetadata())
            .copyWith(
              provider: binding.provider,
              syncedAt: DateTime.now().toUtc(),
            ),
      ),
    );

    return remoteManifest;
  }

  Future<ImportedRemoteStoreResult> importRemoteStoreToLocal({
    required String tokenId,
    required String storeUuid,
    required String baseStoragePath,
  }) async {
    final remoteManifest = await _repository.readRemoteStoreManifest(
      tokenId,
      storeUuid: storeUuid,
    );
    if (remoteManifest == null) {
      throw StateError('Remote store manifest was not found for $storeUuid.');
    }

    final preferredName = remoteManifest.storeName.trim().isEmpty
        ? storeUuid
        : remoteManifest.storeName.trim();
    final prepared = await _prepareUniqueImportDirectory(
      baseStoragePath: baseStoragePath,
      preferredStoreName: preferredName,
    );
    final storagePath = prepared.storageDir.path;

    try {
      await _repository.downloadRemoteStoreFiles(
        tokenId,
        storeUuid: storeUuid,
        localStorePath: storagePath,
      );

      final remoteAttachments = await _repository.readRemoteAttachmentsManifest(
        tokenId,
        storeUuid: storeUuid,
      );
      if (remoteAttachments != null) {
        await _repository.reconcileAttachmentsDownload(
          tokenId,
          storeUuid: storeUuid,
          localAttachmentsDir: Directory(
            _storageService.getAttachmentsPath(storagePath),
          ),
          remoteManifest: remoteAttachments,
        );
        await AttachmentsManifestFileService.writeTo(
          storagePath,
          remoteAttachments,
        );
      }

      await StoreManifestService.writeTo(storagePath, remoteManifest);

      final dbFilePath =
          await _storageService.findDatabaseFile(storagePath) ??
          _storageService.getDatabaseFilePath(
            storagePath,
            prepared.normalizedName,
          );
      if (!await File(dbFilePath).exists()) {
        throw StateError(
          'Downloaded snapshot does not contain a local database file.',
        );
      }

      return ImportedRemoteStoreResult(
        storagePath: storagePath,
        normalizedName: prepared.normalizedName,
        dbFilePath: dbFilePath,
        remoteManifest: remoteManifest,
        tokenId: tokenId,
        storeUuid: storeUuid,
      );
    } catch (_) {
      if (await Directory(storagePath).exists()) {
        await Directory(storagePath).delete(recursive: true);
      }
      rethrow;
    }
  }

  StoreVersionCompareResult compareStoreVersions({
    required StoreManifest local,
    required StoreManifest? remote,
  }) {
    return _compareManifests(local: local, remote: remote);
  }

  Future<StoreManifest> _uploadLocalSnapshot({
    required String storePath,
    required StoreInfoDto storeInfo,
    required LocalStoreSnapshot localSnapshot,
    required StoreSyncBinding binding,
    required StoreManifest? remoteManifest,
  }) async {
    final updatedSyncMetadata =
        (localSnapshot.storeManifest.sync ?? const StoreManifestSyncMetadata())
            .copyWith(
              provider: binding.provider,
              syncedAt: DateTime.now().toUtc(),
            );
    final manifestToUpload = localSnapshot.storeManifest.copyWith(
      baseRevision: remoteManifest?.revision,
      baseSnapshotId: remoteManifest?.snapshotId,
      sync: updatedSyncMetadata,
    );

    await _repository.uploadStoreFiles(
      binding.tokenId,
      storeUuid: manifestToUpload.storeUuid,
      dbFile: localSnapshot.dbFile,
      keyFile: localSnapshot.keyFile,
    );
    await _repository.reconcileAttachmentsUpload(
      binding.tokenId,
      storeUuid: manifestToUpload.storeUuid,
      localAttachmentsDir: Directory(
        _storageService.getAttachmentsPath(storePath),
      ),
      localManifest: localSnapshot.attachmentsManifest,
      remoteManifest: await _repository.readRemoteAttachmentsManifest(
        binding.tokenId,
        storeUuid: manifestToUpload.storeUuid,
      ),
    );
    await _repository.uploadAttachmentsManifest(
      binding.tokenId,
      storeUuid: manifestToUpload.storeUuid,
      manifest: localSnapshot.attachmentsManifest,
    );
    await _repository.uploadStoreManifest(
      binding.tokenId,
      storeUuid: manifestToUpload.storeUuid,
      manifest: manifestToUpload,
    );

    final remoteLayout = await _repository.ensureRemoteStoreLayout(
      binding.tokenId,
      manifestToUpload.storeUuid,
    );
    final manifestHash = _hashService.sha256ForJson(manifestToUpload.toJson());
    final cloudManifest =
        (await _repository.readCloudManifest(binding.tokenId)) ??
        CloudManifest.empty();
    final updatedCloudManifest = CloudManifest(
      version: cloudManifest.version,
      updatedAt: DateTime.now().toUtc(),
      stores: _upsertCloudEntry(
        cloudManifest.stores,
        CloudManifestStoreEntry(
          storeUuid: manifestToUpload.storeUuid,
          storeName: manifestToUpload.storeName,
          revision: manifestToUpload.revision,
          updatedAt: manifestToUpload.updatedAt,
          snapshotId: manifestToUpload.snapshotId,
          remoteStoreId: remoteLayout.storeFolder.ref.resourceId,
          remotePath: remoteLayout.storeFolder.ref.path,
          manifestSha256: manifestHash,
        ),
      ),
    );
    await _repository.writeCloudManifest(binding.tokenId, updatedCloudManifest);

    final persistedLocalManifest = manifestToUpload.copyWith(
      sync: updatedSyncMetadata.copyWith(
        remoteStoreId: remoteLayout.storeFolder.ref.resourceId,
        remotePath: remoteLayout.storeFolder.ref.path,
      ),
    );
    await StoreManifestService.writeTo(storePath, persistedLocalManifest);
    return persistedLocalManifest;
  }

  List<CloudManifestStoreEntry> _upsertCloudEntry(
    List<CloudManifestStoreEntry> entries,
    CloudManifestStoreEntry next,
  ) {
    final updated = <CloudManifestStoreEntry>[];
    var replaced = false;
    for (final entry in entries) {
      if (entry.storeUuid == next.storeUuid) {
        updated.add(next);
        replaced = true;
      } else {
        updated.add(entry);
      }
    }
    if (!replaced) {
      updated.add(next);
    }
    updated.sort((left, right) => left.storeUuid.compareTo(right.storeUuid));
    return updated;
  }

  StoreVersionCompareResult _compareManifests({
    required StoreManifest local,
    required StoreManifest? remote,
  }) {
    if (remote == null) {
      return StoreVersionCompareResult.remoteMissing;
    }
    if (local.storeUuid != remote.storeUuid) {
      return StoreVersionCompareResult.differentStore;
    }
    if (local.revision > remote.revision) {
      return StoreVersionCompareResult.localNewer;
    }
    if (remote.revision > local.revision) {
      return StoreVersionCompareResult.remoteNewer;
    }
    if (local.snapshotId.isNotEmpty && local.snapshotId == remote.snapshotId) {
      return StoreVersionCompareResult.same;
    }
    if (local.isSameContent(remote)) {
      return StoreVersionCompareResult.same;
    }
    return StoreVersionCompareResult.conflict;
  }

  bool _isRecoverableStatusLoadError(CloudStorageException error) {
    return error.type == CloudStorageExceptionType.network ||
        error.type == CloudStorageExceptionType.timeout;
  }

  Future<({String normalizedName, Directory storageDir})>
  _prepareUniqueImportDirectory({
    required String baseStoragePath,
    required String preferredStoreName,
  }) async {
    final baseName = preferredStoreName.trim().isEmpty
        ? 'imported_store'
        : preferredStoreName.trim();

    for (var attempt = 0; attempt < 1000; attempt++) {
      final candidateName = switch (attempt) {
        0 => baseName,
        1 => '${baseName}_imported',
        _ => '${baseName}_imported_$attempt',
      };

      try {
        return await _storageService.prepareNewStorageDirectory(
          baseStoragePath: baseStoragePath,
          storeName: candidateName,
        );
      } on ValidationError {
        continue;
      } on DatabaseError catch (error) {
        throw StateError(
          'Failed to prepare local storage directory for import: ${error.message}',
        );
      }
    }

    throw StateError(
      'Could not find a unique local store name for "$preferredStoreName".',
    );
  }
}
