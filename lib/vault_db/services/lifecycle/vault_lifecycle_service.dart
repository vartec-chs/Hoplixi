import 'dart:async';

import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/logger.dart' hide Session;
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/models/session.dart';
import 'package:hoplixi/vault_db/services/db_history_services/db_history_services.dart';
import 'package:hoplixi/vault_db/services/session/ivault_session_holder.dart';
import 'package:hoplixi/vault_db/services/storage/ivault_storage_manager.dart';
import 'package:hoplixi/vault_db/usecases/close_main_store.dart';
import 'package:hoplixi/vault_db/usecases/create_main_store.dart';
import 'package:hoplixi/vault_db/usecases/open_main_store.dart';
import 'package:hoplixi/vault_db/usecases/update_main_store.dart';
import 'package:result_dart/result_dart.dart';
import 'package:synchronized/synchronized.dart';

import 'ivault_lifecycle_service.dart';

class VaultLifecycleService implements IVaultLifecycleService {
  static const String _logTag = 'VaultLifecycleService';

  final Lock _lock = Lock();
  final IVaultSessionHolder _sessionHolder;
  final IVaultStorageManager _storageManager;
  final DatabaseHistoryService _dbHistoryService;
  final CreateVaultDB _createVaultDB;
  final OpenVaultDB _openVaultDB;
  final CloseVaultDB _closeVaultDB;
  final UpdateVaultDB _updateVaultDB;

  VaultLifecycleService({
    required IVaultSessionHolder sessionHolder,
    required IVaultStorageManager storageManager,
    required DatabaseHistoryService dbHistoryService,
    required CreateVaultDB createVaultDB,
    required OpenVaultDB openVaultDB,
    required CloseVaultDB closeVaultDB,
    required UpdateVaultDB updateVaultDB,
  }) : _sessionHolder = sessionHolder,
       _storageManager = storageManager,
       _dbHistoryService = dbHistoryService,
       _createVaultDB = createVaultDB,
       _openVaultDB = openVaultDB,
       _closeVaultDB = closeVaultDB,
       _updateVaultDB = updateVaultDB;

  bool _isCurrentStorePath(String storePath) {
    return _sessionHolder.currentStorePath == storePath;
  }

  Future<ResultDart<Unit, AppError>> _closeCurrentSession() async {
    final sessionToClose = _sessionHolder.currentSession;
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
      _sessionHolder.clearSessionIfMatches(sessionToClose);
    }

    return result;
  }

  @override
  AsyncResultDart<Session, AppError> createStore({
    required CreateStoreDto dto,
    required String masterPassword,
  }) async {
    return _lock.synchronized(() async {
      // Close any previously opened store
      if (_sessionHolder.isStoreOpen) {
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
      _sessionHolder.updateSession(session);

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

      return Success(session);
    });
  }

  @override
  AsyncResultDart<Session, AppError> openStore({
    required OpenStoreDto dto,
    required String masterPassword,
    bool allowMigration = false,
  }) async {
    return _lock.synchronized(() async {
      // Close any previously opened store
      if (_sessionHolder.isStoreOpen) {
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
      _sessionHolder.updateSession(session);

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

      return Success(session);
    });
  }

  @override
  AsyncResultDart<Unit, AppError> closeStore() async {
    return _lock.synchronized(() async {
      return _closeCurrentSession();
    });
  }

  @override
  AsyncResultDart<StoreInfoDto, AppError> updateStore(PatchStoreDto dto) async {
    return _lock.synchronized(() async {
      final session = _sessionHolder.currentSession;
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
      if (_sessionHolder.currentStorePath == session.storeDirectoryPath) {
        _sessionHolder.updateSession((
          api: session.api,
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

  @override
  AsyncResultDart<StoreInfoDto, AppError> getStoreInfo() async {
    return _lock.synchronized(() async {
      final currentStore = _sessionHolder.currentDB;
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

  @override
  AsyncResultDart<Unit, AppError> deleteStore(
    String path, {
    required bool deleteFromDisk,
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
          requireExistingStorage: deleteFromDisk,
        );

        if (_isCurrentStorePath(storePath)) {
          final closeResult = await _closeCurrentSession();
          if (closeResult.isError()) {
            return Failure(closeResult.exceptionOrNull()!);
          }
        }

        await _deleteHistoryEntries(normalizedPath, storePath);

        if (deleteFromDisk) {
          if (!await _storageManager.storageDirectoryExists(storePath)) {
            return Failure(
              AppError.mainDatabase(
                code: MainDatabaseErrorCode.recordNotFound,
                message: 'Директория хранилища не найдена',
                data: <String, dynamic>{'path': storePath},
                timestamp: DateTime.now(),
              ),
            );
          }
          await _storageManager.deleteStorageDirectory(storePath);
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

  Future<String> _resolveDeleteStorePath(
    String path, {
    required bool requireExistingStorage,
  }) async {
    try {
      return await _storageManager.resolveExistingStoragePath(path);
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
