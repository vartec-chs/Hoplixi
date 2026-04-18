import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/models.dart' as logger_models;
import 'package:hoplixi/db_core/main_store.dart';
import 'package:hoplixi/db_core/models/db_ciphers.dart';
import 'package:hoplixi/db_core/models/db_errors.dart';
import 'package:hoplixi/db_core/models/store_key_config.dart';
import 'package:hoplixi/db_core/models/store_manifest.dart';
import 'package:hoplixi/db_core/services/main_store_metadata_service.dart';
import 'package:hoplixi/db_core/services/store_manifest_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MainStoreManifestSyncService {
  final MainStoreMetadataService _metadataService;

  MainStoreManifestSyncService({MainStoreMetadataService? metadataService})
    : _metadataService = metadataService ?? MainStoreMetadataService();

  Future<void> writeForOpenedStore({
    required MainStore database,
    required String storagePath,
    StoreKeyConfig? keyConfig,
  }) async {
    final storeInfoResult = await _metadataService.getStoreInfo(database);
    if (storeInfoResult.isError()) {
      throw storeInfoResult.fold(
        (_) => DatabaseError.queryFailed(
          message: 'Не удалось получить информацию о хранилище для манифеста',
          timestamp: DateTime.now(),
        ),
        (error) => error,
      );
    }

    final storeInfo = storeInfoResult.getOrThrow();
    final existingManifest = await StoreManifestService.readFrom(storagePath);
    final deviceInfo = await logger_models.DeviceInfo.collect();
    final packageInfo = await PackageInfo.fromPlatform();
    final currentAppVersion = packageInfo.version;
    const currentMigrationVersion = MainConstants.databaseSchemaVersion;
    final lastModifiedBy = StoreManifestLastModifiedBy(
      deviceId: deviceInfo.deviceId,
      clientInstanceId: '${deviceInfo.deviceId}:${packageInfo.packageName}',
      appVersion: currentAppVersion,
    );

    final persistedLastModifiedBy = existingManifest?.lastModifiedBy;
    final hasPersistedLastModifiedBy =
        persistedLastModifiedBy != null &&
        persistedLastModifiedBy.deviceId.isNotEmpty;

    final manifest =
        existingManifest?.copyWith(
          manifestVersion: MainConstants.storeManifestVersion,
          lastMigrationVersion: currentMigrationVersion,
          appVersion: currentAppVersion,
          storeUuid: storeInfo.id,
          storeName: storeInfo.name,
          updatedAt: storeInfo.modifiedAt.toUtc(),
          lastModifiedBy: hasPersistedLastModifiedBy
              ? persistedLastModifiedBy
              : lastModifiedBy,
          keyConfig: keyConfig ?? existingManifest.keyConfig,
        ) ??
        StoreManifest.initial(
          lastMigrationVersion: currentMigrationVersion,
          appVersion: currentAppVersion,
          storeUuid: storeInfo.id,
          storeName: storeInfo.name,
          updatedAt: storeInfo.modifiedAt.toUtc(),
          lastModifiedBy: lastModifiedBy,
          keyConfig: keyConfig,
        );

    try {
      await StoreManifestService.writeTo(storagePath, manifest);
    } catch (e, stackTrace) {
      throw DatabaseError.updateFailed(
        message: 'Не удалось записать store_manifest.json: $e',
        timestamp: DateTime.now(),
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> updateDetectedCipher({
    required String storagePath,
    required StoreManifest manifest,
    required StoreKeyConfig keyConfig,
    required DBCipher cipher,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();

    await StoreManifestService.writeTo(
      storagePath,
      manifest.copyWith(
        manifestVersion: MainConstants.storeManifestVersion,
        lastMigrationVersion: MainConstants.databaseSchemaVersion,
        appVersion: packageInfo.version,
        keyConfig: keyConfig.copyWith(cipher: cipher),
      ),
    );
  }
}
