import 'dart:async';
import 'dart:io';

import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/attachments_manifest.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_manifest.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/attachments_manifest_file_service.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/snapshot_sync_hash_service.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/snapshot_sync_repository.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/store_snapshot_manifest_builder.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';
import 'package:hoplixi/db_core/models/db_errors.dart';
import 'package:hoplixi/db_core/models/dto/main_store_dto.dart';
import 'package:hoplixi/db_core/models/store_manifest.dart';
import 'package:hoplixi/db_core/services/main_store_storage_service.dart';
import 'package:hoplixi/db_core/services/store_manifest_service.dart';

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
  static const int _totalProgressSteps = 6;

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
    bool skipRemoteManifestCheck = false,
    bool remoteCheckSkippedOffline = false,
    bool persistLocalSnapshot = false,
    bool allowLocalRevisionBump = false,
  }) async {
    final localSnapshot = await _buildLocalSnapshot(
      storePath: storePath,
      storeInfo: storeInfo,
      persist: persistLocalSnapshot,
      allowRevisionBump: allowLocalRevisionBump,
    );
    final remoteManifest = await _readRemoteManifestForStatus(
      binding: binding,
      storeUuid: localSnapshot.storeManifest.storeUuid,
      skipRemoteManifestCheck: skipRemoteManifestCheck,
    );

    return _buildStoreSyncStatus(
      storePath: storePath,
      storeInfo: storeInfo,
      binding: binding,
      token: token,
      localManifest: localSnapshot.storeManifest,
      remoteManifest: remoteManifest,
      remoteCheckSkippedOffline: remoteCheckSkippedOffline,
    );
  }

  Future<LocalStoreSnapshot> _buildLocalSnapshot({
    required String storePath,
    required StoreInfoDto storeInfo,
    bool persist = true,
    bool allowRevisionBump = true,
  }) {
    return _manifestBuilder.buildAndPersist(
      storePath: storePath,
      storeInfo: storeInfo,
      persist: persist,
      allowRevisionBump: allowRevisionBump,
    );
  }

  Future<StoreManifest?> _readRemoteManifestForStatus({
    required StoreSyncBinding? binding,
    required String storeUuid,
    required bool skipRemoteManifestCheck,
  }) async {
    if (binding == null || skipRemoteManifestCheck) {
      return null;
    }

    try {
      return await _repository.readRemoteStoreManifest(
        binding.tokenId,
        storeUuid: storeUuid,
      );
    } on CloudStorageException catch (error) {
      if (!_isRecoverableStatusLoadError(error)) {
        rethrow;
      }
      return null;
    }
  }

  StoreSyncStatus _buildStoreSyncStatus({
    required String storePath,
    required StoreInfoDto storeInfo,
    required StoreSyncBinding? binding,
    required AuthTokenEntry? token,
    required StoreManifest localManifest,
    required StoreManifest? remoteManifest,
    required bool remoteCheckSkippedOffline,
  }) {
    final compareResult = compareStoreManifests(
      local: localManifest,
      remote: remoteManifest,
    );

    return StoreSyncStatus(
      isStoreOpen: true,
      storePath: storePath,
      storeUuid: storeInfo.id,
      storeName: storeInfo.name,
      binding: binding,
      token: token,
      localManifest: localManifest,
      remoteManifest: remoteManifest,
      compareResult: compareResult,
      remoteCheckSkippedOffline: remoteCheckSkippedOffline,
      pendingConflict:
          compareResult == StoreVersionCompareResult.conflict &&
              remoteManifest != null
          ? SnapshotSyncConflict(
              localManifest: localManifest,
              remoteManifest: remoteManifest,
            )
          : null,
    );
  }

  Future<SnapshotSyncResult> sync({
    required String storePath,
    required StoreInfoDto storeInfo,
    required StoreSyncBinding binding,
  }) {
    return _awaitProgressResult(
      syncWithProgress(
        storePath: storePath,
        storeInfo: storeInfo,
        binding: binding,
      ),
    );
  }

  Stream<SnapshotSyncProgressEvent> syncWithProgress({
    required String storePath,
    required StoreInfoDto storeInfo,
    required StoreSyncBinding binding,
  }) {
    return _runProgressStream((emitProgress) async {
      emitProgress(_preparingLocalSnapshotProgress());
      final localSnapshot = await _buildLocalSnapshot(
        storePath: storePath,
        storeInfo: storeInfo,
      );

      emitProgress(_checkingRemoteVersionProgress());
      final remoteManifest = await _repository.readRemoteStoreManifest(
        binding.tokenId,
        storeUuid: localSnapshot.storeManifest.storeUuid,
      );

      return _syncByCompareResult(
        compareResult: compareStoreManifests(
          local: localSnapshot.storeManifest,
          remote: remoteManifest,
        ),
        storePath: storePath,
        localSnapshot: localSnapshot,
        binding: binding,
        remoteManifest: remoteManifest,
        lockBeforeDownload: false,
        emitProgress: emitProgress,
      );
    });
  }

  Future<SnapshotSyncResult> _syncByCompareResult({
    required StoreVersionCompareResult compareResult,
    required String storePath,
    required LocalStoreSnapshot localSnapshot,
    required StoreSyncBinding binding,
    required StoreManifest? remoteManifest,
    required bool lockBeforeDownload,
    void Function(SnapshotSyncProgress progress)? emitProgress,
  }) async {
    switch (compareResult) {
      case StoreVersionCompareResult.same:
        return SnapshotSyncResult(
          type: SnapshotSyncResultType.noChanges,
          localManifest: localSnapshot.storeManifest,
          remoteManifest: remoteManifest,
        );
      case StoreVersionCompareResult.remoteMissing:
      case StoreVersionCompareResult.localNewer:
        return _uploadLocalSyncResult(
          storePath: storePath,
          localSnapshot: localSnapshot,
          binding: binding,
          remoteManifest: remoteManifest,
          emitProgress: emitProgress,
        );
      case StoreVersionCompareResult.remoteNewer:
        return _downloadSyncResult(
          storePath: storePath,
          binding: binding,
          lockBeforeDownload: lockBeforeDownload,
          emitProgress: emitProgress,
        );
      case StoreVersionCompareResult.conflict:
        if (remoteManifest == null) {
          throw StateError(
            'Remote manifest is required to build a conflict result.',
          );
        }
        return SnapshotSyncResult(
          type: SnapshotSyncResultType.conflict,
          localManifest: localSnapshot.storeManifest,
          remoteManifest: remoteManifest,
          conflict: SnapshotSyncConflict(
            localManifest: localSnapshot.storeManifest,
            remoteManifest: remoteManifest,
          ),
        );
      case StoreVersionCompareResult.differentStore:
        throw StateError(
          'Cannot sync different stores: local=${localSnapshot.storeManifest.storeUuid}, '
          'remote=${remoteManifest?.storeUuid ?? 'unknown'}.',
        );
    }
  }

  Future<SnapshotSyncResult> _uploadLocalSyncResult({
    required String storePath,
    required LocalStoreSnapshot localSnapshot,
    required StoreSyncBinding binding,
    required StoreManifest? remoteManifest,
    void Function(SnapshotSyncProgress progress)? emitProgress,
  }) async {
    final uploadedManifest = await _uploadLocalSnapshot(
      storePath: storePath,
      localSnapshot: localSnapshot,
      binding: binding,
      remoteManifest: remoteManifest,
      emitProgress: emitProgress,
    );
    return SnapshotSyncResult(
      type: SnapshotSyncResultType.uploaded,
      localManifest: uploadedManifest,
      remoteManifest: uploadedManifest,
    );
  }

  Future<SnapshotSyncResult> _downloadSyncResult({
    required String storePath,
    required StoreSyncBinding binding,
    required bool lockBeforeDownload,
    void Function(SnapshotSyncProgress progress)? emitProgress,
  }) async {
    final downloadedManifest = await downloadRemoteSnapshot(
      storePath: storePath,
      binding: binding,
      lockBeforeApply: lockBeforeDownload,
      emitProgress: emitProgress,
    );
    return SnapshotSyncResult(
      type: SnapshotSyncResultType.downloaded,
      localManifest: downloadedManifest,
      remoteManifest: downloadedManifest,
      requiresUnlockToApply: lockBeforeDownload,
    );
  }

  Future<SnapshotSyncResult> resolveConflict({
    required String storePath,
    required StoreInfoDto storeInfo,
    required StoreSyncBinding binding,
    required SnapshotConflictResolution resolution,
    bool lockBeforeDownload = false,
  }) {
    return _awaitProgressResult(
      resolveConflictWithProgress(
        storePath: storePath,
        storeInfo: storeInfo,
        binding: binding,
        resolution: resolution,
        lockBeforeDownload: lockBeforeDownload,
      ),
    );
  }

  Stream<SnapshotSyncProgressEvent> resolveConflictWithProgress({
    required String storePath,
    required StoreInfoDto storeInfo,
    required StoreSyncBinding binding,
    required SnapshotConflictResolution resolution,
    bool lockBeforeDownload = false,
  }) {
    return _runProgressStream((emitProgress) async {
      if (resolution == SnapshotConflictResolution.uploadLocal) {
        emitProgress(_preparingLocalSnapshotProgress());
        final localSnapshot = await _buildLocalSnapshot(
          storePath: storePath,
          storeInfo: storeInfo,
        );

        emitProgress(_checkingRemoteVersionProgress());
        final remoteManifest = await _repository.readRemoteStoreManifest(
          binding.tokenId,
          storeUuid: localSnapshot.storeManifest.storeUuid,
        );
        return _uploadLocalSyncResult(
          storePath: storePath,
          localSnapshot: localSnapshot,
          binding: binding,
          remoteManifest: remoteManifest,
          emitProgress: emitProgress,
        );
      }

      emitProgress(_preparingLocalSnapshotProgress());
      emitProgress(_checkingRemoteVersionProgress());
      return _downloadSyncResult(
        storePath: storePath,
        binding: binding,
        lockBeforeDownload: lockBeforeDownload,
        emitProgress: emitProgress,
      );
    });
  }

  Future<StoreManifest> downloadRemoteSnapshot({
    required String storePath,
    required StoreSyncBinding binding,
    required bool lockBeforeApply,
    void Function(SnapshotSyncProgress progress)? emitProgress,
  }) async {
    return _downloadStoreToLocal(
      tokenId: binding.tokenId,
      storeUuid: binding.storeUuid,
      storePath: storePath,
      syncProvider: binding.provider,
      updateSyncMetadata: true,
      emitProgress: emitProgress,
    );
  }

  Future<StoreManifest> _downloadStoreToLocal({
    required String tokenId,
    required String storeUuid,
    required String storePath,
    required bool updateSyncMetadata,
    CloudSyncProvider? syncProvider,
    StoreManifest? remoteManifest,
    void Function(SnapshotSyncProgress progress)? emitProgress,
  }) async {
    final requiredRemoteManifest =
        remoteManifest ??
        await _requireRemoteStoreManifest(tokenId, storeUuid: storeUuid);
    final remoteLayout = await _repository.ensureRemoteStoreLayout(
      tokenId,
      storeUuid,
    );

    emitProgress?.call(
      _primaryTransferProgress(
        direction: SnapshotSyncTransferDirection.download,
      ),
    );
    await _repository.downloadRemoteStoreFiles(
      tokenId,
      storeUuid: storeUuid,
      localStorePath: storePath,
      layout: remoteLayout,
      onProgress: (progress) {
        emitProgress?.call(
          _primaryTransferProgress(
            direction: SnapshotSyncTransferDirection.download,
            transferProgress: progress,
          ),
        );
      },
    );

    final remoteAttachments = await _repository.readRemoteAttachmentsManifest(
      tokenId,
      storeUuid: storeUuid,
      layout: remoteLayout,
    );
    emitProgress?.call(
      _attachmentsProgress(direction: SnapshotSyncTransferDirection.download),
    );
    if (remoteAttachments != null) {
      await _repository.reconcileAttachmentsDownload(
        tokenId,
        storeUuid: storeUuid,
        localAttachmentsDir: Directory(
          _storageService.getAttachmentsPath(storePath),
        ),
        remoteManifest: remoteAttachments,
        layout: remoteLayout,
        onProgress: (progress) {
          emitProgress?.call(
            _attachmentsProgress(
              direction: SnapshotSyncTransferDirection.download,
              transferProgress: progress,
            ),
          );
        },
      );
      await AttachmentsManifestFileService.writeTo(
        storePath,
        remoteAttachments,
      );
    }

    emitProgress?.call(_metadataProgress());
    final appliedManifest = updateSyncMetadata
        ? requiredRemoteManifest.copyWith(
            sync:
                (requiredRemoteManifest.sync ??
                        const StoreManifestSyncMetadata())
                    .copyWith(
                      provider: syncProvider,
                      syncedAt: DateTime.now().toUtc(),
                    ),
          )
        : requiredRemoteManifest;
    await StoreManifestService.writeTo(storePath, appliedManifest);
    return appliedManifest;
  }

  Future<StoreManifest> _requireRemoteStoreManifest(
    String tokenId, {
    required String storeUuid,
  }) async {
    final remoteManifest = await _repository.readRemoteStoreManifest(
      tokenId,
      storeUuid: storeUuid,
    );
    if (remoteManifest == null) {
      throw StateError('Remote store manifest was not found for $storeUuid.');
    }
    return remoteManifest;
  }

  Future<ImportedRemoteStoreResult> importRemoteStoreToLocal({
    required String tokenId,
    required String storeUuid,
    required String baseStoragePath,
  }) async {
    final remoteManifest = await _requireRemoteStoreManifest(
      tokenId,
      storeUuid: storeUuid,
    );
    final preferredName = remoteManifest.storeName.trim().isEmpty
        ? storeUuid
        : remoteManifest.storeName.trim();
    final prepared = await _prepareUniqueImportDirectory(
      baseStoragePath: baseStoragePath,
      preferredStoreName: preferredName,
    );
    final storagePath = prepared.storageDir.path;

    try {
      final downloadedManifest = await _downloadStoreToLocal(
        tokenId: tokenId,
        storeUuid: storeUuid,
        storePath: storagePath,
        updateSyncMetadata: false,
        remoteManifest: remoteManifest,
      );
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
        remoteManifest: downloadedManifest,
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

  Future<void> deleteRemoteSnapshot({
    required String tokenId,
    required CloudManifestStoreEntry entry,
    bool permanent = true,
  }) async {
    try {
      await _repository.deleteRemoteStoreFolder(
        tokenId,
        storeUuid: entry.storeUuid,
        remoteStoreId: entry.remoteStoreId,
        remotePath: entry.remotePath,
        permanent: permanent,
      );
    } on CloudStorageException catch (error) {
      if (error.type != CloudStorageExceptionType.notFound) {
        rethrow;
      }
    }

    final cloudManifest =
        await _repository.readCloudManifest(tokenId) ?? CloudManifest.empty();
    final updatedAt = DateTime.now().toUtc();
    final updatedCloudManifest = CloudManifest(
      version: cloudManifest.version,
      updatedAt: updatedAt,
      stores: _markCloudEntryDeleted(
        cloudManifest.stores,
        entry,
        updatedAt: updatedAt,
      ),
    );
    await _repository.writeCloudManifest(tokenId, updatedCloudManifest);
  }

  StoreVersionCompareResult compareStoreVersions({
    required StoreManifest local,
    required StoreManifest? remote,
  }) {
    return compareStoreManifests(local: local, remote: remote);
  }

  Future<StoreManifest> _uploadLocalSnapshot({
    required String storePath,
    required LocalStoreSnapshot localSnapshot,
    required StoreSyncBinding binding,
    required StoreManifest? remoteManifest,
    void Function(SnapshotSyncProgress progress)? emitProgress,
  }) async {
    emitProgress?.call(
      _primaryTransferProgress(direction: SnapshotSyncTransferDirection.upload),
    );
    final remoteLayout = await _repository.ensureRemoteStoreLayout(
      binding.tokenId,
      localSnapshot.storeManifest.storeUuid,
    );
    final metadataReads = await Future.wait<Object?>(<Future<Object?>>[
      _repository.readRemoteAttachmentsManifest(
        binding.tokenId,
        storeUuid: localSnapshot.storeManifest.storeUuid,
        layout: remoteLayout,
      ),
      _repository.readCloudManifest(binding.tokenId),
    ]);
    final remoteAttachmentsManifest =
        metadataReads.first as AttachmentsManifest?;
    final cloudManifest =
        metadataReads.last as CloudManifest? ?? CloudManifest.empty();

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
      layout: remoteLayout,
      onProgress: (progress) {
        emitProgress?.call(
          _primaryTransferProgress(
            direction: SnapshotSyncTransferDirection.upload,
            transferProgress: progress,
          ),
        );
      },
    );
    emitProgress?.call(
      _attachmentsProgress(direction: SnapshotSyncTransferDirection.upload),
    );
    await _repository.reconcileAttachmentsUpload(
      binding.tokenId,
      storeUuid: manifestToUpload.storeUuid,
      localAttachmentsDir: Directory(
        _storageService.getAttachmentsPath(storePath),
      ),
      localManifest: localSnapshot.attachmentsManifest,
      remoteManifest: remoteAttachmentsManifest,
      layout: remoteLayout,
      onProgress: (progress) {
        emitProgress?.call(
          _attachmentsProgress(
            direction: SnapshotSyncTransferDirection.upload,
            transferProgress: progress,
          ),
        );
      },
    );
    emitProgress?.call(_metadataProgress());
    await _repository.uploadAttachmentsManifest(
      binding.tokenId,
      storeUuid: manifestToUpload.storeUuid,
      manifest: localSnapshot.attachmentsManifest,
      layout: remoteLayout,
    );
    await _repository.uploadStoreManifest(
      binding.tokenId,
      storeUuid: manifestToUpload.storeUuid,
      manifest: manifestToUpload,
      layout: remoteLayout,
    );

    final manifestHash = _hashService.sha256ForJson(manifestToUpload.toJson());
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

  Future<SnapshotSyncResult> _awaitProgressResult(
    Stream<SnapshotSyncProgressEvent> stream,
  ) async {
    await for (final event in stream) {
      if (event is SnapshotSyncProgressResult) {
        return event.result;
      }
    }
    throw StateError('Snapshot sync stream completed without a result.');
  }

  Stream<SnapshotSyncProgressEvent> _runProgressStream(
    Future<SnapshotSyncResult> Function(
      void Function(SnapshotSyncProgress progress) emitProgress,
    )
    runner,
  ) {
    final controller = StreamController<SnapshotSyncProgressEvent>();
    unawaited(() async {
      try {
        final result = await runner((progress) {
          if (!controller.isClosed) {
            controller.add(SnapshotSyncProgressUpdate(progress));
          }
        });
        if (!controller.isClosed) {
          controller.add(
            SnapshotSyncProgressUpdate(_completedProgress(result)),
          );
          controller.add(SnapshotSyncProgressResult(result));
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      } finally {
        await controller.close();
      }
    }());
    return controller.stream;
  }

  SnapshotSyncProgress _preparingLocalSnapshotProgress() {
    return const SnapshotSyncProgress(
      stage: SnapshotSyncStage.preparingLocalSnapshot,
      stepIndex: 1,
      totalSteps: _totalProgressSteps,
      title: 'Подготовка локального снимка',
      description: 'Собираем локальный snapshot и обновляем manifest-файлы.',
    );
  }

  SnapshotSyncProgress _checkingRemoteVersionProgress() {
    return const SnapshotSyncProgress(
      stage: SnapshotSyncStage.checkingRemoteVersion,
      stepIndex: 2,
      totalSteps: _totalProgressSteps,
      title: 'Проверка облачной версии',
      description: 'Читаем удалённый manifest и сравниваем версии.',
    );
  }

  SnapshotSyncProgress _primaryTransferProgress({
    required SnapshotSyncTransferDirection direction,
    SnapshotSyncTransferProgress? transferProgress,
  }) {
    return SnapshotSyncProgress(
      stage: SnapshotSyncStage.transferringPrimaryFiles,
      stepIndex: 3,
      totalSteps: _totalProgressSteps,
      title: direction == SnapshotSyncTransferDirection.upload
          ? 'Загрузка в облако'
          : 'Скачивание из облака',
      description: direction == SnapshotSyncTransferDirection.upload
          ? 'Передаём базу данных и ключ шифрования.'
          : 'Скачиваем основные файлы хранилища.',
      transferProgress: transferProgress,
    );
  }

  SnapshotSyncProgress _attachmentsProgress({
    required SnapshotSyncTransferDirection direction,
    SnapshotSyncTransferProgress? transferProgress,
  }) {
    return SnapshotSyncProgress(
      stage: SnapshotSyncStage.syncingAttachments,
      stepIndex: 4,
      totalSteps: _totalProgressSteps,
      title: 'Синхронизация вложений',
      description: direction == SnapshotSyncTransferDirection.upload
          ? 'Загружаем изменённые вложения и удаляем устаревшие remote-файлы.'
          : 'Скачиваем вложения и удаляем лишние локальные файлы.',
      transferProgress: transferProgress,
    );
  }

  SnapshotSyncProgress _metadataProgress() {
    return const SnapshotSyncProgress(
      stage: SnapshotSyncStage.updatingMetadata,
      stepIndex: 5,
      totalSteps: _totalProgressSteps,
      title: 'Обновление метаданных',
      description:
          'Сохраняем manifest-файлы и обновляем сведения о snapshot в облаке.',
    );
  }

  SnapshotSyncProgress _completedProgress(SnapshotSyncResult result) {
    final description = switch (result.type) {
      SnapshotSyncResultType.uploaded =>
        'Локальная snapshot-версия загружена в облако.',
      SnapshotSyncResultType.downloaded =>
        'Удалённая snapshot-версия применена локально.',
      SnapshotSyncResultType.noChanges =>
        'Локальная и удалённая версии уже совпадают.',
      SnapshotSyncResultType.conflict => 'Обнаружен конфликт версий.',
      SnapshotSyncResultType.idle => 'Операция завершена.',
    };

    return SnapshotSyncProgress(
      stage: SnapshotSyncStage.completed,
      stepIndex: _totalProgressSteps,
      totalSteps: _totalProgressSteps,
      title: 'Завершено',
      description: description,
    );
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

  List<CloudManifestStoreEntry> _markCloudEntryDeleted(
    List<CloudManifestStoreEntry> entries,
    CloudManifestStoreEntry target, {
    required DateTime updatedAt,
  }) {
    final updated = <CloudManifestStoreEntry>[];
    var replaced = false;

    for (final entry in entries) {
      if (entry.storeUuid != target.storeUuid) {
        updated.add(entry);
        continue;
      }

      updated.add(
        CloudManifestStoreEntry(
          storeUuid: entry.storeUuid,
          storeName: entry.storeName,
          revision: entry.revision,
          updatedAt: updatedAt,
          snapshotId: entry.snapshotId,
          remoteStoreId: entry.remoteStoreId,
          remotePath: entry.remotePath,
          manifestSha256: entry.manifestSha256,
          deleted: true,
        ),
      );
      replaced = true;
    }

    if (!replaced) {
      updated.add(
        CloudManifestStoreEntry(
          storeUuid: target.storeUuid,
          storeName: target.storeName,
          revision: target.revision,
          updatedAt: updatedAt,
          snapshotId: target.snapshotId,
          remoteStoreId: target.remoteStoreId,
          remotePath: target.remotePath,
          manifestSha256: target.manifestSha256,
          deleted: true,
        ),
      );
    }

    updated.sort((left, right) => left.storeUuid.compareTo(right.storeUuid));
    return updated;
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
