import 'dart:async';

import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/index.dart' hide Session;
import 'package:hoplixi/main_db/core/dao/index.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/new/models/session.dart';
import 'package:hoplixi/main_db/new/services/db_history_services/db_history_services.dart';
import 'package:hoplixi/main_db/new/services/main_store_storage_service.dart';
import 'package:hoplixi/main_db/new/usecases/close_main_store.dart';
import 'package:hoplixi/main_db/new/usecases/create_main_store.dart';
import 'package:hoplixi/main_db/new/usecases/open_main_store.dart';
import 'package:hoplixi/main_db/new/usecases/perform_store_cleanup.dart';
import 'package:hoplixi/main_db/new/usecases/update_main_store.dart';
import 'package:hoplixi/main_db/old/services/other/file_storage_service.dart';
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

  AsyncResultDart<Session, AppError> createStore(
    CreateStoreDto dto,
    String masterPassword,
  ) async {
    return _lock.synchronized(() async {
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
        return Success(session);
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
        return Success(session);
      }
    });
  }

  AsyncResultDart<Session, AppError> openStore(
    OpenStoreDto dto,
    String masterPassword, {
    bool allowMigration = false,
  }) async {
    return _lock.synchronized(() async {
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

      unawaited(_runStartupCleanup(session));
      return Success(session);
    });
  }

  AsyncResultDart<Unit, AppError> closeStore() async {
    return _lock.synchronized(() async {
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
    });
  }

  AsyncResultDart<StoreInfoDto, AppError> updateStore(
    Session session,
    UpdateStoreDto dto,
  ) async {
    return _lock.synchronized(() async {
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

  Future<void> _runStartupCleanup(Session session) async {
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
}
