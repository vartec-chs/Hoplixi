import 'package:result_dart/result_dart.dart';

import 'package:hoplixi/vault_db/core/config/store_settings_keys.dart';
import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/store_meta_dto.dart';
import 'package:hoplixi/vault_db/core/repositories/base/system/store_settings_repository.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/system/store/store_settings.dart';
import 'package:hoplixi/vault_db/core/services/system/store_meta_service.dart';
import 'package:hoplixi/vault_db/core/services/vault_entity_services.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:hoplixi/vault_db/services/main_store_storage_service.dart';
import 'package:hoplixi/vault_db/services/other/file_storage_service.dart';
import 'package:hoplixi/vault_db/usecases/perform_store_cleanup.dart';

/// Public API boundary for store metadata and settings.
class VaultStoreApi {
  const VaultStoreApi({
    required this._db,
    required this._metaService,
    required this._settingsRepository,
    required this._entityServices,
    required this._repositories,
  });

  final VaultDB _db;
  final StoreMetaService _metaService;
  final StoreSettingsRepository _settingsRepository;
  final VaultEntityServices _entityServices;
  final VaultRepositories _repositories;

  AsyncDBResult<StoreInfoDto> getStoreInfo() {
    return _metaService.getStoreInfo();
  }

  AsyncDBResult<StoreMetaDto> getStoreMeta() {
    return _metaService.getStoreMeta();
  }

  AsyncDBResult<Unit> updateInfo({required String name, String? description}) {
    return _metaService.updateInfo(name: name, description: description);
  }

  AsyncDBResult<Unit> changePassword({
    required String newPassword,
    required String newPragmaKey,
  }) {
    return _metaService.changePassword(
      newPassword: newPassword,
      newPragmaKey: newPragmaKey,
    );
  }

  AsyncDBResult<Unit> updateLastOpened() {
    return _metaService.updateLastOpened();
  }

  AsyncDBResult<Optional<String>> getRawSetting(String key) {
    return _settingsRepository.getRawValue(key);
  }

  AsyncDBResult<Unit> setRawSetting({
    required String key,
    required String value,
    StoreSettingValueType valueType = StoreSettingValueType.string,
  }) {
    return _settingsRepository.setRawValue(
      key: key,
      value: value,
      valueType: valueType,
    );
  }

  AsyncDBResult<Unit> deleteSetting(String key) {
    return _settingsRepository.deleteSetting(key);
  }

  AsyncDBResult<List<StoreSettingData>> getAllSettings() {
    return _settingsRepository.getAllSettings();
  }

  AsyncDBResult<Optional<T>> getSetting<T extends Object>(
    StoreSettingsKey<T> key,
  ) {
    return _settingsRepository.get(key);
  }

  AsyncDBResult<T> getSettingOrDefault<T extends Object>(
    StoreSettingsKey<T> key,
  ) {
    return _settingsRepository.getOrDefault(key);
  }

  AsyncDBResult<Unit> setSetting<T>(StoreSettingsKey<T> key, T value) {
    return _settingsRepository.set(key, value);
  }

  AsyncDBResult<Unit> initializeDefaultSettings() {
    return _settingsRepository.initializeDefaults();
  }

  AsyncDBResult<Unit> repairSettings() {
    return _settingsRepository.repairSettings();
  }

  Future<StoreCleanupResult> performCleanup({
    required String storePath,
    bool ignoreInterval = false,
  }) {
    const storageService = VaultDBFileService();
    final fileStorageService = FileStorageService(
      db: _db,
      attachmentsPath: storageService.getAttachmentsPath(storePath),
      decryptedAttachmentsPath: storageService.getDecryptedAttachmentsPath(
        storePath,
      ),
      fileService: _entityServices.file,
      fileRepository: _repositories.file,
      fileMetadataRepository: _repositories.fileMetadata,
    );

    final cleanup = PerformStoreCleanup(
      settingsDao: _db.storeSettingsDao,
      fileStorageService: fileStorageService,
    );

    return cleanup(ignoreInterval: ignoreInterval);
  }
}
