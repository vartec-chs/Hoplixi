import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/logger/models.dart' as logger_models;
import 'package:hoplixi/db_core/main_store.dart';
import 'package:hoplixi/db_core/models/db_ciphers.dart';
import 'package:hoplixi/db_core/models/db_errors.dart';
import 'package:hoplixi/db_core/models/dto/main_store_dto.dart';
import 'package:hoplixi/db_core/models/store_key_config.dart';
import 'package:hoplixi/db_core/models/store_manifest.dart';
import 'package:hoplixi/db_core/services/db_history_services.dart';
import 'package:hoplixi/db_core/services/db_key_derivation_service.dart';
import 'package:hoplixi/db_core/services/main_store_connection_service.dart';
import 'package:hoplixi/db_core/services/main_store_metadata_service.dart';
import 'package:hoplixi/db_core/services/main_store_storage_service.dart';
import 'package:hoplixi/db_core/services/store_manifest_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:result_dart/result_dart.dart';

/// Менеджер для управления хранилищами MainStore
///
/// Отвечает за создание, открытие, закрытие и управление
/// зашифрованными хранилищами паролей на основе Drift + SQLite3 Multiple Ciphers
class MainStoreManager {
  static const String _logTag = 'MainStoreManager';

  final DatabaseHistoryService _dbHistoryService;
  final DbKeyDerivationService _keyService;
  final MainStoreStorageService _storageService;
  final MainStoreConnectionService _connectionService;
  final MainStoreMetadataService _metadataService;

  MainStore? _currentStore;
  String? _currentStorePath;

  MainStoreManager(
    this._dbHistoryService,
    this._keyService, {
    MainStoreStorageService? storageService,
    MainStoreConnectionService? connectionService,
    MainStoreMetadataService? metadataService,
  }) : _storageService = storageService ?? MainStoreStorageService(),
       _connectionService = connectionService ?? MainStoreConnectionService(),
       _metadataService = metadataService ?? MainStoreMetadataService();

  /// Проверка, открыто ли хранилище
  bool get isStoreOpen => _currentStore != null && _currentStorePath != null;

  /// Получить текущий путь к хранилищу
  String? get currentStorePath => _currentStorePath;

  MainStore? get currentStore => _currentStore;

  Future<String> resolveStoragePath(String path) {
    return _storageService.resolveExistingStoragePath(path);
  }

  /// Создать новое хранилище
  ///
  /// [dto] - данные для создания хранилища
  /// Возвращает информацию о созданном хранилище или ошибку
  AsyncResultDart<StoreInfoDto, DatabaseError> createStore(
    CreateStoreDto dto,
  ) async {
    try {
      logInfo('Creating new store: ${dto.name}', tag: _logTag);

      // Проверка, открыто ли уже хранилище
      if (isStoreOpen) {
        return Failure(
          DatabaseError.alreadyInitialized(
            message:
                'Хранилище уже открыто. Закройте текущее перед созданием нового.',
            timestamp: DateTime.now(),
          ),
        );
      }

      final storagePath = await AppPaths.appStoragesPath;
      final preparedStorage = await _storageService.prepareNewStorageDirectory(
        baseStoragePath: storagePath,
        storeName: dto.name,
      );
      final storageDir = preparedStorage.storageDir;

      final argon2Salt = DbKeyDerivationService.generateSalt();

      final keyConfig = StoreKeyConfig(
        argon2Salt: argon2Salt,
        useDeviceKey: dto.useDeviceKey,
        cipher: dto.cipher,
      );
      logInfo(
        'Prepared store manifest key config (useDeviceKey=${dto.useDeviceKey}, cipher=${dto.cipher.name})',
        tag: _logTag,
      );

      final pragmaKey = await _keyService.derivePragmaKey(
        dto.password,
        argon2Salt,
        useDeviceKey: dto.useDeviceKey,
      );

      final dbFilePath = _storageService.getDatabaseFilePath(
        storageDir.path,
        preparedStorage.normalizedName,
      );

      final dbResult = await _connectionService.createDatabaseConnection(
        dbFilePath,
        pragmaKey,
        cipher: dto.cipher,
        isDatabaseCreation: true,
      );

      if (dbResult.isError()) {
        await _storageService.deleteStorageDirectory(storageDir.path);
        return dbResult.fold(
          (_) => Success(
            StoreInfoDto(
              id: '',
              name: '',
              createdAt: DateTime.now(),
              modifiedAt: DateTime.now(),
              lastOpenedAt: DateTime.now(),
              version: '',
            ),
          ),
          (error) => Failure(error),
        );
      }

      final database = dbResult.getOrThrow();
      _currentStore = database;
      _currentStorePath = storageDir.path;

      final storeId = await _metadataService.createStoreMetadata(
        database: database,
        name: dto.name,
        description: dto.description,
        password: dto.password,
      );

      logInfo('Created store metadata with id: $storeId', tag: _logTag);

      try {
        await _writeCurrentStoreManifest(keyConfig: keyConfig);
        logInfo('Wrote store_manifest.json', tag: _logTag);
      } on DatabaseError {
        await database.close();
        _currentStore = null;
        _currentStorePath = null;
        await _storageService.deleteStorageDirectory(storageDir.path);
        rethrow;
      }

      // Добавление в историю
      await _dbHistoryService.create(
        path: storageDir.path,
        dbId: storeId,
        name: dto.name,
        description: dto.description,
        password: dto.saveMasterPassword ? dto.password : null,
        savePassword: dto.saveMasterPassword,
      );

      logInfo('Store created successfully: ${dto.name}', tag: _logTag);

      // Получение информации о созданном хранилище
      return getStoreInfo();
    } on DatabaseError catch (e) {
      return Failure(e);
    } catch (e, stackTrace) {
      logError(
        'Failed to create store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.unknown(
          message: 'Не удалось создать хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Открыть существующее хранилище
  ///
  /// [dto] - данные для открытия хранилища
  /// Возвращает информацию о хранилище или ошибку
  AsyncResultDart<StoreInfoDto, DatabaseError> openStore(
    OpenStoreDto dto, {
    bool allowMigration = false,
  }) async {
    try {
      logInfo('Opening store at: ${dto.path}', tag: _logTag);

      final actualStoragePath = await _storageService
          .resolveExistingStoragePath(dto.path);

      final dbFilePath = await _storageService.findDatabaseFile(
        actualStoragePath,
      );
      if (dbFilePath == null) {
        return Failure(
          DatabaseError.recordNotFound(
            message: 'Файл базы данных не найден в директории',
            data: {'path': actualStoragePath},
            timestamp: DateTime.now(),
          ),
        );
      }

      logInfo('Found database file: $dbFilePath', tag: _logTag);

      final manifest = await StoreManifestService.readFrom(actualStoragePath);
      final compatibility = await _checkStoreOpenCompatibility(manifest);
      final compatibilityError = _buildCompatibilityError(
        compatibility: compatibility,
        storagePath: actualStoragePath,
        allowMigration: allowMigration,
      );
      if (compatibilityError != null) {
        return Failure(compatibilityError);
      }

      final keyConfig = manifest?.keyConfig;
      if (keyConfig == null) {
        return Failure(
          DatabaseError.recordNotFound(
            message: 'В store_manifest.json не найден keyConfig',
            data: {'path': actualStoragePath},
            timestamp: DateTime.now(),
          ),
        );
      }

      // Проверка, открыто ли уже хранилище
      if (isStoreOpen) {
        await _closeCurrentStore();
      }

      var selectedCipher = keyConfig.cipher ?? DBCipher.chacha20;
      final pragmaKey = await _keyService.derivePragmaKey(
        dto.password,
        keyConfig.argon2Salt,
        useDeviceKey: keyConfig.useDeviceKey,
      );
      logInfo(
        'Derived Argon2 PRAGMA key from store_manifest.json (useDeviceKey=${keyConfig.useDeviceKey}, cipher=${selectedCipher.name})',
        tag: _logTag,
      );

      final dbResult = await _connectionService.createDatabaseConnection(
        dbFilePath,
        pragmaKey,
        cipher: selectedCipher,
      );

      ResultDart<MainStore, DatabaseError> effectiveDbResult = dbResult;

      // Если первичный cipher не подошел, пробуем альтернативные и сохраняем успешный.
      if (effectiveDbResult.isError()) {
        for (final fallbackCipher in DBCipher.values) {
          if (fallbackCipher == selectedCipher) {
            continue;
          }

          logInfo(
            'Primary cipher failed, trying fallback cipher: ${fallbackCipher.name}',
            tag: _logTag,
          );

          final fallbackResult = await _connectionService
              .createDatabaseConnection(
                dbFilePath,
                pragmaKey,
                cipher: fallbackCipher,
              );

          if (fallbackResult.isSuccess()) {
            effectiveDbResult = fallbackResult;
            selectedCipher = fallbackCipher;
            final packageInfo = await PackageInfo.fromPlatform();

            await StoreManifestService.writeTo(
              actualStoragePath,
              manifest!.copyWith(
                manifestVersion: MainConstants.storeManifestVersion,
                lastMigrationVersion: MainConstants.databaseSchemaVersion,
                appVersion: packageInfo.version,
                keyConfig: keyConfig.copyWith(cipher: fallbackCipher),
              ),
            );
            logInfo(
              'Updated store_manifest.json with detected cipher: ${fallbackCipher.name}',
              tag: _logTag,
            );
            break;
          }
        }
      }

      if (effectiveDbResult.isError()) {
        return effectiveDbResult.fold(
          (_) => Success(
            StoreInfoDto(
              id: '',
              name: '',
              createdAt: DateTime.now(),
              modifiedAt: DateTime.now(),
              lastOpenedAt: DateTime.now(),
              version: '',
            ),
          ),
          (error) => Failure(error),
        );
      }

      final database = effectiveDbResult.getOrThrow();
      final effectiveKeyConfig = keyConfig.copyWith(cipher: selectedCipher);

      final storeMetaResult = await _metadataService.getStoreMeta(database);
      if (storeMetaResult.isError()) {
        await database.close();
        return storeMetaResult.fold(
          (_) => Success(
            StoreInfoDto(
              id: '',
              name: '',
              createdAt: DateTime.now(),
              modifiedAt: DateTime.now(),
              lastOpenedAt: DateTime.now(),
              version: '',
            ),
          ),
          (error) => Failure(error),
        );
      }

      final storeMeta = storeMetaResult.getOrThrow();

      _currentStore = database;
      _currentStorePath = actualStoragePath;

      await _metadataService.updateLastOpenedAt(database);

      if (allowMigration && compatibility.requiresMigration) {
        await _writeCurrentStoreManifest(keyConfig: effectiveKeyConfig);
        logInfo(
          'Updated store_manifest.json after compatibility migration',
          tag: _logTag,
        );
      }

      final existingHistory = await _dbHistoryService.getByPath(
        actualStoragePath,
      );
      if (existingHistory == null) {
        await _dbHistoryService.create(
          path: actualStoragePath,
          dbId: storeMeta.id,
          name: storeMeta.name,
          description: storeMeta.description,
          password: dto.saveMasterPassword ? dto.password : null,
          savePassword: dto.saveMasterPassword,
        );
        logInfo('Created new history entry for opened store', tag: _logTag);
      } else {
        await _dbHistoryService.updateLastAccessed(actualStoragePath);
        logInfo('Updated existing history entry', tag: _logTag);
      }

      logInfo('Store opened successfully', tag: _logTag);

      return getStoreInfo();
    } on DatabaseError catch (e) {
      return Failure(e);
    } catch (e, stackTrace) {
      logError(
        'Failed to open store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.connectionFailed(
          message: 'Не удалось открыть хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Закрыть текущее хранилище
  AsyncResultDart<Unit, DatabaseError> closeStore() async {
    try {
      if (!isStoreOpen) {
        return Failure(
          DatabaseError.notInitialized(
            message: 'Хранилище не открыто',
            timestamp: DateTime.now(),
          ),
        );
      }

      logInfo('Closing store', tag: _logTag);

      await _closeCurrentStore();

      logInfo('Store closed successfully', tag: _logTag);

      return const Success(unit);
    } on DatabaseError catch (e) {
      return Failure(e);
    } catch (e, stackTrace) {
      logError(
        'Failed to close store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.unknown(
          message: 'Не удалось закрыть хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Получить информацию о текущем хранилище
  AsyncResultDart<StoreInfoDto, DatabaseError> getStoreInfo() async {
    try {
      if (!isStoreOpen) {
        return Failure(
          DatabaseError.notInitialized(
            message: 'Хранилище не открыто',
            timestamp: DateTime.now(),
          ),
        );
      }

      return _metadataService.getStoreInfo(_currentStore!);
    } catch (e, stackTrace) {
      logError(
        'Failed to get store info: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.queryFailed(
          message: 'Не удалось получить информацию о хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Обновить метаданные хранилища
  AsyncResultDart<StoreInfoDto, DatabaseError> updateStore(
    UpdateStoreDto dto,
  ) async {
    try {
      if (!isStoreOpen) {
        return Failure(
          DatabaseError.notInitialized(
            message: 'Хранилище не открыто',
            timestamp: DateTime.now(),
          ),
        );
      }

      logInfo('Updating store metadata', tag: _logTag);
      final result = await _metadataService.updateStore(_currentStore!, dto);
      if (result.isError()) {
        return result;
      }

      if (dto.password != null) {
        logInfo('Password updated for store', tag: _logTag);
      }

      if (_currentStorePath != null) {
        final historyEntry = await _dbHistoryService.getByPath(
          _currentStorePath!,
        );
        if (historyEntry != null) {
          final shouldSavePassword =
              dto.saveMasterPassword ?? historyEntry.savePassword;
          await _dbHistoryService.update(
            historyEntry.copyWith(
              name: dto.name ?? historyEntry.name,
              description: dto.description ?? historyEntry.description,
              savePassword: shouldSavePassword,
            ),
          );

          if (dto.saveMasterPassword == false) {
            await _dbHistoryService.setSavedPasswordByPath(
              _currentStorePath!,
              null,
            );
          } else if (dto.password != null && shouldSavePassword) {
            await _dbHistoryService.setSavedPasswordByPath(
              _currentStorePath!,
              dto.password,
            );
          }
        }
      }

      logInfo('Store metadata updated successfully', tag: _logTag);

      return result;
    } catch (e, stackTrace) {
      logError(
        'Failed to update store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.updateFailed(
          message: 'Не удалось обновить хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<void> _closeCurrentStore() async {
    if (!isStoreOpen) {
      throw DatabaseError.notInitialized(
        message: 'Хранилище не открыто',
        timestamp: DateTime.now(),
      );
    }

    DatabaseError? manifestError;
    try {
      await _writeCurrentStoreManifest();
      logInfo('Updated store_manifest.json before close', tag: _logTag);
    } on DatabaseError catch (error) {
      manifestError = error;
    }

    await _currentStore?.close();
    _currentStore = null;
    _currentStorePath = null;

    if (manifestError != null) {
      throw manifestError;
    }
  }

  Future<void> _writeCurrentStoreManifest({StoreKeyConfig? keyConfig}) async {
    final storagePath = _currentStorePath;
    if (_currentStore == null || storagePath == null) {
      throw DatabaseError.notInitialized(
        message: 'Хранилище не открыто',
        timestamp: DateTime.now(),
      );
    }

    final storeInfoResult = await getStoreInfo();
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
    final manifest =
        existingManifest?.copyWith(
          manifestVersion: MainConstants.storeManifestVersion,
          lastMigrationVersion: currentMigrationVersion,
          appVersion: currentAppVersion,
          storeUuid: storeInfo.id,
          storeName: storeInfo.name,
          updatedAt: storeInfo.modifiedAt.toUtc(),
          lastModifiedBy: existingManifest.lastModifiedBy.deviceId.isNotEmpty
              ? existingManifest.lastModifiedBy
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

  Future<_StoreOpenCompatibility> _checkStoreOpenCompatibility(
    StoreManifest? manifest,
  ) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentAppVersion = packageInfo.version;
    const currentManifestVersion = MainConstants.storeManifestVersion;
    const currentSchemaVersion = MainConstants.databaseSchemaVersion;

    if (manifest == null) {
      return const _StoreOpenCompatibility(
        currentManifestVersion: currentManifestVersion,
        currentSchemaVersion: currentSchemaVersion,
        currentAppVersion: '',
      );
    }

    final storeManifestVersion = manifest.manifestVersion;
    final storeSchemaVersion = manifest.lastMigrationVersion;
    final storeAppVersion = manifest.appVersion?.trim();
    final appVersionComparison = _compareAppVersions(
      storeAppVersion,
      currentAppVersion,
    );

    final manifestVersionTooNew = storeManifestVersion > currentManifestVersion;
    final schemaVersionTooNew =
        storeSchemaVersion != null && storeSchemaVersion > currentSchemaVersion;
    final appVersionTooNew = appVersionComparison > 0;

    final requiresMigration =
        !manifestVersionTooNew &&
        !schemaVersionTooNew &&
        !appVersionTooNew &&
        (storeManifestVersion < currentManifestVersion ||
            storeSchemaVersion == null ||
            storeSchemaVersion < currentSchemaVersion ||
            storeAppVersion == null ||
            storeAppVersion.isEmpty ||
            appVersionComparison < 0);

    return _StoreOpenCompatibility(
      currentManifestVersion: currentManifestVersion,
      storeManifestVersion: storeManifestVersion,
      currentSchemaVersion: currentSchemaVersion,
      storeSchemaVersion: storeSchemaVersion,
      currentAppVersion: currentAppVersion,
      storeAppVersion: storeAppVersion,
      requiresMigration: requiresMigration,
      manifestVersionTooNew: manifestVersionTooNew,
      schemaVersionTooNew: schemaVersionTooNew,
      appVersionTooNew: appVersionTooNew,
    );
  }

  DatabaseError? _buildCompatibilityError({
    required _StoreOpenCompatibility compatibility,
    required String storagePath,
    required bool allowMigration,
  }) {
    if (compatibility.blocksOpen) {
      final reasons = <String>[];

      if (compatibility.manifestVersionTooNew) {
        reasons.add(
          'Версия manifest (${compatibility.storeManifestVersion}) новее поддерживаемой (${compatibility.currentManifestVersion})',
        );
      }
      if (compatibility.schemaVersionTooNew) {
        reasons.add(
          'Версия схемы данных (${compatibility.storeSchemaVersion}) новее поддерживаемой (${compatibility.currentSchemaVersion})',
        );
      }
      if (compatibility.appVersionTooNew) {
        reasons.add(
          'Store был обновлён в версии приложения ${compatibility.storeAppVersion}, а текущая версия приложения ${compatibility.currentAppVersion}',
        );
      }

      return DatabaseError.migrationFailed(
        code: 'DB_STORE_VERSION_TOO_NEW',
        message:
            'Открытие невозможно: ${reasons.join('. ')}. Используйте более новую версию приложения.',
        data: compatibility.toErrorData(storagePath),
        timestamp: DateTime.now(),
      );
    }

    if (compatibility.requiresMigration && !allowMigration) {
      return DatabaseError.migrationFailed(
        code: 'DB_STORE_MIGRATION_REQUIRED',
        message:
            'Хранилище требует миграции перед открытием. Сначала создайте backup, затем выполните миграцию на текущие версии приложения и схемы.',
        data: compatibility.toErrorData(storagePath),
        timestamp: DateTime.now(),
      );
    }

    return null;
  }
}

class _StoreOpenCompatibility {
  const _StoreOpenCompatibility({
    required this.currentManifestVersion,
    required this.currentSchemaVersion,
    required this.currentAppVersion,
    this.storeManifestVersion,
    this.storeSchemaVersion,
    this.storeAppVersion,
    this.requiresMigration = false,
    this.manifestVersionTooNew = false,
    this.schemaVersionTooNew = false,
    this.appVersionTooNew = false,
  });

  final int currentManifestVersion;
  final int? storeManifestVersion;
  final int currentSchemaVersion;
  final int? storeSchemaVersion;
  final String currentAppVersion;
  final String? storeAppVersion;
  final bool requiresMigration;
  final bool manifestVersionTooNew;
  final bool schemaVersionTooNew;
  final bool appVersionTooNew;

  bool get blocksOpen =>
      manifestVersionTooNew || schemaVersionTooNew || appVersionTooNew;

  Map<String, dynamic> toErrorData(String storagePath) {
    return <String, dynamic>{
      'path': storagePath,
      'currentManifestVersion': currentManifestVersion,
      'storeManifestVersion': storeManifestVersion,
      'currentSchemaVersion': currentSchemaVersion,
      'storeSchemaVersion': storeSchemaVersion,
      'currentAppVersion': currentAppVersion,
      'storeAppVersion': storeAppVersion,
      'requiresMigration': requiresMigration,
      'manifestVersionTooNew': manifestVersionTooNew,
      'schemaVersionTooNew': schemaVersionTooNew,
      'appVersionTooNew': appVersionTooNew,
    };
  }
}

int _compareAppVersions(String? left, String? right) {
  final leftSegments = _parseVersionSegments(left);
  final rightSegments = _parseVersionSegments(right);
  final maxLength = leftSegments.length > rightSegments.length
      ? leftSegments.length
      : rightSegments.length;

  for (var index = 0; index < maxLength; index++) {
    final leftValue = index < leftSegments.length ? leftSegments[index] : 0;
    final rightValue = index < rightSegments.length ? rightSegments[index] : 0;
    if (leftValue != rightValue) {
      return leftValue.compareTo(rightValue);
    }
  }

  return 0;
}

List<int> _parseVersionSegments(String? value) {
  if (value == null || value.trim().isEmpty) {
    return const <int>[0];
  }

  final matches = RegExp(r'\d+').allMatches(value);
  final segments = <int>[];
  for (final match in matches) {
    final parsed = int.tryParse(match.group(0) ?? '');
    if (parsed != null) {
      segments.add(parsed);
    }
  }

  return segments.isEmpty ? const <int>[0] : segments;
}
