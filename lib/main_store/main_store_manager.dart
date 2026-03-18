import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/db_errors.dart';
import 'package:hoplixi/main_store/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_store/models/store_key_config.dart';
import 'package:hoplixi/main_store/models/store_manifest.dart';
import 'package:hoplixi/main_store/services/db_history_services.dart';
import 'package:hoplixi/main_store/services/db_key_derivation_service.dart';
import 'package:hoplixi/main_store/services/main_store_connection_service.dart';
import 'package:hoplixi/main_store/services/main_store_metadata_service.dart';
import 'package:hoplixi/main_store/services/main_store_storage_service.dart';
import 'package:hoplixi/main_store/services/store_key_config_service.dart';
import 'package:hoplixi/main_store/services/store_manifest_service.dart';
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
      );
      await keyConfig.writeTo(storageDir.path);
      logInfo(
        'Wrote store_key.json (useDeviceKey=${dto.useDeviceKey})',
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
        await _writeCurrentStoreManifest();
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
    OpenStoreDto dto,
  ) async {
    try {
      logInfo('Opening store at: ${dto.path}', tag: _logTag);

      // Проверка, открыто ли уже хранилище
      if (isStoreOpen) {
        await _closeCurrentStore();
      }

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

      final keyConfig = await StoreKeyConfigService.readFrom(actualStoragePath);
      final String pragmaKey;
      if (keyConfig != null) {
        pragmaKey = await _keyService.derivePragmaKey(
          dto.password,
          keyConfig.argon2Salt,
          useDeviceKey: keyConfig.useDeviceKey,
        );
        logInfo(
          'Derived Argon2 PRAGMA key (useDeviceKey=${keyConfig.useDeviceKey})',
          tag: _logTag,
        );
      } else {
        // Обратная совместимость: сырой пароль как раньше
        pragmaKey = dto.password;
        logInfo(
          'No store_key.json found — using raw password (legacy mode)',
          tag: _logTag,
        );
      }

      final dbResult = await _connectionService.createDatabaseConnection(
        dbFilePath,
        pragmaKey,
      );

      if (dbResult.isError()) {
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
          await _dbHistoryService.update(
            historyEntry.copyWith(
              name: dto.name ?? historyEntry.name,
              description: dto.description ?? historyEntry.description,
              password: dto.saveMasterPassword == true && dto.password != null
                  ? dto.password
                  : dto.saveMasterPassword == false
                  ? null
                  : historyEntry.password,
              savePassword: dto.saveMasterPassword ?? historyEntry.savePassword,
            ),
          );
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

  Future<void> _writeCurrentStoreManifest() async {
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
    final manifest = StoreManifest(
      storeId: storeInfo.id,
      lastModified: storeInfo.modifiedAt.millisecondsSinceEpoch,
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
}
