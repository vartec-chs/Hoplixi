import 'dart:io';

import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/models.dart' as logger_models;
import 'package:hoplixi/main_db/core/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_db/services/main_store_storage_service.dart';
import 'package:hoplixi/main_db/services/store_manifest_service/model/store_manifest.dart';
import 'package:hoplixi/main_db/services/store_manifest_service/store_manifest_service.dart';

import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/attachments_manifest.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/attachments_manifest_file_service.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/snapshot_sync_hash_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class LocalStoreSnapshot {
  const LocalStoreSnapshot({
    required this.storeManifest,
    required this.attachmentsManifest,
    required this.dbFile,
  });

  final StoreManifest storeManifest;
  final AttachmentsManifest attachmentsManifest;
  final File dbFile;
}

class StoreSnapshotManifestBuilder {
  StoreSnapshotManifestBuilder({
    SnapshotSyncHashService? hashService,
    Uuid? uuid,
    Future<logger_models.DeviceInfo> Function()? deviceInfoLoader,
    Future<PackageInfo> Function()? packageInfoLoader,
  }) : _hashService = hashService ?? const SnapshotSyncHashService(),
       _uuid = uuid ?? const Uuid(),
       _deviceInfoLoader = deviceInfoLoader ?? logger_models.DeviceInfo.collect,
       _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform;

  final SnapshotSyncHashService _hashService;
  final Uuid _uuid;
  final Future<logger_models.DeviceInfo> Function() _deviceInfoLoader;
  final Future<PackageInfo> Function() _packageInfoLoader;
  final MainStoreFileService _storageService = const MainStoreFileService();

  Future<LocalStoreSnapshot> buildAndPersist({
    required String storePath,
    required StoreInfoDto storeInfo,
    bool persist = true,
    bool allowRevisionBump = true,
  }) async {
    final deviceInfo = await _deviceInfoLoader();
    final packageInfo = await _packageInfoLoader();
    final existingManifest = await StoreManifestService.readFrom(storePath);
    final existingAttachmentsManifest =
        await AttachmentsManifestFileService.readFrom(storePath);
    final dbFilePath = await _storageService.findDatabaseFile(storePath);
    if (dbFilePath == null) {
      throw StateError('Database file was not found for store at $storePath.');
    }

    final dbFile = File(dbFilePath);
    final dbHash = await _hashService.sha256ForFile(dbFile);

    final draftAttachmentsManifest = await _buildAttachmentsManifest(
      storePath: storePath,
      storeUuid: storeInfo.id,
      revision: existingManifest?.revision ?? 0,
    );

    final candidateLastModifiedBy = StoreManifestLastModifiedBy(
      deviceId: deviceInfo.deviceId,
      clientInstanceId: _buildClientInstanceId(deviceInfo, packageInfo),
      appVersion: packageInfo.version,
    );

    final storeModifiedAt = storeInfo.modifiedAt.toUtc();
    final existingDbFile = existingManifest?.content.dbFile;
    final dbChangedLogically =
        existingManifest == null ||
        existingDbFile?.modifiedAt == null ||
        existingDbFile!.modifiedAt!.toUtc() != storeModifiedAt;
    final needsSnapshotBump =
        allowRevisionBump &&
        (existingManifest == null ||
            existingManifest.storeName != storeInfo.name ||
            dbChangedLogically ||
            existingManifest.content.attachments.filesHash !=
                draftAttachmentsManifest.filesHash);

    final nextRevision = needsSnapshotBump
        ? ((existingManifest?.revision ?? 0) + 1)
        : (existingManifest?.revision ?? 0);
    final attachmentsManifest = AttachmentsManifest(
      version: draftAttachmentsManifest.version,
      storeUuid: draftAttachmentsManifest.storeUuid,
      revision: nextRevision,
      updatedAt:
          existingAttachmentsManifest != null &&
              existingAttachmentsManifest.filesHash ==
                  draftAttachmentsManifest.filesHash &&
              existingAttachmentsManifest.revision == nextRevision
          ? existingAttachmentsManifest.updatedAt
          : draftAttachmentsManifest.updatedAt,
      filesHash: draftAttachmentsManifest.filesHash,
      files: draftAttachmentsManifest.files,
    );

    final candidateDbFile = !dbChangedLogically
        ? existingDbFile.copyWith(fileName: p.basename(dbFile.path))
        : StoreManifestDbFileContent(
            fileName: p.basename(dbFile.path),
            size: await dbFile.length(),
            sha256: dbHash,
            modifiedAt: storeModifiedAt,
          );

    final candidateContent = StoreManifestContent(
      dbFile: candidateDbFile,
      attachments: StoreManifestAttachmentsContent(
        count: attachmentsManifest.files.where((file) => !file.deleted).length,
        totalSize: attachmentsManifest.files
            .where((file) => !file.deleted)
            .fold<int>(0, (sum, file) => sum + file.size),
        manifestSha256: _hashService.sha256ForJson(
          attachmentsManifest.toJson(),
        ),
        filesHash: attachmentsManifest.filesHash,
      ),
    );

    final storeManifest =
        (existingManifest ??
                StoreManifest.initial(
                  lastMigrationVersion: MainConstants.databaseSchemaVersion,
                  appVersion: packageInfo.version,
                  storeUuid: storeInfo.id,
                  storeName: storeInfo.name,
                  updatedAt: storeModifiedAt,
                  lastModifiedBy: candidateLastModifiedBy,
                ))
            .copyWith(
              manifestVersion: MainConstants.storeManifestVersion,
              lastMigrationVersion: MainConstants.databaseSchemaVersion,
              appVersion: packageInfo.version,
              storeUuid: storeInfo.id,
              storeName: storeInfo.name,
              revision: nextRevision,
              updatedAt: needsSnapshotBump
                  ? DateTime.now().toUtc()
                  : (existingManifest?.updatedAt ?? storeModifiedAt),
              snapshotId: needsSnapshotBump
                  ? _uuid.v4()
                  : (existingManifest?.snapshotId ?? ''),
              lastModifiedBy: needsSnapshotBump
                  ? candidateLastModifiedBy
                  : (existingManifest?.lastModifiedBy ??
                        candidateLastModifiedBy),
              sync: existingManifest?.sync,
              keyConfig: existingManifest?.keyConfig,
              content: candidateContent,
            );

    if (persist) {
      await StoreManifestService.writeTo(storePath, storeManifest);
      await AttachmentsManifestFileService.writeTo(
        storePath,
        attachmentsManifest,
      );
    }

    return LocalStoreSnapshot(
      storeManifest: storeManifest,
      attachmentsManifest: attachmentsManifest,
      dbFile: dbFile,
    );
  }

  Future<AttachmentsManifest> _buildAttachmentsManifest({
    required String storePath,
    required String storeUuid,
    required int revision,
  }) async {
    final attachmentsDir = Directory(
      _storageService.getAttachmentsPath(storePath),
    );
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final files = <AttachmentManifestEntry>[];
    final entities = await attachmentsDir.list(followLinks: false).toList();
    entities.sort((left, right) => left.path.compareTo(right.path));

    for (final entity in entities) {
      if (entity is! File) {
        continue;
      }
      final stat = await entity.stat();
      files.add(
        AttachmentManifestEntry(
          fileName: p.basename(entity.path),
          size: stat.size,
          sha256: await _hashService.sha256ForFile(entity),
          updatedAt: stat.modified.toUtc(),
        ),
      );
    }

    final aggregateSource = files
        .map(
          (entry) =>
              '${entry.fileName}:${entry.size}:${entry.sha256}:${entry.deleted}',
        )
        .join('|');
    final filesHash = _hashService.sha256ForString(aggregateSource);

    return AttachmentsManifest(
      version: 1,
      storeUuid: storeUuid,
      revision: revision,
      updatedAt: DateTime.now().toUtc(),
      filesHash: filesHash,
      files: files,
    );
  }

  String _buildClientInstanceId(
    logger_models.DeviceInfo deviceInfo,
    PackageInfo packageInfo,
  ) {
    return '${deviceInfo.deviceId}:${packageInfo.packageName}';
  }
}
