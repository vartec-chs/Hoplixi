import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/logger.dart' hide Session;
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/db_ciphers.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/models/session.dart';
import 'package:hoplixi/main_db/models/store_key_config.dart';
import 'package:hoplixi/main_db/services/db_key_derivation_service.dart';
import 'package:hoplixi/main_db/services/main_store_compatibility_service/main_store_compatibility_service.dart';
import 'package:hoplixi/main_db/services/main_store_compatibility_service/model/store_open_compatibility.dart';
import 'package:hoplixi/main_db/services/main_store_connection_service.dart';
import 'package:hoplixi/main_db/services/main_store_storage_service.dart';
import 'package:hoplixi/main_db/services/store_manifest_service/model/store_manifest.dart';
import 'package:hoplixi/main_db/services/store_manifest_service/store_manifest_service.dart';
import 'package:hoplixi/main_db/usecases/utils/error_handling.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:result_dart/result_dart.dart';

class OpenMainStore {
  static const String _logTag = 'OpenMainStore';

  final MainStoreConnectionService _connectionService;
  final DbKeyDerivationService _keyService;
  final MainStoreFileService _storageService;
  final MainStoreCompatibilityService _compatibilityService;

  OpenMainStore({
    MainStoreConnectionService? connectionService,
    DbKeyDerivationService? keyService,
    MainStoreFileService? storageService,
    MainStoreCompatibilityService? compatibilityService,
  }) : _connectionService = connectionService ?? MainStoreConnectionService(),
       _keyService =
           keyService ?? DbKeyDerivationService(getIt<FlutterSecureStorage>()),
       _storageService = storageService ?? const MainStoreFileService(),
       _compatibilityService =
           compatibilityService ?? const MainStoreCompatibilityService();

  AsyncResultDart<Session, AppError> call({
    required OpenStoreDto dto,
    required String masterPassword,
    bool allowMigration = false,
  }) async {
    MainStore? store;

    try {
      logInfo('Opening store', tag: _logTag, data: {'path': dto.path});

      final actualStoragePath = await _storageService
          .resolveExistingStoragePath(dto.path);
      final dbFilePath = await _storageService.findDatabaseFile(
        actualStoragePath,
      );
      if (dbFilePath == null) {
        return Failure(
          AppError.mainDatabase(
            code: MainDatabaseErrorCode.recordNotFound,
            message: 'Файл базы данных не найден в директории',
            data: {'path': actualStoragePath},
            timestamp: DateTime.now(),
          ),
        );
      }

      final manifest = await StoreManifestService.readFrom(actualStoragePath);
      final compatibility = await _compatibilityService.checkOpenCompatibility(
        manifest,
      );
      final compatibilityError = _compatibilityService.buildCompatibilityError(
        compatibility: compatibility,
        storagePath: actualStoragePath,
        allowMigration: allowMigration,
      );
      if (compatibilityError != null) {
        return Failure(compatibilityError);
      }

      final keyConfig = manifest?.keyConfig;
      if (manifest == null || keyConfig == null) {
        return Failure(
          AppError.mainDatabase(
            code: MainDatabaseErrorCode.recordNotFound,
            message: 'В store_manifest.json не найден keyConfig',
            data: {'path': actualStoragePath},
            timestamp: DateTime.now(),
          ),
        );
      }
      final keyFileValidationError = validateKeyFileForOpen(
        dto: dto,
        manifest: manifest,
      );
      if (keyFileValidationError != null) {
        return Failure(keyFileValidationError);
      }

      final pragmaKey = await _keyService.derivePragmaKey(
        masterPassword,
        keyConfig.argon2Salt,
        useDeviceKey: keyConfig.useDeviceKey,
        keyFileSecret: manifest.useKeyFile ? dto.keyFileSecret : null,
        kdfVersion: keyConfig.kdfVersion,
      );
      final connection = await _openDatabase(
        dbFilePath: dbFilePath,
        pragmaKey: pragmaKey,
        keyConfig: keyConfig,
      );
      if (connection.result.isError()) {
        return Failure(connection.result.exceptionOrNull()!);
      }

      store = connection.result.getOrThrow();
      final effectiveKeyConfig = keyConfig.copyWith(
        cipher: connection.selectedCipher,
      );

      if (connection.selectedCipher != keyConfig.cipher ||
          compatibility.requiresMigration) {
        await _writeUpdatedManifest(
          storagePath: actualStoragePath,
          manifest: manifest,
          keyConfig: effectiveKeyConfig,
          compatibility: compatibility,
        );
      }

      await store.storeMetaDao.updateLastOpenedAt();
      final info = await _readStoreInfo(store);

      logInfo('Store opened successfully', tag: _logTag);
      return Success((
        store: store,
        info: info,
        storeDirectoryPath: actualStoragePath,
      ));
    } catch (error, stackTrace) {
      await _closeStoreAfterFailure(store);

      return handleMainStoreUseCaseError(
        message: 'Failed to open store',
        error: error,
        stackTrace: stackTrace,
        tag: _logTag,
      );
    }
  }

  Future<({ResultDart<MainStore, AppError> result, DBCipher selectedCipher})>
  _openDatabase({
    required String dbFilePath,
    required String pragmaKey,
    required StoreKeyConfig keyConfig,
  }) async {
    var selectedCipher = keyConfig.cipher ?? DBCipher.chacha20;
    var result = await _connectionService.createDatabaseConnection(
      dbFilePath,
      pragmaKey,
      cipher: selectedCipher,
    );

    if (result.isSuccess()) {
      return (result: result, selectedCipher: selectedCipher);
    }

    for (final fallbackCipher in DBCipher.values) {
      if (fallbackCipher == selectedCipher) {
        continue;
      }

      logInfo(
        'Primary cipher failed, trying fallback cipher: ${fallbackCipher.name}',
        tag: _logTag,
      );
      final fallbackResult = await _connectionService.createDatabaseConnection(
        dbFilePath,
        pragmaKey,
        cipher: fallbackCipher,
      );

      if (fallbackResult.isSuccess()) {
        result = fallbackResult;
        selectedCipher = fallbackCipher;
        break;
      }
    }

    return (result: result, selectedCipher: selectedCipher);
  }

  Future<StoreInfoDto> _readStoreInfo(MainStore store) async {
    final meta = await store.storeMetaDao.getStoreMeta();
    if (meta == null) {
      throw AppError.mainDatabase(
        code: MainDatabaseErrorCode.recordNotFound,
        message: 'Метаданные хранилища не найдены',
        timestamp: DateTime.now(),
      );
    }

    return StoreInfoDto(
      id: meta.id,
      name: meta.name,
      description: meta.description,
      createdAt: meta.createdAt,
      modifiedAt: meta.modifiedAt,
      lastOpenedAt: meta.lastOpenedAt,
      version: meta.version,
    );
  }

  static AppError? validateKeyFileForOpen({
    required OpenStoreDto dto,
    required StoreManifest manifest,
  }) {
    try {
      manifest.validateKeyFileSettings();
    } on ArgumentError catch (error, stackTrace) {
      return AppError.validation(
        code: ValidationErrorCode.invalidInput,
        message: error.message?.toString() ?? 'Некорректные настройки key file',
        cause: error,
        stackTrace: stackTrace,
        timestamp: DateTime.now(),
      );
    }

    if (!manifest.useKeyFile) {
      return null;
    }

    final selectedKeyFileId = dto.keyFileId?.trim();
    if (selectedKeyFileId == null ||
        selectedKeyFileId.isEmpty ||
        dto.keyFileSecret == null ||
        dto.keyFileSecret!.isEmpty) {
      return AppError.validation(
        code: ValidationErrorCode.emptyField,
        message: 'Для открытия этого хранилища выберите JSON key file',
        timestamp: DateTime.now(),
      );
    }

    if (selectedKeyFileId != manifest.keyFileId) {
      return AppError.validation(
        code: ValidationErrorCode.invalidInput,
        message: 'Выбранный JSON key file не подходит для этого хранилища',
        timestamp: DateTime.now(),
      );
    }

    return null;
  }

  Future<void> _writeUpdatedManifest({
    required String storagePath,
    required StoreManifest manifest,
    required StoreKeyConfig keyConfig,
    required StoreOpenCompatibility compatibility,
  }) async {
    try {
      await StoreManifestService.writeTo(
        storagePath,
        manifest.copyWith(
          manifestVersion: MainConstants.storeManifestVersion,
          lastMigrationVersion: MainConstants.databaseSchemaVersion,
          appVersion: compatibility.currentAppVersion,
          updatedAt: DateTime.now().toUtc(),
          keyConfig: keyConfig,
        ),
      );
      logInfo('Updated store_manifest.json after openStore', tag: _logTag);
    } catch (error, stackTrace) {
      throw AppError.mainDatabase(
        code: MainDatabaseErrorCode.queryFailed,
        message: 'Не удалось обновить store_manifest.json: $error',
        cause: error,
        stackTrace: stackTrace,
        timestamp: DateTime.now(),
      );
    }
  }

  Future<void> _closeStoreAfterFailure(MainStore? store) async {
    if (store == null) {
      return;
    }

    try {
      await store.close();
    } catch (error, stackTrace) {
      logWarning(
        'Failed to close store after openStore error',
        tag: _logTag,
        data: {'error': error.toString(), 'stackTrace': stackTrace.toString()},
      );
    }
  }
}
