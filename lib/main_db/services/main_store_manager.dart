import 'dart:async';

import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/logger.dart' hide Session;
import 'package:hoplixi/main_db/core/daos/daos.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/models/session.dart';
import 'package:hoplixi/main_db/services/db_history_services/db_history_services.dart';
import 'package:hoplixi/main_db/services/main_store_storage_service.dart';
import 'package:hoplixi/main_db/usecases/close_main_store.dart';
import 'package:hoplixi/main_db/usecases/create_main_store.dart';
import 'package:hoplixi/main_db/usecases/open_main_store.dart';
import 'package:hoplixi/main_db/usecases/perform_store_cleanup.dart';
import 'package:hoplixi/main_db/usecases/update_main_store.dart';
import 'package:hoplixi/main_db/services/other/file_storage_service.dart';
import 'package:result_dart/result_dart.dart';
import 'package:synchronized/synchronized.dart';

class MainStoreManager {
  static const String _logTag = 'MainStoreManager';

  final Lock _lock = Lock();
  final DatabaseHistoryService _dbHistoryService;
  final CreateMainStore _createMainStore;
  final OpenMainStore _openMainStore;
  final CloseMainStore _closeMainStore;
  final UpdateMainStore _updateMainStore;
  final MainStoreFileService _storageService;

  MainStore? _currentStore;
  Session? _currentSession;

  MainStoreManager({
    required DatabaseHistoryService dbHistoryService,
    CreateMainStore? createMainStore,
    OpenMainStore? openMainStore,
    CloseMainStore? closeMainStore,
    UpdateMainStore? updateMainStore,
    MainStoreFileService? storageService,
  }) : _dbHistoryService = dbHistoryService,
       _createMainStore = createMainStore ?? CreateMainStore(),
       _openMainStore = openMainStore ?? OpenMainStore(),
       _closeMainStore = closeMainStore ?? CloseMainStore(),
       _updateMainStore = updateMainStore ?? UpdateMainStore(),
       _storageService = storageService ?? const MainStoreFileService();

  bool get isStoreOpen => _currentStore != null && _currentSession != null;

  MainStore? get currentStore =>
      _currentStore; // Предоставляет доступ к текущему открытому MainStore, или null если БД не открыта

  Session? get currentSession =>
      _currentSession; // Предоставляет доступ к текущей сессии, которая включает MainStore, информацию о хранилище и путь к директории. Может быть null, если БД не открыта

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
    _currentStore = session.store;
    _currentSession = session;
  }

  void _clearCurrentSessionIfMatches(Session session) {
    if (_currentSession == null) {
      return;
    }

    final isSameStorePath =
        _currentSession!.storeDirectoryPath == session.storeDirectoryPath;
    final isSameStoreInstance = identical(_currentStore, session.store);
    if (isSameStorePath || isSameStoreInstance) {
      _currentStore = null;
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

    final result = await _closeMainStore(session: sessionToClose);
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

      final result = await _createMainStore(
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

      unawaited(runStartupCleanup(session));
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

      final result = await _openMainStore(
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

      unawaited(runStartupCleanup(session));
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

  AsyncResultDart<StoreInfoDto, AppError> updateStore(
    UpdateStoreDto dto,
  ) async {
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

      final result = await _updateMainStore(session: session, dto: dto);
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
              session.storeDirectoryPath,
              null,
            );
          } else if (dto.password != null && shouldSavePassword) {
            await _dbHistoryService.setSavedPasswordByPath(
              session.storeDirectoryPath,
              dto.password,
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
      final currentStore = _currentStore;
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
            version: meta.version,
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

  Future<void> runStartupCleanup([Session? targetSession]) async {
    final session = targetSession ?? _currentSession;
    if (session == null) {
      logWarning('Cannot run startup cleanup: no active session', tag: _logTag);
      return;
    }

    try {
      final attachmentsPath = _storageService.getAttachmentsPath(
        session.storeDirectoryPath,
      );
      final decryptedAttachmentsPath = _storageService
          .getDecryptedAttachmentsPath(session.storeDirectoryPath);
      final fileStorageService = FileStorageService(
        session.store,
        attachmentsPath,
        decryptedAttachmentsPath,
      );
      final cleanup = PerformStoreCleanup(
        StoreSettingsDao(session.store),
        fileStorageService,
      );
      final result = await cleanup();
      if (result.isSuccess) {
        logInfo('Startup cleanup completed: ${result.message}', tag: _logTag);
      } else {
        logWarning(
          'Startup cleanup failed: ${result.errorMessage ?? result.message}',
          tag: _logTag,
        );
      }
    } catch (error, stackTrace) {
      logWarning(
        'Unexpected startup cleanup error',
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
