import 'dart:async';

import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/logger.dart' hide Session;
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:hoplixi/vault_db/models/session.dart';
import 'package:hoplixi/vault_db/services/db_history_services/db_history_services.dart';
import 'package:hoplixi/vault_db/services/main_store_storage_service.dart';
import 'package:hoplixi/vault_db/usecases/close_main_store.dart';
import 'package:hoplixi/vault_db/usecases/create_main_store.dart';
import 'package:hoplixi/vault_db/usecases/open_main_store.dart';
import 'package:hoplixi/vault_db/usecases/update_main_store.dart';
import 'package:result_dart/result_dart.dart';
import 'package:synchronized/synchronized.dart';

class VaultDBManagerFactory {
  VaultDBManagerFactory({
    required this.dbHistoryService,
    this.performStoreCleanup,
  }) : createVaultDB = CreateVaultDB(),
       openVaultDB = OpenVaultDB(),
       closeVaultDB = CloseVaultDB(),
       updateVaultDB = UpdateVaultDB(),
       storageService = const VaultDBFileService();

  final DatabaseHistoryService dbHistoryService;
  final CreateVaultDB createVaultDB;
  final OpenVaultDB openVaultDB;
  final CloseVaultDB closeVaultDB;
  final UpdateVaultDB updateVaultDB;
  final VaultDBFileService storageService;
  final Future<void> Function(VaultDB db, String storePath)?
  performStoreCleanup;

  VaultDBManager create() {
    return VaultDBManager(
      dbHistoryService: dbHistoryService,
      createVaultDB: createVaultDB,
      openVaultDB: openVaultDB,
      closeVaultDB: closeVaultDB,
      updateVaultDB: updateVaultDB,
      storageService: storageService,
      performStoreCleanup: performStoreCleanup,
    );
  }
}

class VaultDBManager {
  static const String _logTag = 'VaultDBManager';

  final Lock _lock = Lock();
  final DatabaseHistoryService _dbHistoryService;
  final CreateVaultDB _createVaultDB;
  final OpenVaultDB _openVaultDB;
  final CloseVaultDB _closeVaultDB;
  final UpdateVaultDB _updateVaultDB;
  final VaultDBFileService _storageService;
  final Future<void> Function(VaultDB db, String storePath)?
  _performStoreCleanup;

  VaultDB? _currentDB;
  Session? _currentSession;

  VaultDBManager({
    required DatabaseHistoryService dbHistoryService,
    required CreateVaultDB createVaultDB,
    required OpenVaultDB openVaultDB,
    required CloseVaultDB closeVaultDB,
    required UpdateVaultDB updateVaultDB,
    required VaultDBFileService storageService,
    Future<void> Function(VaultDB db, String storePath)? performStoreCleanup,
  }) : _dbHistoryService = dbHistoryService,
       _createVaultDB = createVaultDB,
       _openVaultDB = openVaultDB,
       _closeVaultDB = closeVaultDB,
       _updateVaultDB = updateVaultDB,
       _storageService = storageService,
       _performStoreCleanup = performStoreCleanup;

  bool get isStoreOpen => _currentDB != null && _currentSession != null;

  VaultDB? get currentDB =>
      _currentDB; // Предоставляет доступ к текущему открытому VaultDB, или null если БД не открыта

  Session? get currentSession =>
      _currentSession; // Предоставляет доступ к текущей сессии, которая включает VaultDB, информацию о хранилище и путь к директории. Может быть null, если БД не открыта

  String? get currentStorePath => _currentSession?.storeDirectoryPath;

  String? getAttachmentsPath() {
    final storePath = currentStorePath;
    if (storePath == null || storePath.isEmpty) {
      return null;
    }
    return _storageService.getAttachmentsPath(storePath);
  }

  String? getDecryptedAttachmentsPath() {
    final storePath = currentStorePath;
    if (storePath == null || storePath.isEmpty) {
      return null;
    }
    return _storageService.getDecryptedAttachmentsPath(storePath);
  }

  void _setCurrentSession(Session session) {
    _currentDB = session.store;
    _currentSession = session;
  }

  void _clearCurrentSessionIfMatches(Session session) {
    if (_currentSession == null) {
      return;
    }

    final isSameStorePath =
        _currentSession!.storeDirectoryPath == session.storeDirectoryPath;
    final isSameStoreInstance = identical(_currentDB, session.store);
    if (isSameStorePath || isSameStoreInstance) {
      _currentDB = null;
      _currentSession = null;
    }
  }

  bool _isCurrentStorePath(String storePath) {
    return _currentSession?.storeDirectoryPath == storePath;
  }

  Future<ResultDart<Unit, AppError>> _closeCurrentSession() async {
    final sessionToClose = _currentSession;
    if (sessionToClose == null) {
      return Failure(
        AppError.mainDatabase(
          code: MainDatabaseErrorCode.notInitialized,
          message: 'Хранилище не открыто',
          timestamp: DateTime.now(),
        ),
      );
    }

    final result = await _closeVaultDB(session: sessionToClose);
    if (result.isSuccess()) {
      _clearCurrentSessionIfMatches(sessionToClose);
    }

    return result;
  }

  AsyncResultDart<Session, AppError> createStore(
    CreateStoreDto dto,
    String masterPassword,
  ) async {
    return _lock.synchronized(() async {
      // Close any previously opened store
      if (_currentSession != null) {
        await _closeCurrentSession();
      }

      final result = await _createVaultDB(
        dto: dto,
        masterPassword: masterPassword,
      );
      if (result.isError()) {
        return Failure(result.exceptionOrNull()!);
      }

      final session = result.getOrThrow();
      _setCurrentSession(session);
      try {
        await _dbHistoryService.create(
          path: session.storeDirectoryPath,
          dbId: session.info.id,
          name: session.info.name,
          description: session.info.description,
          password: dto.saveMasterPassword ? masterPassword : null,
          savePassword: dto.saveMasterPassword,
        );
        logInfo('Created history entry for new store', tag: _logTag);
      } catch (error, stackTrace) {
        logWarning(
          'Failed to create history entry for new store',
          tag: _logTag,
          data: {
            'storeId': session.info.id,
            'storePath': session.storeDirectoryPath,
            'error': error.toString(),
            'stackTrace': stackTrace.toString(),
          },
        );
      }

      final performStoreCleanup = _performStoreCleanup;
      if (performStoreCleanup != null) {
        try {
          await performStoreCleanup(session.store, session.storeDirectoryPath);
          logInfo(
            'Store cleanup completed successfully during store creation',
            tag: _logTag,
          );
        } catch (error, stackTrace) {
          logWarning(
            'Failed to perform store cleanup during store creation',
            tag: _logTag,
            data: {
              'storeId': session.info.id,
              'storePath': session.storeDirectoryPath,
              'error': error.toString(),
              'stackTrace': stackTrace.toString(),
            },
          );
        }
      }

      return Success(session);
    });
  }

  AsyncResultDart<Session, AppError> openStore(
    OpenStoreDto dto,
    String masterPassword, {
    bool allowMigration = false,
  }) async {
    return _lock.synchronized(() async {
      // Close any previously opened store
      if (_currentSession != null) {
        await _closeCurrentSession();
      }

      final result = await _openVaultDB(
        dto: dto,
        masterPassword: masterPassword,
        allowMigration: allowMigration,
      );
      if (result.isError()) {
        return Failure(result.exceptionOrNull()!);
      }

      final session = result.getOrThrow();
      _setCurrentSession(session);
      try {
        final existingHistory = await _dbHistoryService.getByPath(
          session.storeDirectoryPath,
        );
        if (existingHistory == null) {
          await _dbHistoryService.create(
            path: session.storeDirectoryPath,
            dbId: session.info.id,
            name: session.info.name,
            description: session.info.description,
            password: dto.saveMasterPassword ? masterPassword : null,
            savePassword: dto.saveMasterPassword,
          );
          logInfo('Created history entry for opened store', tag: _logTag);
        } else {
          await _dbHistoryService.updateLastAccessed(
            session.storeDirectoryPath,
          );
          logInfo('Updated existing history entry', tag: _logTag);
        }
      } catch (error, stackTrace) {
        logWarning(
          'Failed to update history entry for opened store',
          tag: _logTag,
          data: {
            'storeId': session.info.id,
            'storePath': session.storeDirectoryPath,
            'error': error.toString(),
            'stackTrace': stackTrace.toString(),
          },
        );
      }

      final performStoreCleanup = _performStoreCleanup;
      if (performStoreCleanup != null) {
        try {
          await performStoreCleanup(session.store, session.storeDirectoryPath);
          logInfo(
            'Store cleanup completed successfully during store opening',
            tag: _logTag,
          );
        } catch (error, stackTrace) {
          logWarning(
            'Failed to perform store cleanup during store opening',
            tag: _logTag,
            data: {
              'storeId': session.info.id,
              'storePath': session.storeDirectoryPath,
              'error': error.toString(),
              'stackTrace': stackTrace.toString(),
            },
          );
        }
      }

      return Success(session);
    });
  }

  AsyncResultDart<Unit, AppError> closeStore() async {
    return _lock.synchronized(() async {
      return _closeCurrentSession();
    });
  }

  AsyncResultDart<String, AppError> createSubfolder(String folderName) async {
    return _lock.synchronized(() async {
      try {
        final storePath = currentStorePath;
        if (storePath == null || storePath.isEmpty) {
          return Failure(
            AppError.mainDatabase(
              code: MainDatabaseErrorCode.notInitialized,
              message: 'Хранилище не открыто',
              timestamp: DateTime.now(),
            ),
          );
        }

        final path = await _storageService.createSubfolder(
          storePath: storePath,
          folderName: folderName,
        );
        return Success(path);
      } catch (error, stackTrace) {
        if (error is AppError) {
          return Failure(error);
        }
        return Failure(
          AppError.fileSystem(
            code: FileSystemErrorCode.unknown,
            message: 'Не удалось создать подпапку хранилища',
            cause: error,
            stackTrace: stackTrace,
            timestamp: DateTime.now(),
          ),
        );
      }
    });
  }

  AsyncResultDart<Unit, AppError> deleteStore(
    String path, {
    bool deleteFromDisk = true,
  }) async {
    return _lock.synchronized(() async {
      try {
        final normalizedPath = path.trim();
        if (normalizedPath.isEmpty) {
          return Failure(
            AppError.validation(
              code: ValidationErrorCode.invalidInput,
              message: 'Путь к хранилищу не указан',
              timestamp: DateTime.now(),
            ),
          );
        }

        final storePath = await _resolveDeleteStorePath(
          normalizedPath,
          requireExistingStorage: false,
        );

        if (_isCurrentStorePath(storePath)) {
          final closeResult = await _closeCurrentSession();
          if (closeResult.isError()) {
            return Failure(closeResult.exceptionOrNull()!);
          }
        }

        await _deleteHistoryEntries(normalizedPath, storePath);

        if (deleteFromDisk &&
            await _storageService.storageDirectoryExists(storePath)) {
          await _storageService.deleteStorageDirectory(storePath);
        }

        logInfo('Store deleted successfully', tag: _logTag);
        return const Success(unit);
      } catch (error, stackTrace) {
        return _mapDeleteFailure(
          error,
          stackTrace: stackTrace,
          message: 'Не удалось удалить хранилище',
        );
      }
    });
  }

  AsyncResultDart<Unit, AppError> deleteStoreFromDisk(String path) async {
    return _lock.synchronized(() async {
      try {
        final normalizedPath = path.trim();
        if (normalizedPath.isEmpty) {
          return Failure(
            AppError.validation(
              code: ValidationErrorCode.invalidInput,
              message: 'Путь к хранилищу не указан',
              timestamp: DateTime.now(),
            ),
          );
        }

        final storePath = await _resolveDeleteStorePath(
          normalizedPath,
          requireExistingStorage: true,
        );

        if (_isCurrentStorePath(storePath)) {
          final closeResult = await _closeCurrentSession();
          if (closeResult.isError()) {
            return Failure(closeResult.exceptionOrNull()!);
          }
        }

        if (!await _storageService.storageDirectoryExists(storePath)) {
          return Failure(
            AppError.mainDatabase(
              code: MainDatabaseErrorCode.recordNotFound,
              message: 'Директория хранилища не найдена',
              data: <String, dynamic>{'path': storePath},
              timestamp: DateTime.now(),
            ),
          );
        }

        await _storageService.deleteStorageDirectory(storePath);
        await _deleteHistoryEntries(normalizedPath, storePath);

        logInfo('Store deleted from disk successfully', tag: _logTag);
        return const Success(unit);
      } catch (error, stackTrace) {
        return _mapDeleteFailure(
          error,
          stackTrace: stackTrace,
          message: 'Не удалось удалить хранилище с диска',
        );
      }
    });
  }

  AsyncResultDart<StoreInfoDto, AppError> updateStore(PatchStoreDto dto) async {
    return _lock.synchronized(() async {
      final session = _currentSession;
      if (session == null) {
        return Failure(
          AppError.mainDatabase(
            code: MainDatabaseErrorCode.notInitialized,
            message: 'Хранилище не открыто',
            timestamp: DateTime.now(),
          ),
        );
      }

      final result = await _updateVaultDB(session: session, dto: dto);
      if (result.isError()) {
        return Failure(result.exceptionOrNull()!);
      }

      final storeInfo = result.getOrThrow();
      if (_currentSession?.storeDirectoryPath == session.storeDirectoryPath) {
        _setCurrentSession((
          store: session.store,
          info: storeInfo,
          storeDirectoryPath: session.storeDirectoryPath,
        ));
      }

      try {
        final historyEntry = await _dbHistoryService.getByPath(
          session.storeDirectoryPath,
        );
        if (historyEntry != null) {
          final shouldSavePassword =
              dto.saveMasterPassword.valueOrNull ?? historyEntry.savePassword;

          await _dbHistoryService.update(
            historyEntry.copyWith(
              name: dto.name.valueOrNull ?? historyEntry.name,
              description:
                  dto.description.valueOrNull ?? historyEntry.description,
              savePassword: shouldSavePassword,
            ),
          );

          if (dto.saveMasterPassword.valueOrNull == false) {
            await _dbHistoryService.setSavedPasswordByPath(
              session.storeDirectoryPath,
              null,
            );
          } else if (dto.password.valueOrNull != null && shouldSavePassword) {
            await _dbHistoryService.setSavedPasswordByPath(
              session.storeDirectoryPath,
              dto.password.valueOrNull,
            );
          }

          logInfo('Updated history entry for store', tag: _logTag);
        }

        return Success(storeInfo);
      } catch (error, stackTrace) {
        logWarning(
          'Failed to update history entry for store',
          tag: _logTag,
          data: {
            'storeId': session.info.id,
            'storePath': session.storeDirectoryPath,
            'error': error.toString(),
            'stackTrace': stackTrace.toString(),
          },
        );
        return Success(storeInfo);
      }
    });
  }

  AsyncResultDart<StoreInfoDto, AppError> getStoreInfo() async {
    return _lock.synchronized(() async {
      final currentStore = _currentDB;
      if (currentStore == null) {
        return Failure(
          AppError.mainDatabase(
            code: MainDatabaseErrorCode.notInitialized,
            message: 'Хранилище не открыто',
            timestamp: DateTime.now(),
          ),
        );
      }

      try {
        final meta = await currentStore.storeMetaDao.getStoreMeta();

        if (meta == null) {
          return Failure(
            AppError.mainDatabase(
              code: MainDatabaseErrorCode.recordNotFound,
              message: 'Метаданные хранилища не найдены',
              timestamp: DateTime.now(),
            ),
          );
        }

        return Success(
          StoreInfoDto(
            id: meta.id,
            name: meta.name,
            description: meta.description,
            createdAt: meta.createdAt,
            modifiedAt: meta.modifiedAt,
            lastOpenedAt: meta.lastOpenedAt,
          ),
        );
      } catch (error, stackTrace) {
        return Failure(
          AppError.mainDatabase(
            code: MainDatabaseErrorCode.queryFailed,
            message: 'Не удалось получить информацию о хранилище: $error',
            cause: error,
            stackTrace: stackTrace,
            timestamp: DateTime.now(),
          ),
        );
      }
    });
  }

  Future<String> _resolveDeleteStorePath(
    String path, {
    required bool requireExistingStorage,
  }) async {
    try {
      return await _storageService.resolveExistingStoragePath(path);
    } catch (_) {
      if (requireExistingStorage) {
        rethrow;
      }
      return path;
    }
  }

  Future<void> _deleteHistoryEntries(
    String originalPath,
    String storePath,
  ) async {
    await _dbHistoryService.deleteByPath(storePath);
    if (originalPath != storePath) {
      await _dbHistoryService.deleteByPath(originalPath);
    }
  }

  ResultDart<Unit, AppError> _mapDeleteFailure(
    Object error, {
    required StackTrace stackTrace,
    required String message,
  }) {
    if (error is AppError) {
      return Failure(error);
    }

    return Failure(
      AppError.mainDatabase(
        code: MainDatabaseErrorCode.unknown,
        message: message,
        cause: error,
        stackTrace: stackTrace,
        timestamp: DateTime.now(),
      ),
    );
  }
}
