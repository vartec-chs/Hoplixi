import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/index.dart' hide Session;
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/new/services/db_history_services/db_history_services.dart';
import 'package:hoplixi/main_db/new/usecases/close_main_store.dart';
import 'package:hoplixi/main_db/new/usecases/create_main_store.dart';
import 'package:hoplixi/main_db/new/usecases/open_main_store.dart';
import 'package:hoplixi/main_db/new/usecases/update_main_store.dart';
import 'package:result_dart/result_dart.dart';
import 'package:synchronized/synchronized.dart';

class MainStoreService  {
  static const String _logTag = 'MainStoreService';

  final Lock _lock = Lock();
  final DatabaseHistoryService _dbHistoryService;
  final CreateMainStore _createMainStore;
  final OpenMainStore _openMainStore;
  final CloseMainStore _closeMainStore;
  final UpdateMainStore _updateMainStore;

  MainStoreService({
    required DatabaseHistoryService dbHistoryService,
    CreateMainStore? createMainStore,
    OpenMainStore? openMainStore,
    CloseMainStore? closeMainStore,
    UpdateMainStore? updateMainStore,
  }) : _dbHistoryService = dbHistoryService,
       _createMainStore = createMainStore ?? CreateMainStore(),
       _openMainStore = openMainStore ?? OpenMainStore(),
       _closeMainStore = closeMainStore ?? CloseMainStore(),
       _updateMainStore = updateMainStore ?? UpdateMainStore();

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

        return Success(session);
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
        return Success(session);
      }
    });
  }

  AsyncResultDart<Unit, AppError> closeStore(Session session) async {
    return _lock.synchronized(() => _closeMainStore(session: session));
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
}
